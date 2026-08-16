-- =============================================================================
-- Migration 029: the live dispatch seam (S2 minimal, Howard's ruling with 028)
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-16
-- Author:  mlm-db-engineer
--
-- APPLIED TO THE CLOUD PROJECT 2026-08-16 (gated: console verifier verdict
-- commit 1905283, quality assurance gate commit b48b331). The in-place-edit
-- window on this file is CLOSED FOREVER as of that apply: any future change,
-- however small, is a NEW numbered migration file.
--
-- Design:  spec v1.2 sections 9 (step 8: "in S2, to the real rail as an
--          off-session MIT; the state machine, classification, and bridge
--          never know which processor answered") and 8.4 (the MIT and 3DS
--          invariant), plus the coordinator-relayed ruling: when Howard
--          presses RUN with a limit, the renewals must REALLY hit
--          HyperSwitch and land on Braintree, non-3DS sandbox cards only.
--
-- STATUS: AUTHORED AND PROVEN LOCALLY ONLY (seam shape proven against the
--         simulated processor; the LIVE half is the deploy-round acceptance
--         written at the bottom of this file). Rides the 028 deploy round
--         after gates. No cloud writes from this build.
--
-- Acronym key: Merchant Initiated Transaction (MIT), 3-D Secure (3DS),
-- Customer Initiated Transaction (CIT), failure mode (FM), Personal Volume
-- (PV), Primary Account Number (PAN), Application Programming Interface (API).
--
-- -----------------------------------------------------------------------------
-- THE SEAM, in one paragraph
-- -----------------------------------------------------------------------------
-- The tick gains a third argument, p_dispatch, default 'simulated' (INERT:
-- nothing changes for any existing caller). When the console's execute
-- passes 'live', the tick does everything it always does EXCEPT the
-- simulated submit: each payment attempt is created demo-order-shaped and
-- left in the honest non-terminal state 'dispatched', stamped
-- dispatch_mode 'live'. The LIVE WORKER (the console's Edge Function, whose
-- contract is below) then performs the real HyperSwitch create-and-confirm
-- per attempt and writes the verdict back through
-- app.fn_record_live_verdict, which funnels into the SAME
-- fn_apply_attempt_result path the simulator uses: one classification, one
-- state machine, one bridge, exactly as the spec demands. The in-tick
-- reconciler resolves only SIMULATED strands; live strands stay visible in
-- the attention queue until the worker (or its retrieve sweep) answers,
-- which is FM2 discipline applied to the real rail.
--
-- -----------------------------------------------------------------------------
-- THE LIVE WORKER CONTRACT (the console execute Edge Function implements
-- this; recorded here so nobody improvises it)
-- -----------------------------------------------------------------------------
-- Console execute payload (staff-gated, same session gate as the refund
-- screen; every call audited to app.demo_staff_actions):
--   { "tick_date": "YYYY-MM-DD",          the date to run
--     "limit": 5 | null,                  ruling R9, blank = all
--     "dispatch": "live" | "simulated" }  explicit, never defaulted by the page
-- The function: (1) calls select app.fn_billing_tick(tick_date, limit,
-- dispatch); (2) when dispatch = 'live', selects the run's attempts WHERE
-- outcome = 'dispatched' AND dispatch_mode = 'live' ORDER BY id, and for
-- each: reprices server-side through the _shared truth path (the same
-- pricing.ts mirror create-payment uses; secret key from the vault, never
-- the page), asserts the repriced integer cents EQUAL the attempt's
-- demo-order total_cents (refuse on mismatch: the frozen period is the
-- promise), then HyperSwitch payments create+confirm with:
--     amount:               demo_orders.total_cents  (integer minor units)
--     currency:             USD
--     confirm:              true
--     authentication_type:  no_three_ds     <- ruling: a renewal is an MIT;
--                                             NO external authentication,
--                                             NO challenge flow, ever (8.4)
--     off_session semantics per the S2 mandate path; card data for the
--     TEST subscriptions comes from the seeded sandbox marker (below)
--     metadata:             { channel: "renewal_engine",
--                             billing_attempt_id, order_number }
-- (3) retrieves the payment (fresh retrieve, exact integer amount match:
-- the same evidentiary bar the checkout holds) and writes the verdict:
--     select app.fn_record_live_verdict(attempt_id,
--            'succeeded' | 'declined' | 'processor_unreachable',
--            decline_code_or_null, hyperswitch_payment_id);
-- (4) then select app.fn_bridge_demo_orders(true). A worker crash between
-- create and verdict leaves the attempt 'dispatched': the FM2 posture; the
-- worker's next invocation retrieves by metadata.billing_attempt_id and
-- resolves, exactly like the sim reconciler but against the real ledger.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. dispatch_mode on the ledgers
-- -----------------------------------------------------------------------------
alter table app.billing_attempts
    add column if not exists dispatch_mode text not null default 'simulated';
alter table app.billing_attempts drop constraint if exists billing_attempts_dispatch_mode_check;
alter table app.billing_attempts
    add constraint billing_attempts_dispatch_mode_check
    check (dispatch_mode in ('simulated', 'live'));

alter table app.billing_runs
    add column if not exists dispatch_mode text not null default 'simulated';
alter table app.billing_runs drop constraint if exists billing_runs_dispatch_mode_check;
alter table app.billing_runs
    add constraint billing_runs_dispatch_mode_check
    check (dispatch_mode in ('simulated', 'live'));

comment on column app.billing_attempts.dispatch_mode is
    'simulated = the Path B scripted processor answers; live = the real '
    'HyperSwitch rail answers through fn_record_live_verdict. The in-tick '
    'reconciler resolves simulated strands only. Added by migration 029.';


-- -----------------------------------------------------------------------------
-- 2. The tick, re-created with the dispatch argument (three changes only:
--    the p_dispatch validation and run stamp; the reconciler's
--    simulated-only filter; the dispatch branch that stamps live attempts
--    and leaves them for the worker instead of sim-submitting. Everything
--    else is migration 028's body verbatim; 028's header carries the run
--    limit rationale and is not repeated here.)
-- -----------------------------------------------------------------------------
drop function if exists app.fn_billing_tick(date, int);

create function app.fn_billing_tick(
    p_date date,
    p_limit int default null,
    p_dispatch text default 'simulated'
)
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
    v_processed    int := 0;
    v_attempts     int := 0;
    v_succeeded    int := 0;
    v_declined     int := 0;
    v_member_fault int := 0;
    v_system_fault int := 0;
    v_crash_after  int;
    v_dispatched   int := 0;
    v_candidates   jsonb;
    v_selected     jsonb;
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
    if p_limit is not null and p_limit < 1 then
        raise exception
            'the run limit must be a positive integer or null (blank = run everything due); % is neither (ruling R9)',
            p_limit;
    end if;
    if p_dispatch not in ('simulated', 'live') then
        raise exception
            'dispatch mode is simulated or live; % is neither (migration 029)', p_dispatch;
    end if;

    select clock_date, engine_epoch into v_clock, v_epoch from app.sim_clock;
    if v_clock is null then
        raise exception 'sim clock is not initialized; call app.fn_sim_clock_init first';
    end if;
    if p_date = v_clock then
        v_rerun := true;
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
         limit_requested, dispatch_mode)
    values
        (p_date, 'S1', 'simulated', 'running', now(), p_limit, p_dispatch)
    returning id into v_run_id;

    -- Reconcile: SIMULATED strands only (migration 029). Live strands are
    -- the live worker's to retrieve against the real ledger; resolving them
    -- from the script table would invent processor truth.
    for r in
        select ba.id as attempt_id, rp.subscription_id, rp.renewal_index,
               ba.attempt_no
          from app.billing_attempts ba
          join app.renewal_periods rp on rp.id = ba.renewal_period_id
         where ba.outcome = 'dispatched'
           and ba.dispatch_mode = 'simulated'
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

    -- Retries: never limited (9B rule 6); in a live run they dispatch live
    -- too (a retry is a payment; the rail answers it, not the script table).
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
            v_attempts := v_attempts + 1;
            if p_dispatch = 'live' then
                update app.billing_attempts set dispatch_mode = 'live'
                 where id = v_attempt_id;
            else
                perform app.fn_sim_submit(v_attempt_id, p_date, v_run_id);
            end if;
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

    v_due := jsonb_array_length(v_candidates);

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

    v_promo_out := app.fn_apply_promotions(v_run_id, v_selected);
    v_promo_ok  := (v_promo_out = v_selected);

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
            continue;
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
            continue;
        end if;

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
            continue;
        end if;

        -- MIGRATION 029, THE SEAM: a live run leaves the attempt in the
        -- honest non-terminal state for the worker; the simulated run
        -- submits to the script table as always. Same rows, same states,
        -- different answerer: the state machine never knows which.
        if p_dispatch = 'live' then
            update app.billing_attempts set dispatch_mode = 'live'
             where id = v_attempt_id;
        else
            perform app.fn_sim_submit(v_attempt_id, p_date, v_run_id);
        end if;
    end loop;

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

    perform app.fn_bridge_demo_orders(true);

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
           due_count             = v_due,
           processed_count       = v_processed,
           remaining_count       = v_due - v_processed
     where id = v_run_id;

    if not v_rerun then
        update app.sim_clock set clock_date = p_date;
        insert into app.sim_clock_advances (from_date, to_date, advanced_by_run)
        values (v_clock, p_date, v_run_id);
    end if;

    return v_run_id;
end;
$$;

revoke execute on function app.fn_billing_tick(date, int, text) from public;

comment on function app.fn_billing_tick(date, int, text) is
    'The billing tick with the R9 run limit (migration 028) and the live '
    'dispatch seam (migration 029): p_dispatch simulated (default, inert) '
    'submits to the Path B script table; live leaves attempts dispatched '
    'for the HyperSwitch worker, whose verdicts return through '
    'fn_record_live_verdict into the one shared classification path.';


-- -----------------------------------------------------------------------------
-- 3. app.fn_record_live_verdict: the worker's one write-back door
-- -----------------------------------------------------------------------------
create or replace function app.fn_record_live_verdict(
    p_attempt_id bigint,
    p_result text,                 -- 'succeeded' | 'declined' | 'processor_unreachable'
    p_decline_code text default null,
    p_payment_reference text default null   -- the HyperSwitch payment id
) returns void
language plpgsql
as $$
declare
    v_att  app.billing_attempts%rowtype;
    v_tick date;
begin
    select * into v_att from app.billing_attempts where id = p_attempt_id;
    if not found then
        raise exception 'billing attempt % does not exist', p_attempt_id;
    end if;
    if v_att.dispatch_mode <> 'live' then
        raise exception
            'billing attempt % is %-dispatched; the live verdict door is for live attempts only',
            p_attempt_id, v_att.dispatch_mode;
    end if;
    if p_result not in ('succeeded', 'declined', 'processor_unreachable') then
        raise exception 'live verdict is succeeded, declined or processor_unreachable, not %', p_result;
    end if;

    select clock_date into v_tick from app.sim_clock;

    perform app.fn_apply_attempt_result(
        p_attempt_id, p_result, p_decline_code, v_tick, v_att.run_id);

    -- The real payment identity replaces the simulator's placeholder, and
    -- the summary stops claiming to be simulated.
    if p_result = 'succeeded' and p_payment_reference is not null then
        update app.demo_orders
           set payment_reference = p_payment_reference,
               processor_summary = processor_summary
                   || jsonb_build_object('simulated', false,
                                         'rail', 'hyperswitch_braintree')
         where id = v_att.demo_order_id;
    end if;
end;
$$;

revoke execute on function app.fn_record_live_verdict(bigint, text, text, text) from public;

comment on function app.fn_record_live_verdict(bigint, text, text, text) is
    'The live worker''s single write-back: funnels a HyperSwitch retrieve '
    'verdict into fn_apply_attempt_result (one classification path, one '
    'state machine, one bridge) and stamps the real payment reference. '
    'Added by migration 029.';


-- -----------------------------------------------------------------------------
-- 4. The S2 test-credential seed (Howard's card rule made data)
--
--    Seeds one monthly test subscription per named member, credentials
--    carrying ONLY the confirmed NON-3DS Braintree sandbox cards:
--    4242 4242 4242 4242 (visa) and 5555 5555 5555 4444 (mastercard),
--    expiry 01/2029. These are SANDBOX-PUBLIC test numbers published for
--    exactly this purpose, never real PANs, which is why they may live in a
--    seed (noted per the coordinator's ruling); the real S2 path uses
--    vaulted mandates and never stores a number. Howard's explicit rule:
--    NO card that triggers a challenge (no 4111, no 2503, no saboteur; the
--    saboteur experiment stays parked in the spec). The token_reference
--    carries the sandbox marker the live worker parses:
--    'sandbox-card:<number>:<month>:<year>'.
--
--    Due dates STAGGER: member i anchors at p_first_due plus (i-1 modulo 5)
--    days, so a limit-2 run has exactly two due on day one and the rest
--    arrive across the week. Called at deploy time with the real first-due
--    date and the ten real member codes the operator picks; the rig calls
--    it locally with fixture members to prove the shape.
-- -----------------------------------------------------------------------------
create or replace function app.fn_seed_s2_test_subscriptions(
    p_first_due date,
    p_member_codes text[]
) returns int
language plpgsql
as $$
declare
    v_code    text;
    v_member  bigint;
    v_product bigint;
    v_cred    bigint;
    v_i       int := 0;
    v_brand   text;
    v_number  text;
    v_anchor  date;
begin
    select id into v_product from app.products where sku = 'AGT-D-001';

    foreach v_code in array p_member_codes loop
        v_i := v_i + 1;
        select id into v_member from app.members where member_code = v_code;
        if not found then
            raise exception 'member % does not exist; the seed creates subscriptions, never members', v_code;
        end if;

        if v_i % 2 = 1 then
            v_brand := 'visa';        v_number := '4242424242424242';
        else
            v_brand := 'mastercard';  v_number := '5555555555554444';
        end if;
        v_anchor := p_first_due + ((v_i - 1) % 5);

        insert into app.payment_credentials
            (member_id, brand, last4, expiry_month, expiry_year,
             token_reference, network_anchor, created_on)
        values
            (v_member, v_brand, right(v_number, 4), 1, 2029,
             'sandbox-card:' || v_number || ':01:2029',
             'sim:' || v_brand || ':s2-' || v_i,
             p_first_due - 1)
        returning id into v_cred;

        insert into app.subscriptions
            (member_id, product_id, quantity, start_month,
             billing_anchor_date, frequency_months, billing_day, state,
             credential_id)
        values
            (v_member, v_product, 1, date_trunc('month', v_anchor)::date,
             v_anchor, 1, null, 'active', v_cred);
    end loop;

    return v_i;
end;
$$;

revoke execute on function app.fn_seed_s2_test_subscriptions(date, text[]) from public;


-- =============================================================================
-- DEPLOY-ROUND ACCEPTANCE (the LIVE half of the proof, executed after the
-- console deploy round applies 028 and 029; written here so nobody
-- improvises it)
-- =============================================================================
-- A1. Seed: fn_seed_s2_test_subscriptions with the deploy date and ten real
--     demo member codes; verify ten credentials, all brand visa or
--     mastercard, last4 4242 or 4444, expiry 01/2029, and NOT ONE other
--     card number anywhere in app.payment_credentials.
-- A2. The run: console execute with { tick_date: today, limit: 2,
--     dispatch: "live" }. The run row must read limit_requested 2,
--     due_count >= 2, processed_count 2, dispatch_mode live.
-- A3. The rail: EXACTLY 2 payments visible in the HyperSwitch dashboard,
--     metadata channel renewal_engine, status succeeded, connector
--     Braintree, authentication_type no_three_ds, ZERO challenges issued
--     (Howard's rule: any challenge on any renewal is an immediate FAIL of
--     this acceptance).
-- A4. The write-back: both attempts resolved succeeded via
--     fn_record_live_verdict with the HyperSwitch payment ids stamped as
--     payment_reference; processor_summary reads simulated false, rail
--     hyperswitch_braintree; amounts match the frozen renewal_periods
--     amount_cents to the integer cent.
-- A5. The bridge: both orders bridged; PV booked to the covered months;
--     the commission dry run shows the volume, the finalized months
--     untouched.
-- A6. The remainder: the eight unprocessed test subscriptions bill on
--     their staggered days through the normal (unlimited) path with zero
--     duplicates: the FM1 key across live limited runs.
-- A7. The strand drill: kill the worker between create and verdict on ONE
--     deliberate run; the attempt stays dispatched/live, appears in the
--     attention queue, and the worker's next invocation retrieves by
--     metadata.billing_attempt_id and resolves it with no second charge.
-- =============================================================================
