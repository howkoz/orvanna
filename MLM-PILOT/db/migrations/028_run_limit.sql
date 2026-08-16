-- =============================================================================
-- Migration 028: the run limit (ruling R9, spec v1.2 section 9B)
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-16
-- Author:  mlm-db-engineer
-- Design:  MLM-PILOT\docs\SUBSCRIPTION-ENGINE-SPEC.md version 1.2, section 9B
--          (six rules), ruling R9. Howard's words: "put a field that allows
--          me to run a specific amount of subscriptions, if i want to run 5
--          run only 5, if i want to run 100 then run 100... i will never
--          probably run more than 10 but i want it wired up in case."
--
-- STATUS: AUTHORED AND PROVEN LOCALLY ONLY. Migrations 024 through 027 are
--         CLOUD-APPLIED, so by the standing rule (applied SQL is never
--         edited; a follow-up change is a NEW numbered migration, the rule
--         that failed four times before it became law) this change is its
--         own file. It re-creates app.fn_billing_tick with the new
--         signature; migration 026's file stays byte-for-byte untouched as
--         the record of what the database ran before this. Do NOT
--         cloud-apply until both gates pass; 028 rides the console deploy
--         round.
--
-- Acronym key: failure mode (FM), open question (OQ), ruling (R), transition
-- (T), Personal Volume (PV), Coordinated Universal Time (UTC), Merchant
-- Initiated Transaction (MIT), 3-D Secure (3DS), Customer Initiated
-- Transaction (CIT).
--
-- -----------------------------------------------------------------------------
-- WHAT CHANGES, exactly three things (spec 9B's migration note):
-- -----------------------------------------------------------------------------
--   1. app.billing_runs gains the four arithmetic columns of 9B rule 4:
--      limit_requested (null = unlimited), due_count, processed_count,
--      remaining_count, so a partial run can never be mistaken for a
--      complete one ("ran N of M due, R remaining" is renderable from the
--      row alone).
--   2. app.fn_billing_tick gains the optional limit: (p_date date,
--      p_limit int default null). Null runs everything due, byte-identical
--      behavior to before. N processes exactly N NEW cycle billings, or all
--      of them when fewer are due.
--   3. Selection is DETERMINISTIC (9B rule 2): the due set is ordered by
--      OLDEST DUE DATE FIRST (scheduled_date ascending), then member code
--      ascending (then subscription id, then renewal index, so the order is
--      total even for a member holding two subscriptions), and the first N
--      are taken. Oldest-first means a limit can never starve the
--      longest-waiting subscription.
--
-- WHAT THE LIMIT DOES NOT TOUCH (9B rule 6, implemented literally): the
-- limit bounds NEW cycle billings ONLY. Already-scheduled retries due that
-- day process regardless, as do the reconciler, checkpoint evaluations,
-- pause auto-resumes, and auto-cancel sweeps. A retry is a promise already
-- made on a date clipped by rule C1; deferring it behind a limit could push
-- it out of its calendar-month window and vanish it as skipped_clipped,
-- turning a cautious small run into a dunning distortion that punishes
-- exactly the members already in trouble. The counts in rule 4 therefore
-- count new cycle billings only; retries appear under attempts_made as
-- always.
--
-- WHY A LIMITED RUN CAN STRAND NOTHING (9B rule 3): the remainder is simply
-- not processed, so it has no accounting row, so the existing
-- due-on-or-before gather selects it on the very next tick, oldest first.
-- No bookmark, no cursor, no new state: due-ness already derives from cycle
-- accounting under the FM1 key, and anything unprocessed remains due by
-- construction. The FM1 unique key (subscription_id, renewal_index) holds
-- across limited runs exactly as it holds across crashes and reruns.
--
-- IMPLEMENTATION NOTES, argued:
--   N1. The old one-argument function is DROPPED before the two-argument
--       function with a default is created. Keeping both would make every
--       existing call fn_billing_tick(date) ambiguous ("function is not
--       unique"), because both candidates match. Existing callers
--       (fn_scheduler_poll, the harness, the future console) resolve to the
--       new function through the default; the scheduled daily run therefore
--       always runs UNLIMITED (9B rule 5: the limit is a hand-run
--       instrument).
--   N2. The promo hook (pipeline step 4) receives the SELECTED set, not the
--       full due set: the hook prices what this run will actually bill, and
--       pricing candidates that are deliberately not billing this run would
--       let a future promotion consume a budget on charges that never
--       happen. due_count is measured on the full set BEFORE selection.
--   N3. processed_count counts cycles this run ACTED ON: a materialised
--       accounting row, whether the dispatch then succeeded, declined, or
--       was stopped at pre-flight (FM5). A pre-flight stop consumed one of
--       the N slots because the cycle is now accounted and will not be
--       gathered again; hiding it from the count would make a limited run
--       of five look like four.
--   N4. p_limit must be a positive integer when given. Zero is refused
--       rather than interpreted: "run nothing" is not running the engine,
--       and a silent no-op run row would read like a day with nothing due.
--
-- RUN ORDER: after 024..027. Local proof: MLM-PILOT\db\subscriptions\
-- (segment 17, battery rows LM1..LM6).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The run-record arithmetic (9B rule 4)
-- -----------------------------------------------------------------------------
alter table app.billing_runs add column if not exists limit_requested int;
alter table app.billing_runs add column if not exists due_count       int;
alter table app.billing_runs add column if not exists processed_count int;
alter table app.billing_runs add column if not exists remaining_count int;

comment on column app.billing_runs.limit_requested is
    'The run limit N this run was invoked with; null = unlimited (ruling R9, '
    'spec v1.2 section 9B). Added by migration 028.';
comment on column app.billing_runs.due_count is
    'New cycle billings due at this tick BEFORE the limit was applied. '
    'Retries are not counted here (9B rule 6). Added by migration 028.';
comment on column app.billing_runs.processed_count is
    'New cycle billings this run acted on (accounting row materialised, '
    'including pre-flight stops). "ran N of M due". Added by migration 028.';
comment on column app.billing_runs.remaining_count is
    'due_count minus processed_count: what the next tick''s gather will pick '
    'up, oldest first, with no bookmark needed. Added by migration 028.';


-- -----------------------------------------------------------------------------
-- 2. The tick, re-created with the optional limit (implementation note N1)
--
--    The body below is migration 026's tick verbatim except where marked
--    R9: the limit validation, the deterministic selection between gather
--    and the promo hook, the processed counter, and the close-out
--    arithmetic. Everything else (reconcile, auto-resume, retries,
--    pre-flight, crash lever, checkpoint, auto-cancel, bridge, clock) is
--    unchanged, and an unlimited call is behavior-identical to before.
-- -----------------------------------------------------------------------------
drop function if exists app.fn_billing_tick(date);

create function app.fn_billing_tick(p_date date, p_limit int default null)
returns bigint
language plpgsql
as $$
declare
    v_clock        date;
    v_epoch        date;
    v_run_id       bigint;
    v_rerun        boolean := false;
    v_reconciled   int := 0;
    v_due          int := 0;
    v_processed    int := 0;      -- R9: new cycle billings acted on this run
    v_attempts     int := 0;
    v_succeeded    int := 0;
    v_declined     int := 0;
    v_member_fault int := 0;
    v_system_fault int := 0;
    v_crash_after  int;
    v_dispatched   int := 0;
    v_candidates   jsonb;
    v_selected     jsonb;         -- R9: the deterministic first N
    v_promo_out    jsonb;
    v_promo_ok     boolean;
    r              record;
    v_sub          app.subscriptions%rowtype;
    v_n            int;
    v_date_n       date;
    v_price        numeric(10,2);
    v_pv           numeric(10,2);
    v_qty          int;
    v_period_id    bigint;
    v_attempt_id   bigint;
    v_pf           text;
    v_kind         text;
    v_checkpoint   date;
    v_truth        app.sim_outcome_scripts%rowtype;
begin
    -- R9 (note N4): a limit, when given, is a positive integer.
    if p_limit is not null and p_limit < 1 then
        raise exception
            'the run limit must be a positive integer or null (blank = run everything due); % is neither (ruling R9)',
            p_limit;
    end if;

    -- ---- Step 1: open the run (and validate the clock). --------------------
    select clock_date, engine_epoch into v_clock, v_epoch from app.sim_clock;
    if v_clock is null then
        raise exception 'sim clock is not initialized; call app.fn_sim_clock_init first';
    end if;
    if p_date = v_clock then
        v_rerun := true;      -- a rerun of the just-processed day, superseding
    elsif p_date <> v_clock + 1 then
        raise exception
            'tick date % is not the clock date % nor the day after; the clock advances one day per tick',
            p_date, v_clock;
    end if;

    update app.billing_runs
       set status = 'superseded'
     where tick_date = p_date and status in ('running', 'final');

    insert into app.billing_runs
        (tick_date, engine_version, clock_source, status, started_at,
         limit_requested)
    values
        (p_date, 'S1', 'simulated', 'running', now(), p_limit)
    returning id into v_run_id;

    -- ---- Step 2: reconcile FIRST (FM2). Never limited (9B rule 6). ---------
    for r in
        select ba.id as attempt_id, rp.subscription_id, rp.renewal_index,
               ba.attempt_no
          from app.billing_attempts ba
          join app.renewal_periods rp on rp.id = ba.renewal_period_id
         where ba.outcome = 'dispatched'
         order by ba.id
    loop
        select * into v_truth
          from app.sim_outcome_scripts s
         where s.subscription_id = r.subscription_id
           and s.renewal_index   = r.renewal_index
           and s.attempt_no      = r.attempt_no
           and not s.consumed
         limit 1;

        if not found then
            perform app.fn_apply_attempt_result(r.attempt_id, 'succeeded', null, p_date, v_run_id);
        elsif v_truth.outcome = 'not_received' then
            update app.sim_outcome_scripts set consumed = true where id = v_truth.id;
            perform app.fn_sim_submit(r.attempt_id, p_date, v_run_id);
        else
            update app.sim_outcome_scripts set consumed = true where id = v_truth.id;
            perform app.fn_apply_attempt_result(
                r.attempt_id, v_truth.outcome, v_truth.decline_code, p_date, v_run_id);
        end if;
        v_reconciled := v_reconciled + 1;
    end loop;

    -- ---- Step 3a: auto-resume paused subscriptions due today (T19). --------
    -- Never limited (9B rule 6).
    for r in
        select s.id
          from app.subscriptions s
         where s.state = 'paused'
           and exists (select 1 from app.subscription_events e
                        where e.subscription_id = s.id and e.event_type = 'pause'
                          and e.pause_until <= p_date
                          and e.id = (select max(e2.id) from app.subscription_events e2
                                       where e2.subscription_id = s.id
                                         and e2.event_type in ('pause', 'resume')))
    loop
        perform app.fn_record_state(r.id, 'active',
            'T19: auto-resume, the pause window ended (R3)', p_date, 'engine');
        insert into app.subscription_events
            (subscription_id, event_type, occurred_on, cause, actor)
        values (r.id, 'resume', p_date, 'auto-resume at pause window end', 'engine');
    end loop;

    -- ---- Step 3b: gather due retries. NEVER LIMITED (9B rule 6): a retry --
    -- is a promise already made on a C1-clipped date; deferring it behind a
    -- limit could vanish it as skipped_clipped and distort dunning.
    for r in
        select ba.id as prior_attempt, ba.attempt_no, ba.decline_class,
               ba.next_retry_date, ba.next_retry_step,
               rp.id as period_id, rp.subscription_id, rp.scheduled_date,
               s.state
          from app.billing_attempts ba
          join app.renewal_periods rp on rp.id = ba.renewal_period_id
          join app.subscriptions s    on s.id  = rp.subscription_id
         where rp.outcome = 'open'
           and ba.next_action in ('retry', 'infra_immediate')
           and ba.next_retry_date is not null
           and ba.next_retry_date <= p_date
           and ba.attempt_no = (select max(b2.attempt_no)
                                  from app.billing_attempts b2
                                 where b2.renewal_period_id = rp.id)
           and s.state in ('active', 'past_due', 'dunning')
         order by rp.subscription_id, rp.renewal_index
    loop
        if date_trunc('month', p_date::timestamp)
             = date_trunc('month', r.scheduled_date::timestamp)
           and extract(day from p_date)::int <= 26 then
            v_kind := case r.decline_class
                        when 'soft'  then 'retry_soft'
                        when 'infra' then 'retry_soft'
                        else 'retry_ambiguous' end;
            v_attempt_id := app.fn_dispatch_attempt(
                v_run_id, r.period_id, r.attempt_no + 1, v_kind,
                r.next_retry_step, p_date);
            perform app.fn_sim_submit(v_attempt_id, p_date, v_run_id);
            v_attempts := v_attempts + 1;
        else
            insert into app.billing_attempts
                (run_id, renewal_period_id, attempt_no, attempt_kind,
                 ladder_step, scheduled_for, outcome, decline_class,
                 member_fault, next_action)
            values
                (v_run_id, r.period_id, r.attempt_no + 1,
                 case r.decline_class when 'soft' then 'retry_soft'
                      when 'infra' then 'retry_soft' else 'retry_ambiguous' end,
                 r.next_retry_step, r.next_retry_date, 'skipped_clipped',
                 r.decline_class, null, 'none');
            if r.state = 'past_due' then
                perform app.fn_record_state(r.subscription_id, 'dunning',
                    'T8: the surviving retry window passed unrun (C1 clip on catch-up)',
                    p_date, 'engine');
            end if;
        end if;
    end loop;

    -- ---- Step 3c: gather due NEW cycles (the FM1/FM4 derivation). ----------
    v_crash_after := nullif(current_setting('orvanna.sim_crash_after_dispatches', true), '')::int;

    v_candidates := '[]'::jsonb;
    for r in
        select s.id as subscription_id
          from app.subscriptions s
         where s.state = 'active'
         order by s.id
    loop
        v_n := coalesce((select max(p2.renewal_index) from app.renewal_periods p2
                          where p2.subscription_id = r.subscription_id), 0) + 1;
        v_date_n := app.fn_sub_scheduled_date(r.subscription_id, v_n);
        while v_date_n is not null and v_date_n <= p_date loop
            if v_date_n > v_epoch then
                select p.price, p.volume_points, s.quantity
                  into v_price, v_pv, v_qty
                  from app.subscriptions s
                  join app.products p on p.id = s.product_id
                 where s.id = r.subscription_id;
                v_candidates := v_candidates || jsonb_build_array(jsonb_build_object(
                    'subscription_id', r.subscription_id,
                    'renewal_index',   v_n,
                    'scheduled_date',  v_date_n,
                    'unit_price_cents', (v_price * 100)::int,
                    'unit_pv',          v_pv,
                    'quantity',         v_qty));
            end if;
            v_n := v_n + 1;
            v_date_n := app.fn_sub_scheduled_date(r.subscription_id, v_n);
        end loop;
    end loop;

    -- R9: due_count is the FULL due set, measured before selection.
    v_due := jsonb_array_length(v_candidates);

    -- R9 (9B rule 2): THE DETERMINISTIC SELECTION. Oldest due date first,
    -- then member code, then subscription id, then renewal index: total
    -- order, so same data plus same N equals the same subscriptions, every
    -- time, recomputable by the verifier and previewable by the console.
    select coalesce(jsonb_agg(x.c order by x.sched, x.member_code,
                                       x.subscription_id, x.renewal_index),
                    '[]'::jsonb)
      into v_selected
      from (
        select c,
               (c ->> 'scheduled_date')::date    as sched,
               m.member_code,
               (c ->> 'subscription_id')::bigint as subscription_id,
               (c ->> 'renewal_index')::int      as renewal_index
          from jsonb_array_elements(v_candidates) c
          join app.subscriptions s2 on s2.id = (c ->> 'subscription_id')::bigint
          join app.members m        on m.id  = s2.member_id
         order by 2, 3, 4, 5
         limit coalesce(p_limit, 2147483647)
      ) x;

    -- Step 4: the promo hook prices what this run will actually bill
    -- (implementation note N2), a no-op in S1, asserted on the run row.
    v_promo_out := app.fn_apply_promotions(v_run_id, v_selected);
    v_promo_ok  := (v_promo_out = v_selected);

    -- Steps 6 through 10 per selected candidate, in the selection order.
    for r in
        select (c ->> 'subscription_id')::bigint as subscription_id,
               (c ->> 'renewal_index')::int      as renewal_index,
               (c ->> 'scheduled_date')::date    as sched,
               m.member_code
          from jsonb_array_elements(v_promo_out) c
          join app.subscriptions s2 on s2.id = (c ->> 'subscription_id')::bigint
          join app.members m        on m.id  = s2.member_id
         order by 3, 4, 1, 2
    loop
        select * into v_sub from app.subscriptions where id = r.subscription_id;
        if v_sub.state <> 'active' then
            continue;   -- a cancellation_all earlier in this very loop may
                        -- have cancelled a later candidate; never bill it
        end if;

        select p.price, p.volume_points
          into v_price, v_pv
          from app.products p where p.id = v_sub.product_id;

        insert into app.renewal_periods
            (subscription_id, renewal_index, scheduled_date,
             covered_month_first, covered_months, amount_cents, pv_total)
        values
            (r.subscription_id, r.renewal_index, r.sched,
             app.fn_sub_covered_month_first(r.subscription_id, r.renewal_index),
             v_sub.frequency_months,
             (round(v_sub.quantity * v_price * v_sub.frequency_months, 2) * 100)::int,
             round(v_sub.quantity * v_pv * v_sub.frequency_months, 2))
        on conflict (subscription_id, renewal_index) do nothing
        returning id into v_period_id;

        if v_period_id is null then
            continue;   -- FM1: already accounted, nothing to do
        end if;

        -- R9 (note N3): the cycle is now accounted; it consumed a slot.
        v_processed := v_processed + 1;

        v_pf := app.fn_preflight(r.subscription_id, p_date);
        if v_pf is not null then
            insert into app.billing_attempts
                (run_id, renewal_period_id, attempt_no, attempt_kind,
                 ladder_step, scheduled_for, outcome, decline_code,
                 decline_class, member_fault, next_action)
            values
                (v_run_id, v_period_id, 1, 'initial', 0, p_date,
                 'preflight_failed', 'preflight_failed', 'internal_config',
                 false, 'attention');
            v_attempts := v_attempts + 1;
            continue;
        end if;

        v_attempt_id := app.fn_dispatch_attempt(
            v_run_id, v_period_id, 1, 'initial', 0, p_date);
        v_attempts   := v_attempts + 1;
        v_dispatched := v_dispatched + 1;

        if v_crash_after is not null then
            if v_dispatched >= v_crash_after then
                perform set_config('orvanna.sim_crash_after_dispatches', '', false);
                update app.billing_runs
                   set notes = 'SIMULATED CRASH after ' || v_dispatched
                               || ' dispatches (FM2 scenario); run left running'
                 where id = v_run_id;
                return v_run_id;
            end if;
            continue;   -- crash mode: dispatch only, never submit
        end if;

        perform app.fn_sim_submit(v_attempt_id, p_date, v_run_id);
    end loop;

    -- ---- Step C2: the suspension checkpoint sweep. Never limited. ----------
    for r in
        select rp.id as period_id, rp.subscription_id, rp.scheduled_date, s.state
          from app.renewal_periods rp
          join app.subscriptions s on s.id = rp.subscription_id
         where rp.outcome = 'open'
           and s.state in ('past_due', 'dunning', 'card_update_required')
         order by rp.subscription_id
    loop
        if extract(day from r.scheduled_date)::int <= 26 then
            v_checkpoint := make_date(extract(year from r.scheduled_date)::int,
                                      extract(month from r.scheduled_date)::int, 26);
        else
            v_checkpoint := (date_trunc('month', r.scheduled_date)
                             + interval '1 month - 1 day')::date;
        end if;

        if p_date >= v_checkpoint then
            update app.renewal_periods set outcome = 'unpaid' where id = r.period_id;
            if r.state = 'past_due' then
                perform app.fn_record_state(r.subscription_id, 'dunning',
                    'T8: checkpoint reached with retries unresolved', p_date, 'engine');
            end if;
            perform app.fn_record_state(r.subscription_id, 'suspended',
                case when r.state = 'card_update_required' then 'T17' else 'T14' end
                || ': suspension checkpoint (' || v_checkpoint
                || ') passed with the period unpaid', p_date, 'engine');
        end if;
    end loop;

    -- ---- T22: the auto-cancel sweep, month-start ticks. Never limited. -----
    if extract(day from p_date)::int = 1 then
        for r in
            select s.id
              from app.subscriptions s
             where s.state = 'suspended'
               and app.fn_sub_unpaid_streak(s.id, p_date) >= 2
        loop
            perform app.fn_record_state(r.id, 'cancelled',
                'T22: two consecutive counted unpaid calendar months while '
                'suspended (R4; paused months excluded, T10a months freeze '
                'rather than break the chain, spec v1.1 12.3)',
                p_date, 'engine');
        end loop;
    end if;

    -- ---- Step 11: the bridge, idempotently. --------------------------------
    perform app.fn_bridge_demo_orders(true);

    -- ---- Step 12: close the run, with its assertions and the R9 arithmetic.
    select count(*) filter (where ba.outcome = 'succeeded'),
           count(*) filter (where ba.outcome in ('declined', 'processor_unreachable', 'preflight_failed')),
           count(*) filter (where ba.member_fault
                              and ba.outcome in ('declined')),
           count(*) filter (where not coalesce(ba.member_fault, true)
                              and ba.outcome in ('declined', 'processor_unreachable', 'preflight_failed'))
      into v_succeeded, v_declined, v_member_fault, v_system_fault
      from app.billing_attempts ba
     where ba.run_id = v_run_id;

    update app.billing_runs
       set status                = 'final',
           finished_at           = now(),
           subscriptions_due     = v_due,
           attempts_made         = v_attempts,
           succeeded             = v_succeeded,
           declined              = v_declined,
           attempts_reconciled   = v_reconciled,
           member_fault_failures = v_member_fault,
           system_fault_failures = v_system_fault,
           promo_hook_identity   = v_promo_ok,
           mit_invariant_ok      = true,
           -- R9 rule 4: "ran N of M due, R remaining", on the row forever.
           due_count             = v_due,
           processed_count       = v_processed,
           remaining_count       = v_due - v_processed
     where id = v_run_id;

    -- Advance the clock (never on a rerun).
    if not v_rerun then
        update app.sim_clock set clock_date = p_date;
        insert into app.sim_clock_advances (from_date, to_date, advanced_by_run)
        values (v_clock, p_date, v_run_id);
    end if;

    return v_run_id;
end;
$$;

revoke execute on function app.fn_billing_tick(date, int) from public;

comment on function app.fn_billing_tick(date, int) is
    'One billing tick (spec section 9), with the optional run limit of '
    'ruling R9 (spec v1.2 section 9B, migration 028): p_limit null runs '
    'everything due; N processes exactly the deterministic first N new '
    'cycle billings (oldest due date, then member code), the remainder '
    'self-heals through the next gather, and already-scheduled retries, '
    'the reconciler, checkpoints, auto-resume and auto-cancel are never '
    'limited. The run row carries limit_requested / due_count / '
    'processed_count / remaining_count.';


-- =============================================================================
-- VERIFICATION QUERIES (the house convention: run after applying)
-- =============================================================================
-- 1. Exactly one fn_billing_tick exists, the two-argument form:
--      select proargtypes::regtype[] from pg_proc
--       where proname = 'fn_billing_tick';
--    Expect one row: {date, integer}. An unlimited call fn_billing_tick(d)
--    must resolve without ambiguity (the one-argument form was dropped,
--    implementation note N1).
-- 2. The four columns exist on app.billing_runs and are null on every
--    pre-028 run row (history is not retro-filled).
-- 3. A limit of zero or a negative is refused with the R9 error.
-- 4. The full local proof: 23 due with limit 5 processes exactly the
--    deterministic first 5 (run row 5 / 23 / 5 / 18), the next tick gathers
--    number 6 onward with zero strandings and zero duplicate cycles, and a
--    retry scheduled on a limited day processes regardless. Battery rows
--    LM1..LM6 in MLM-PILOT\db\subscriptions\sql\30_proof_battery.sql,
--    driven by sql\17_limit_run.sql.
-- =============================================================================
