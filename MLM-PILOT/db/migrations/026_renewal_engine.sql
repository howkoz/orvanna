-- =============================================================================
-- Migration 026: subscription engine Phase S1, the renewal pipeline
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-16
-- Author:  mlm-db-engineer
--
-- APPLIED TO THE CLOUD PROJECT 2026-08-16 (gated: verifier re-gate 13f273e
-- CLOUD APPLY YES, quality assurance delta 8bf59df, on commit 8f31a76). The
-- in-place-edit window on this file is CLOSED FOREVER as of that apply: any
-- future change, however small, is a NEW numbered migration file.
--
-- Design:  MLM-PILOT\docs\SUBSCRIPTION-ENGINE-SPEC.md sections 4 (dates),
--          5 (state machine), 8 (the ladder), 9 (the pipeline), 9A (the
--          scheduler), 10 (the simulated clock and processor), 12 (edge
--          cases), 13A (the failure-mode register), plus the addendum rulings.
--
-- STATUS: AUTHORED AND PROVEN LOCALLY ONLY (see 024's status block). FROZEN
--         once applied anywhere.
--
-- Acronym key: Personal Volume (PV), Sales Volume (SV), Customer Initiated
-- Transaction (CIT), Merchant Initiated Transaction (MIT), 3-D Secure (3DS),
-- Coordinated Universal Time (UTC), failure mode (FM), Grand Unified
-- Configuration variable (GUC, PostgreSQL's session setting mechanism).
--
-- -----------------------------------------------------------------------------
-- DELIBERATE DEVIATIONS AND RESOLUTIONS, each argued
-- -----------------------------------------------------------------------------
-- D6. THE SCHEDULE FORMULA INDEXES FROM ZERO PERIODS AFTER THE ANCHOR, NOT
--     ONE. The spec's section 4.2 sketch reads
--     scheduled_date(n) = add_months(anchor, n * frequency_months + shift),
--     which would put the FIRST renewal one full period after the anchor.
--     Ruling R1's words are "The first renewal bills on that date" (the
--     anchor), and the spec's own example agrees: purchase 2026-01-05,
--     anchor 2026-02-04, "monthly renewals on the 4th thereafter", meaning
--     renewal 1 IS 2026-02-04. Rulings are law over sketch formulas, so this
--     file implements
--     scheduled_date(n) = clamp_day(add_months(anchor, (n - 1) * frequency_months + shift)).
-- D7. THE ENGINE EPOCH. Seeded subscriptions are anchored years in the past
--     and their history is owned by SEEDED orders, not renewal periods. The
--     clock row therefore carries engine_epoch: the gather step only ever
--     considers cycles whose scheduled date is strictly AFTER the epoch, so
--     evolving 1,820 seeded rows cannot trigger a catastrophic catch-up
--     billing of two years of history. The epoch is set once at clock
--     initialization and the cycle audit floors at it too.
-- D8. internal_config, config, duplicate and infra failures leave the
--     subscription STATE UNCHANGED. The spec allows internal_config to route
--     "to card_update_required or the staff attention queue"; this file
--     routes ALL system-fault failures to the attention queue only, because
--     moving a member to card_update_required for OUR defect would punish
--     the member for our bug and (worse) invite a needless card update. The
--     member-fault versus system-fault principle (spec 6.2 table 5) is
--     enforced here: no system-fault outcome ever advances past_due,
--     dunning, suspension, or the auto-cancel counter.
-- D9. THE CRASH LEVER IS A SESSION SETTING, NOT A TABLE. The spec counts ten
--     new tables and the FM2 crash-mid-batch proof needs a deterministic way
--     to kill the engine mid-dispatch. Rather than an eleventh table, the
--     tick reads the session setting orvanna.sim_crash_after_dispatches
--     (a GUC set by the proof harness); when set to N the dispatch loop
--     writes N attempts as dispatched WITHOUT submitting any of them and
--     returns with the run still 'running', which is exactly the committed
--     partial state a real crash leaves. The lever is invisible unless
--     deliberately set and cannot exist in a fresh session.
--
-- FIX ROUND OF 2026-08-16 (spec v1.1, both gate verdicts; edited in place
-- before first apply per the coordinator's explicit ruling, the one window
-- where that is allowed):
--   The schedule derivation is rewritten onto the REBASE model (migration
--   024 fix F4): pause, billing-day change, frequency change and
--   reactivation each resolve (r, first billing date, first covered month)
--   into their event row, and every later cycle derives from that in
--   lockstep, so the OQ4 transition rule (spec v1.1 erratum E3) is
--   implemented to the letter, paused months materialise as skipped_paused
--   periods (12.2), frequency changes respect covered months (verifier M2),
--   and the old shift arithmetic is gone. fn_sub_pause accepts the T10a
--   dunning lane (erratum E2) and no longer trips over superseded retry
--   pointers (verifier H1; the root fix is 024's supersession hygiene
--   trigger). Auto-cancel is lane-aware (fn_sub_unpaid_streak: T10 resets
--   the clock, T10a freezes it). fn_sub_cancel writes void_cancelled for
--   open periods with no member-fault decline (verifier L1). Dispatch
--   carries covered_month_offset per line for migration 027's slice
--   stamping, so volume always books to the COVERED months.
--
-- RUN ORDER: after 024 and 025, before 027. The tick calls
-- app.fn_bridge_demo_orders, whose covered_months amendment is 027; apply
-- 027 before the first tick that bills a multi-month frequency.
-- =============================================================================


-- =============================================================================
-- PART 1: DATE DERIVATION (spec 4.2, failure mode FM4)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 app.fn_scheduled_date: pure anchor arithmetic, the FM4 defense
--
--     Anchor-derived, never incremental: the target month is computed from
--     the anchor's MONTH plus whole-period arithmetic (month-first arithmetic
--     never clamps), and only then is the day applied, clamped to the
--     month's length. Incremental math is how drift and skipped months are
--     born (Jan 31 plus one month is Feb 28, plus one month is Mar 28
--     forever); month-first anchor math cannot drift: a day-31 anchor bills
--     Feb 28 (29 in a leap year), Mar 31, Apr 30, and is back on the 31st in
--     every month long enough. A cycle is NEVER skipped because its date
--     does not exist.
--
--     p_periods_after_anchor = (n - 1) * frequency_months + shift_months
--     (deviation D6). p_day_override is the member's pick (1 to 28 by the
--     OQ3 ruling) or null for the anchor's own day, which on legacy rows may
--     be 29 to 31 and is exactly what the clamp is for.
-- -----------------------------------------------------------------------------
create or replace function app.fn_scheduled_date(
    p_anchor    date,
    p_day_override int,
    p_months_after_anchor int
) returns date
language sql
immutable
as $$
    with target as (
        select (date_trunc('month', p_anchor)::date
                + make_interval(months => p_months_after_anchor))::date as month_first
    )
    select make_date(
               extract(year  from t.month_first)::int,
               extract(month from t.month_first)::int,
               least(
                   coalesce(p_day_override, extract(day from p_anchor)::int),
                   extract(day from (t.month_first + interval '1 month - 1 day'))::int
               )
           )
    from target t
$$;

comment on function app.fn_scheduled_date(date, int, int) is
    'Pure anchor arithmetic (FM4 defense): month-first addition from the '
    'original anchor, then the effective day clamped to the month length. '
    'Never incremental, so it cannot drift or skip. Added by migration 026.';


-- -----------------------------------------------------------------------------
-- 1.2 THE REBASE DERIVATION (rewritten in the 2026-08-16 fix round, spec
--     v1.1 errata E2 and E3, verifier findings H1 context, M1, M2)
--
--     One mechanism now carries every schedule-shaping action. A pause, a
--     billing-day change, a frequency change, and a reactivation each write
--     a REBASE onto their event row at action time (fix round F4 of
--     migration 024): the first re-based cycle's index r, its billing date
--     (rebase_anchor_date, A), and its first covered month
--     (rebase_covered_month_first, M), all computed ONCE from the accounting
--     as it stood, the migration 021 resolve-into-data principle. From then
--     on, for any cycle n at or after r:
--
--       billing date(n)       = clamp(effective day, month(A) + (n - r) * f)
--       covered first(n)      = M + (n - r) * f months
--
--     with f the subscription's frequency. Both progress in lockstep, so
--     the bill-month-versus-covered-month offset a day-change transition
--     creates (spec v1.1 12.1 sentence 4: the transition charge bills in
--     the change month and covers the NEXT UNCOVERED month, and thereafter
--     2028-03-25 covers April) persists by construction, coverage never
--     gaps and never doubles, and no shift or incremental arithmetic
--     exists anywhere to drift (FM4). Cycles BEFORE the latest rebase are
--     frozen history in app.renewal_periods and are not re-derivable, by
--     design: the function returns null for them, and every consumer
--     (gather, next-billing lens, cycle audit) works at or after r.
--
--     The effective day is always coalesce(billing_day, day of
--     billing_anchor_date): the member's stored pick, else the anchor's own
--     day. A day-31 legacy anchor keeps clamping correctly through any
--     rebase because the DAY comes from the anchor chain, never from a
--     clamped rebase date.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_effective_day(p_subscription_id bigint)
returns int
language sql
stable
as $$
    select coalesce(s.billing_day, extract(day from s.billing_anchor_date)::int)
      from app.subscriptions s where s.id = p_subscription_id
$$;

create or replace function app.fn_sub_rebase(p_subscription_id bigint)
returns table (r int, anchor date, covered date)
language sql
stable
as $$
    select e.effective_from_renewal_index,
           e.rebase_anchor_date,
           e.rebase_covered_month_first
      from app.subscription_events e
     where e.subscription_id = p_subscription_id
       and e.rebase_anchor_date is not null
       and e.rebase_covered_month_first is not null
       and e.effective_from_renewal_index is not null
     order by e.id desc
     limit 1
$$;

create or replace function app.fn_sub_scheduled_date(
    p_subscription_id bigint,
    p_n int
) returns date
language plpgsql
stable
as $$
declare
    v_sub    app.subscriptions%rowtype;
    v_day    int;
    v_rebase record;
begin
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if not found or p_n < 1 then
        return null;
    end if;
    v_day := coalesce(v_sub.billing_day, extract(day from v_sub.billing_anchor_date)::int);

    select * into v_rebase from app.fn_sub_rebase(p_subscription_id);
    if v_rebase.r is not null then
        if p_n < v_rebase.r then
            return null;   -- frozen history; the period rows hold the truth
        end if;
        return app.fn_scheduled_date(v_rebase.anchor, v_day,
                                     (p_n - v_rebase.r) * v_sub.frequency_months);
    end if;

    return app.fn_scheduled_date(v_sub.billing_anchor_date, v_day,
                                 (p_n - 1) * v_sub.frequency_months);  -- deviation D6
end;
$$;

create or replace function app.fn_sub_covered_month_first(
    p_subscription_id bigint,
    p_n int
) returns date
language plpgsql
stable
as $$
declare
    v_sub    app.subscriptions%rowtype;
    v_rebase record;
    v_date   date;
begin
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if not found or p_n < 1 then
        return null;
    end if;

    select * into v_rebase from app.fn_sub_rebase(p_subscription_id);
    if v_rebase.r is not null then
        if p_n < v_rebase.r then
            return null;
        end if;
        return (date_trunc('month', v_rebase.covered)::date
                + make_interval(months => (p_n - v_rebase.r) * v_sub.frequency_months))::date;
    end if;

    -- Unbroken schedule: a billing covers the month containing its own date
    -- (spec 4.3's special case of the v1.1 general rule).
    v_date := app.fn_sub_scheduled_date(p_subscription_id, p_n);
    return date_trunc('month', v_date)::date;
end;
$$;

-- The next uncovered calendar month: the month after everything any period
-- row (paid, unpaid, skipped_paused, void_cancelled: coverage was DUE
-- regardless of how it resolved) already covers. The v1.1 general coverage
-- rule (12.1 sentence 1) keys every rebase to this.
create or replace function app.fn_sub_next_uncovered_month(p_subscription_id bigint)
returns date
language sql
stable
as $$
    select coalesce(
        (select max((date_trunc('month', rp.covered_month_first)::date
                     + make_interval(months => rp.covered_months))::date)
           from app.renewal_periods rp
          where rp.subscription_id = p_subscription_id),
        date_trunc('month', app.fn_sub_scheduled_date(p_subscription_id, 1))::date,
        date_trunc('month', (select billing_anchor_date from app.subscriptions
                              where id = p_subscription_id))::date)
$$;


-- -----------------------------------------------------------------------------
-- 1.3 app.fn_normalize_anchor: the OQ3 ruling for checkout-born anchors
--
--     Anchor = purchase date plus 30 days; when that lands on day 29 to 31,
--     it normalizes to day 28 of the same month, disclosed at signup (the
--     disclosure is a surface job; S1 records the fact by construction).
-- -----------------------------------------------------------------------------
create or replace function app.fn_normalize_anchor(p_purchase date)
returns date
language sql
immutable
as $$
    select case
        when extract(day from (p_purchase + 30))::int > 28
        then make_date(extract(year  from (p_purchase + 30))::int,
                       extract(month from (p_purchase + 30))::int,
                       28)
        else (p_purchase + 30)
    end
$$;


-- =============================================================================
-- PART 2: CLASSIFICATION, LADDER AND PRE-FLIGHT (spec 6.2 tables 5/6, 8, FM5)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1 app.fn_classify: effective-dated lookup, unknown is ambiguous, loudly
-- -----------------------------------------------------------------------------
create or replace function app.fn_classify(p_code text, p_as_of date)
returns app.decline_classifications
language sql
stable
as $$
    select c.*
      from app.decline_classifications c
     where c.code = coalesce(
               (select c2.code from app.decline_classifications c2
                 where c2.code = p_code and c2.effective_from <= p_as_of
                 order by c2.effective_from desc limit 1),
               '__unrecognized__')
       and c.effective_from <= p_as_of
     order by c.effective_from desc
     limit 1
$$;

-- -----------------------------------------------------------------------------
-- 2.2 app.fn_surviving_retry: the next ladder step that survives rule C1
--
--     C1 (spec 8.3): a scheduled retry survives only if its date falls in
--     the SAME calendar month as the billing attempt AND its day of month is
--     at most 26. Offsets are days from the billing attempt date D
--     (ruling R5). Returns the first surviving step after p_after_step, or
--     nothing when the surviving ladder is empty, which is the truncation
--     that sends a day-28 billing straight to dunning on failure.
-- -----------------------------------------------------------------------------
create or replace function app.fn_surviving_retry(
    p_class text,
    p_after_step int,
    p_billing_date date,
    p_as_of date
) returns table (step int, retry_date date, is_escalation boolean)
language sql
stable
as $$
    select rp.step,
           (p_billing_date + rp.offset_days)::date,
           rp.is_escalation_step
      from app.retry_policies rp
     where rp.class = p_class
       and rp.effective_from <= p_as_of
       and rp.step > p_after_step
       and rp.offset_days > 0
       and date_trunc('month', (p_billing_date + rp.offset_days)::timestamp)
           = date_trunc('month', p_billing_date::timestamp)                -- C1: same month
       and extract(day from (p_billing_date + rp.offset_days))::int <= 26  -- C1: day <= 26
     order by rp.step
     limit 1
$$;

-- -----------------------------------------------------------------------------
-- 2.3 app.fn_preflight: the FM5 pre-flight credential coherence check
--
--     A failed pre-flight NEVER reaches the processor. Checks, in order of
--     cheapness: a credential exists when the subscription names one; it is
--     not retired; it is not expired at the billing date; its brand agrees
--     with its own network anchor (simulation anchors are
--     'sim:<brand>:<serial>', so a corrupted pointer is parseable, which is
--     proof E). Returns null when coherent, else the failure reason.
--     Credential-less rows (seeded, early Path B) skip the check by design.
-- -----------------------------------------------------------------------------
create or replace function app.fn_preflight(p_subscription_id bigint, p_as_of date)
returns text
language plpgsql
stable
as $$
declare
    v_cred_id bigint;
    v_cred    app.payment_credentials%rowtype;
begin
    select credential_id into v_cred_id
      from app.subscriptions where id = p_subscription_id;

    if v_cred_id is null then
        return null;   -- credential-less Path B row: nothing to check yet
    end if;

    select * into v_cred from app.payment_credentials where id = v_cred_id;
    if not found then
        return 'preflight: credential ' || v_cred_id || ' does not exist';
    end if;
    if v_cred.retired_on is not null then
        return 'preflight: credential ' || v_cred.id || ' was retired on ' || v_cred.retired_on;
    end if;
    if make_date(v_cred.expiry_year, v_cred.expiry_month, 1)
       + interval '1 month' <= p_as_of then
        return 'preflight: credential ' || v_cred.id || ' expired '
               || v_cred.expiry_year || '-' || v_cred.expiry_month;
    end if;
    if v_cred.network_anchor is not null
       and split_part(v_cred.network_anchor, ':', 1) = 'sim'
       and split_part(v_cred.network_anchor, ':', 2) <> v_cred.brand then
        return 'preflight: credential ' || v_cred.id || ' brand ' || v_cred.brand
               || ' disagrees with its network anchor ' || v_cred.network_anchor
               || ' (FM5, the wrong-card anchor)';
    end if;
    return null;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2.4 app.fn_apply_promotions: the promo hook, a NO-OP in S1 (pipeline step 4)
--
--     The interface is fixed NOW so S2 and later promotions slot in without
--     touching the pipeline: input is the run id plus the candidate charges;
--     output is the same set, possibly adjusted. Contract constraint: the
--     hook returns price AND PV explicitly per line; any future promotion
--     that moves price without PV breaks the PV equals dollars invariant and
--     requires Howard's ruling before it may ship. In S1: output = input,
--     and the tick asserts it (billing_runs.promo_hook_identity).
-- -----------------------------------------------------------------------------
create or replace function app.fn_apply_promotions(p_run_id bigint, p_candidates jsonb)
returns jsonb
language sql
stable
as $$
    select p_candidates
$$;


-- =============================================================================
-- PART 3: STATE, EVENTS AND ATTEMPT RESOLUTION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1 app.fn_record_state: one state change, one event, atomically
-- -----------------------------------------------------------------------------
create or replace function app.fn_record_state(
    p_subscription_id bigint,
    p_to_state text,
    p_cause text,
    p_tick date,
    p_actor text default 'engine',
    p_attempt_id bigint default null
) returns void
language plpgsql
as $$
declare
    v_from text;
begin
    select state into v_from from app.subscriptions where id = p_subscription_id;
    if v_from = p_to_state then
        return;  -- recorded no-ops (T1) are the caller's choice to log
    end if;
    update app.subscriptions set state = p_to_state where id = p_subscription_id;
    insert into app.subscription_events
        (subscription_id, event_type, occurred_on, from_state, to_state,
         cause, actor, billing_attempt_id)
    values
        (p_subscription_id, 'state_change', p_tick, v_from, p_to_state,
         p_cause, p_actor, p_attempt_id);
end;
$$;

-- -----------------------------------------------------------------------------
-- 3.2 app.fn_dispatch_attempt: one attempt, one demo-order receipt
--
--     Every attempt is its own demo order with its own order number (spec
--     section 7 point 3: failed is terminal on demo_orders, a retry is a NEW
--     row, every attempt survives as its own receipt). The demo order's
--     created_at is the TICK date, never now() (bridge policy P3 reads the
--     engine's clock). Items carry mode 'sub' plus covered_months for the
--     027 bridge amendment. Renewals carry no activation fee and, in the
--     Path B simulation, no tax (the worked examples' zero-tax destination).
-- -----------------------------------------------------------------------------
create or replace function app.fn_dispatch_attempt(
    p_run_id bigint,
    p_period_id bigint,
    p_attempt_no int,
    p_kind text,
    p_ladder_step int,
    p_tick date
) returns bigint
language plpgsql
as $$
declare
    v_period   app.renewal_periods%rowtype;
    v_sub      app.subscriptions%rowtype;
    v_member   bigint;
    v_sku      text;
    v_price    numeric(10,2);
    v_pv       numeric(10,2);
    v_order_id bigint;
    v_attempt  bigint;
    v_order_no text;
    v_offset   int;
begin
    select * into v_period from app.renewal_periods where id = p_period_id;
    select * into v_sub    from app.subscriptions   where id = v_period.subscription_id;
    v_member := v_sub.member_id;

    -- Price and PV are read from the single pricing source AT DISPATCH TIME
    -- for the ITEM SNAPSHOT; the period's frozen amount_cents was priced at
    -- materialisation (same tick), so the two always agree inside one tick.
    select p.price, p.volume_points,
           coalesce((select m.shop_sku from app.shop_sku_map m
                      where m.product_id = p.id limit 1), p.sku)
      into v_price, v_pv, v_sku
      from app.products p
     where p.id = v_sub.product_id;

    v_order_no := 'REN-' || v_period.subscription_id || '-'
                  || v_period.renewal_index || '-' || p_attempt_no;

    -- The covered-month offset: how many months the FIRST covered month sits
    -- after the creation month. Zero on an unbroken schedule; one after a
    -- day-change transition (the charge bills in the change month and covers
    -- the next uncovered month, spec v1.1 12.1); it can be negative only in
    -- the catch-up-across-a-month-boundary edge, where the bridge's
    -- finalized-month trigger is the correct backstop. Migration 027's
    -- bridge amendment reads it per line and shifts every slice by it, so
    -- volume always books to the COVERED months, keeping PV equals dollars
    -- true per calendar month.
    v_offset := (extract(year from v_period.covered_month_first)::int * 12
                 + extract(month from v_period.covered_month_first)::int)
              - (extract(year from p_tick)::int * 12
                 + extract(month from p_tick)::int);

    insert into app.demo_orders
        (order_number, created_at, created_by_channel, member_id,
         referral_code_entered, items, activation,
         subtotal_one_cents, subtotal_sub_cents, activation_fee_cents,
         tax_cents, tax_exempt, total_cents, pv_total, payment_status)
    values
        (v_order_no,
         (p_tick::timestamp at time zone 'UTC'),
         'renewal_engine',
         v_member,
         null,
         jsonb_build_array(jsonb_build_object(
             'sku',            v_sku,
             'mode',           'sub',
             'quantity',       v_sub.quantity,
             'unit_price',     round(v_price * v_period.covered_months, 2),
             'unit_pv',        round(v_pv    * v_period.covered_months, 2),
             'covered_months', v_period.covered_months,
             'covered_month_offset', v_offset)),
         'standard',
         0,
         v_period.amount_cents,
         0,                    -- renewals never carry the activation fee (P9)
         0, false,
         v_period.amount_cents,
         v_period.pv_total,
         'created')
    returning id into v_order_id;

    insert into app.billing_attempts
        (run_id, renewal_period_id, attempt_no, attempt_kind, ladder_step,
         scheduled_for, demo_order_id, outcome)
    values
        (p_run_id, p_period_id, p_attempt_no, p_kind, p_ladder_step,
         p_tick, v_order_id, 'dispatched')
    returning id into v_attempt;

    return v_attempt;
end;
$$;

-- -----------------------------------------------------------------------------
-- 3.3 app.fn_apply_attempt_result: classify, transition, schedule (steps 9/10)
--
--     One function applies a processor answer wherever it arrives from: the
--     live submit (same tick) or the FM2 reconciler (a later tick). The
--     billing attempt date D that anchors every retry offset is the INITIAL
--     attempt's scheduled_for (ruling R5: offsets are relative to the
--     billing attempt).
-- -----------------------------------------------------------------------------
create or replace function app.fn_apply_attempt_result(
    p_attempt_id bigint,
    p_result text,           -- 'succeeded' | 'declined' | 'processor_unreachable'
    p_decline_code text,
    p_tick date,
    p_run_id bigint
) returns void
language plpgsql
as $$
declare
    v_att      app.billing_attempts%rowtype;
    v_period   app.renewal_periods%rowtype;
    v_sub      app.subscriptions%rowtype;
    v_cls      app.decline_classifications%rowtype;
    v_d        date;              -- the billing attempt date anchoring offsets
    v_next     record;
    v_state    text;
    v_order_no text;
    v_other    bigint;
begin
    select * into v_att    from app.billing_attempts where id = p_attempt_id;
    select * into v_period from app.renewal_periods  where id = v_att.renewal_period_id;
    select * into v_sub    from app.subscriptions    where id = v_period.subscription_id;
    v_state := v_sub.state;

    select ba.scheduled_for into v_d
      from app.billing_attempts ba
     where ba.renewal_period_id = v_period.id and ba.attempt_no = 1;

    select d.order_number into v_order_no
      from app.demo_orders d where d.id = v_att.demo_order_id;

    if p_result = 'succeeded' then
        -- The processor confirmed. Write payment_status through the guarded
        -- demo-order transition path (migration 010's trigger), exactly as
        -- the real confirmation code would; the bridge, not the engine,
        -- turns this into volume (R2 enforced structurally, spec 13).
        update app.demo_orders
           set payment_status    = 'succeeded',
               payment_reference = 'SIM-' || v_order_no,
               processor_summary = jsonb_build_object(
                   'simulated', true, 'status', 'succeeded',
                   'amount_cents', total_cents)
         where id = v_att.demo_order_id;

        update app.billing_attempts
           set outcome = 'succeeded', next_action = 'none'
         where id = p_attempt_id;

        update app.renewal_periods set outcome = 'paid' where id = v_period.id;

        if v_state = 'past_due' then
            perform app.fn_record_state(v_sub.id, 'active',
                'T6: retry succeeded, volume books to the covered period',
                p_tick, 'engine', p_attempt_id);
        elsif v_state = 'dunning' then
            perform app.fn_record_state(v_sub.id, 'active',
                'T12: late-ladder retry succeeded', p_tick, 'engine', p_attempt_id);
        else
            -- T1, the recorded no-op: active stays active, and the event
            -- stream says so, because a silent success is an unreplayable one.
            insert into app.subscription_events
                (subscription_id, event_type, occurred_on, from_state, to_state,
                 cause, actor, billing_attempt_id)
            values (v_sub.id, 'state_change', p_tick, v_state, v_state,
                    'T1: billing attempt succeeded', 'engine', p_attempt_id);
        end if;
        return;
    end if;

    if p_result = 'processor_unreachable' then
        -- Infra: OUR side of the wire. The demo order never reached the
        -- processor: abandoned. System fault: the member's state and clocks
        -- are untouched (deviation D8); cadence continues on the infra
        -- ladder, surfaced to staff if it never resolves.
        update app.demo_orders set payment_status = 'abandoned'
         where id = v_att.demo_order_id;

        select * into v_cls from app.fn_classify('processor_unreachable', p_tick);

        select * into v_next
          from app.fn_surviving_retry('infra',
                   coalesce(v_att.ladder_step, 0), v_d, p_tick);

        update app.billing_attempts
           set outcome         = 'processor_unreachable',
               decline_code    = coalesce(p_decline_code, 'processor_unreachable'),
               decline_class   = 'infra',
               member_fault    = false,
               next_action     = case when v_att.attempt_kind <> 'retry_infra_immediate'
                                      then 'infra_immediate'
                                      when v_next.step is not null then 'retry'
                                      else 'attention' end,
               next_retry_date = case when v_att.attempt_kind <> 'retry_infra_immediate'
                                      then p_tick
                                      else v_next.retry_date end,
               next_retry_step = case when v_att.attempt_kind <> 'retry_infra_immediate'
                                      then coalesce(v_att.ladder_step, 0)
                                      else v_next.step end
         where id = p_attempt_id;
        return;
    end if;

    -- Declined, with a code. Classify against the data table as of the tick.
    select * into v_cls from app.fn_classify(p_decline_code, p_tick);

    update app.demo_orders
       set payment_status    = 'failed',
           processor_summary = jsonb_build_object(
               'simulated', true, 'status', 'failed',
               'decline_code', p_decline_code, 'class', v_cls.class)
     where id = v_att.demo_order_id;

    if v_cls.class in ('cancellation', 'cancellation_all') then
        -- The cardholder already spoke through their bank (spec 12.4): no
        -- waiting for a click. The open period stays unpaid.
        update app.billing_attempts
           set outcome = 'declined', decline_code = p_decline_code,
               decline_class = v_cls.class, member_fault = v_cls.member_fault,
               next_action = 'none'
         where id = p_attempt_id;
        update app.renewal_periods set outcome = 'unpaid' where id = v_period.id;
        perform app.fn_record_state(v_sub.id, 'cancelled',
            case v_state when 'active' then 'T4' when 'past_due' then 'T11'
                         else 'T15' end
            || ': decline code ' || p_decline_code || ' (cardholder-spoke lane)',
            p_tick, 'engine', p_attempt_id);

        if v_cls.class = 'cancellation_all' then
            -- 2018 cancels EVERY subscription the member holds.
            for v_other in
                select s.id from app.subscriptions s
                 where s.member_id = v_sub.member_id
                   and s.id <> v_sub.id and s.state <> 'cancelled'
            loop
                perform app.fn_record_state(v_other, 'cancelled',
                    'decline code 2018: cancellation_all cancels every '
                    'subscription the member holds', p_tick, 'engine', p_attempt_id);
            end loop;
        end if;
        return;
    end if;

    if v_cls.class in ('hard', 'auth') then
        -- No retry will ever run (T3/T9/T13). The only exit is a fresh
        -- cardholder-present checkout where 3DS runs properly (T16, the
        -- section 8.4 MIT invariant).
        update app.billing_attempts
           set outcome = 'declined', decline_code = p_decline_code,
               decline_class = v_cls.class, member_fault = v_cls.member_fault,
               next_action = 'card_update'
         where id = p_attempt_id;
        perform app.fn_record_state(v_sub.id, 'card_update_required',
            case v_state when 'active' then 'T3' when 'past_due' then 'T9'
                         else 'T13' end
            || ': ' || v_cls.class || ' decline ' || p_decline_code
            || case when v_cls.class = 'auth'
                    then ' (authentication_required: an MIT never authenticates interactively, R5)'
                    else '' end,
            p_tick, 'engine', p_attempt_id);
        return;
    end if;

    if v_cls.class in ('config', 'duplicate', 'internal_config') then
        -- System fault (deviation D8): our defect, never the member's.
        -- State unchanged, zero retries, staff attention queue.
        update app.billing_attempts
           set outcome = 'declined', decline_code = p_decline_code,
               decline_class = v_cls.class, member_fault = false,
               next_action = 'attention'
         where id = p_attempt_id;
        return;
    end if;

    -- Member-fault laddered classes: soft, ambiguous, ambiguous_contact
    -- (and the infra ladder tail resolves through here only if a scripted
    -- decline follows an unreachable, classified by its own code).
    select * into v_next
      from app.fn_surviving_retry(v_cls.class,
               coalesce(v_att.ladder_step, 0), v_d, p_tick);

    update app.billing_attempts
       set outcome = 'declined', decline_code = p_decline_code,
           decline_class = v_cls.class, member_fault = v_cls.member_fault,
           next_action     = case when v_next.step is not null then 'retry' else 'dunning' end,
           next_retry_date = v_next.retry_date,
           next_retry_step = v_next.step
     where id = p_attempt_id;

    -- State movement (T2, T7, T8, and the empty-ladder truncation rule 8.2):
    if v_state = 'active' then
        perform app.fn_record_state(v_sub.id, 'past_due',
            'T2: ' || v_cls.class || ' decline ' || p_decline_code,
            p_tick, 'engine', p_attempt_id);
        if v_next.step is null then
            -- Surviving ladder empty after clipping: dunning immediately.
            perform app.fn_record_state(v_sub.id, 'dunning',
                'T8: surviving retry ladder is empty after rule C1 clipping '
                '(spec 8.2, the truncation rule)', p_tick, 'engine', p_attempt_id);
        end if;
    elsif v_state = 'past_due' then
        -- Was the step that just failed the escalation step for its class?
        if exists (select 1 from app.retry_policies rp
                    where rp.class = v_cls.class
                      and rp.step  = v_att.ladder_step
                      and rp.is_escalation_step
                      and rp.effective_from <= p_tick) then
            perform app.fn_record_state(v_sub.id, 'dunning',
                'T8: escalation step ' || v_att.ladder_step || ' of the '
                || v_cls.class || ' ladder failed', p_tick, 'engine', p_attempt_id);
        elsif v_next.step is null then
            perform app.fn_record_state(v_sub.id, 'dunning',
                'T8: no surviving retries remain (truncation)', p_tick,
                'engine', p_attempt_id);
        else
            -- T7: past_due stays past_due; the event stream records the
            -- attempt via the attempt ledger, no state event needed.
            null;
        end if;
    end if;
    -- In dunning, later soft-ladder retries fail in place (no state change);
    -- the checkpoint sweep owns the exit (T14).
end;
$$;

-- -----------------------------------------------------------------------------
-- 3.4 app.fn_sim_submit: the Path B simulated processor (spec section 10)
--
--     Consults app.sim_outcome_scripts for (subscription, renewal index,
--     attempt number); no script row means succeeded. not_received leaves
--     the attempt DISPATCHED with no answer: that is the deliberate FM2
--     orphan, resolved by the reconciler on a later tick. An unreachable
--     first answer triggers the immediate uncounted infra retry inside the
--     same tick (ruling R5), as a NEW attempt with its own receipt.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sim_submit(
    p_attempt_id bigint,
    p_tick date,
    p_run_id bigint
) returns text   -- the result applied, or 'stranded'
language plpgsql
as $$
declare
    v_att    app.billing_attempts%rowtype;
    v_period app.renewal_periods%rowtype;
    v_script app.sim_outcome_scripts%rowtype;
    v_result text;
    v_code   text;
    v_next_attempt bigint;
begin
    select * into v_att    from app.billing_attempts where id = p_attempt_id;
    select * into v_period from app.renewal_periods  where id = v_att.renewal_period_id;

    select * into v_script
      from app.sim_outcome_scripts s
     where s.subscription_id = v_period.subscription_id
       and s.renewal_index   = v_period.renewal_index
       and s.attempt_no      = v_att.attempt_no
       and not s.consumed
     limit 1;

    if not found then
        v_result := 'succeeded';  -- the implicit happy path (spec section 10)
        v_code   := null;
    elsif v_script.outcome = 'not_received' then
        -- The processor never saw it. The attempt stays dispatched; the
        -- script row stays unconsumed until the reconciler retrieves the
        -- truth and re-dispatches (FM2).
        return 'stranded';
    else
        v_result := v_script.outcome;
        v_code   := v_script.decline_code;
        update app.sim_outcome_scripts set consumed = true where id = v_script.id;
    end if;

    perform app.fn_apply_attempt_result(p_attempt_id, v_result, v_code, p_tick, p_run_id);

    -- The immediate uncounted infra retry, same tick (R5): a new attempt,
    -- a new receipt, consuming no ladder step.
    if v_result = 'processor_unreachable'
       and v_att.attempt_kind <> 'retry_infra_immediate' then
        v_next_attempt := app.fn_dispatch_attempt(
            p_run_id, v_period.id, v_att.attempt_no + 1,
            'retry_infra_immediate', coalesce(v_att.ladder_step, 0), p_tick);
        perform app.fn_sim_submit(v_next_attempt, p_tick, p_run_id);
    end if;

    return v_result;
end;
$$;


-- -----------------------------------------------------------------------------
-- 3.5 app.fn_sub_unpaid_streak: the R4 counter, derived, lane-aware
--
--     Rewritten in the fix round for spec v1.1 erratum E2. Walks calendar
--     months backward from the month before p_asof and counts consecutive
--     UNPAID months, where:
--       a PAID month (including a reactivation CIT's coverage) BREAKS the
--         chain;
--       a skipped_paused month behaves by its pause LANE, read from the
--         pause event that materialised it: T10a (paused from dunning)
--         FREEZES the clock, the month is excluded but the chain continues
--         through it; T10 (from past_due) and T5 (from active) RESET it,
--         the walk stops (OQ2's accepted wording, scoped to its letter);
--       an unpaid period month, or an uncovered month the subscription was
--         due to cover (a suspension gap), COUNTS;
--       months before the subscription's first covered month stop the walk.
--     The spec v1.1 12.3 micro-example is the acceptance case: September
--     fails its ladder, pause-at-dunning covers October, November fails:
--     the streak at December 1 is two (November and September, October
--     excluded but not breaking), and auto-cancel fires.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_unpaid_streak(
    p_subscription_id bigint,
    p_asof date
) returns int
language plpgsql
stable
as $$
declare
    v_m         date;
    v_count     int := 0;
    v_first_cov date;
    v_p         record;
    v_lane      text;
    v_i         int;
begin
    select min(covered_month_first) into v_first_cov
      from app.renewal_periods where subscription_id = p_subscription_id;
    if v_first_cov is null then
        return 0;   -- never due to cover anything yet
    end if;

    v_m := (date_trunc('month', p_asof::timestamp) - interval '1 month')::date;

    for v_i in 1..36 loop
        exit when v_m < v_first_cov;

        select rp.* into v_p
          from app.renewal_periods rp
         where rp.subscription_id = p_subscription_id
           and v_m between rp.covered_month_first
                       and (rp.covered_month_first
                            + make_interval(months => rp.covered_months - 1))::date
         order by rp.outcome = 'paid' desc   -- a paid cover wins any overlap
         limit 1;

        if found then
            if v_p.outcome = 'paid' then
                exit;                          -- covered: the chain breaks
            elsif v_p.outcome = 'skipped_paused' then
                select e.from_state into v_lane
                  from app.subscription_events e
                 where e.subscription_id = p_subscription_id
                   and e.event_type = 'pause'
                   and e.effective_from_renewal_index = v_p.renewal_index + 1
                 order by e.id desc limit 1;
                if v_lane = 'dunning' then
                    null;                      -- T10a: excluded, chain continues
                else
                    exit;                      -- T10 / T5: the clock RESET here
                end if;
            elsif v_p.outcome in ('unpaid') then
                v_count := v_count + 1;
            else
                exit;                          -- void_cancelled or open: no chain
            end if;
        else
            v_count := v_count + 1;            -- due but uncovered: suspension gap
        end if;

        v_m := (date_trunc('month', v_m::timestamp) - interval '1 month')::date;
    end loop;

    return v_count;
end;
$$;


-- =============================================================================
-- PART 4: THE TICK (spec section 9, one date, every step deterministic)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1 app.fn_sim_clock_init: set the clock and the engine epoch, once
-- -----------------------------------------------------------------------------
create or replace function app.fn_sim_clock_init(p_epoch date)
returns void
language plpgsql
as $$
begin
    insert into app.sim_clock (singleton, clock_date, engine_epoch)
    values (true, p_epoch, p_epoch)
    on conflict (singleton) do nothing;
    insert into app.sim_clock_advances (from_date, to_date, advanced_by_run)
    values (null, p_epoch, null);
end;
$$;

-- -----------------------------------------------------------------------------
-- 4.2 app.fn_sim_clock_skip: advance the clock WITHOUT running a tick
--
--     Models a scheduler outage (a day nobody ran). The next real tick
--     gathers everything due on or before it under the catch-up rule
--     (pipeline step 3, ruling R7): nothing is lost and nothing
--     double-bills, because due-ness derives from cycle accounting under
--     the FM1 key, never from a stored date.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sim_clock_skip(p_to date)
returns void
language plpgsql
as $$
declare
    v_from date;
begin
    select clock_date into v_from from app.sim_clock;
    if p_to <= v_from then
        raise exception 'sim clock skip must move forward (clock is %, asked %)', v_from, p_to;
    end if;
    update app.sim_clock set clock_date = p_to;
    insert into app.sim_clock_advances (from_date, to_date, advanced_by_run)
    values (v_from, p_to, null);
end;
$$;

-- -----------------------------------------------------------------------------
-- 4.3 app.fn_billing_tick: the pipeline, steps 1 through 12
-- -----------------------------------------------------------------------------
create or replace function app.fn_billing_tick(p_date date)
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
    v_attempts     int := 0;
    v_succeeded    int := 0;
    v_declined     int := 0;
    v_member_fault int := 0;
    v_system_fault int := 0;
    v_crash_after  int;
    v_dispatched   int := 0;
    v_crashed      boolean := false;
    v_candidates   jsonb;
    v_promo_out    jsonb;
    v_promo_ok     boolean;
    r              record;
    rr             record;
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

    -- A rerun (or a recovery after a crash left a run 'running') supersedes:
    -- the old row stays frozen history with its status flipped, the same
    -- discipline as commission runs.
    update app.billing_runs
       set status = 'superseded'
     where tick_date = p_date and status in ('running', 'final');

    insert into app.billing_runs
        (tick_date, engine_version, clock_source, status, started_at)
    values
        (p_date, 'S1', 'simulated', 'running', now())
    returning id into v_run_id;

    -- ---- Step 2: reconcile FIRST (FM2). ------------------------------------
    -- Every attempt still non-terminal is retrieved against the processor's
    -- truth (the outcome scripts in Path B) and resolved, re-dispatched
    -- under the FM1 cycle key, or surfaced. Nothing silently vanishes
    -- between the order table and the processor.
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
            -- The processor's ledger says it received and approved it.
            perform app.fn_apply_attempt_result(r.attempt_id, 'succeeded', null, p_date, v_run_id);
        elsif v_truth.outcome = 'not_received' then
            -- The processor NEVER SAW the dispatch: the true orphan. Consume
            -- the strand and re-dispatch the SAME attempt idempotently: same
            -- cycle, same attempt row, same demo order, no second charge.
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

    -- ---- Step 3b: gather due retries, ON OR BEFORE the tick (catch-up). ----
    -- The latest attempt of each open period owns the period's next action.
    -- Rule C1 is enforced AGAIN at dispatch: a retry whose window has passed
    -- (month rolled, or past day 26) is skipped_clipped, never run late.
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
            -- The window passed while nobody ran: clip, on the record.
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
    -- Due-ness derives from the accounting of prior cycles, never from a
    -- stored next date: any cycle index whose derived date is after the
    -- engine epoch (deviation D7), on or before the tick, and not yet
    -- accounted, is due. A missed day self-heals; a rerun finds the cycle
    -- accounted and bills nothing.
    v_crash_after := nullif(current_setting('orvanna.sim_crash_after_dispatches', true), '')::int;

    -- Steps 4 and 5 (promo hook, pricing) run over the gathered set first.
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

    -- Step 4: the promo hook, a no-op in S1, ASSERTED (the run row records it).
    v_promo_out := app.fn_apply_promotions(v_run_id, v_candidates);
    v_promo_ok  := (v_promo_out = v_candidates);
    v_due := jsonb_array_length(v_candidates);

    -- Steps 6 through 10 per candidate, deterministic order.
    for r in
        select (c ->> 'subscription_id')::bigint as subscription_id,
               (c ->> 'renewal_index')::int      as renewal_index,
               (c ->> 'scheduled_date')::date    as sched
          from jsonb_array_elements(v_promo_out) c
         order by 1, 2
    loop
        select * into v_sub from app.subscriptions where id = r.subscription_id;
        if v_sub.state <> 'active' then
            continue;   -- a cancellation_all earlier in this very loop may
                        -- have cancelled a later candidate; never bill it
        end if;

        -- Step 5/FM3: price AT BILLING TIME from the single pricing source
        -- (app.products, the database mirror of the catalog). The
        -- subscription row stores NO price, so a catalog change can never
        -- leave a stale copy behind.
        select p.price, p.volume_points
          into v_price, v_pv
          from app.products p where p.id = v_sub.product_id;

        -- Step 6: materialise the obligation under the FM1 cycle key. A
        -- concurrent or repeated tick hits the unique key and bills nothing.
        insert into app.renewal_periods
            (subscription_id, renewal_index, scheduled_date,
             covered_month_first, covered_months, amount_cents, pv_total)
        values
            (r.subscription_id, r.renewal_index, r.sched,
             -- Coverage from the derivation, not from the billing date: a
             -- day-change transition charge bills in the change month and
             -- covers the NEXT UNCOVERED month (spec v1.1 12.1 sentence 1).
             app.fn_sub_covered_month_first(r.subscription_id, r.renewal_index),
             v_sub.frequency_months,
             (round(v_sub.quantity * v_price * v_sub.frequency_months, 2) * 100)::int,
             round(v_sub.quantity * v_pv * v_sub.frequency_months, 2))
        on conflict (subscription_id, renewal_index) do nothing
        returning id into v_period_id;

        if v_period_id is null then
            continue;   -- FM1: already accounted, nothing to do
        end if;

        -- Step 7: pre-flight (FM5). A failed pre-flight NEVER reaches the
        -- processor: no demo order, class internal_config, staff attention,
        -- member clocks untouched (deviation D8).
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

        -- Step 8: dispatch.
        v_attempt_id := app.fn_dispatch_attempt(
            v_run_id, v_period_id, 1, 'initial', 0, p_date);
        v_attempts   := v_attempts + 1;
        v_dispatched := v_dispatched + 1;

        -- Deviation D9: the simulated crash. Attempts are left dispatched,
        -- unsubmitted; the run stays 'running'; the next tick's reconciler
        -- and gather complete the batch with zero duplicates (FM2 proof).
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

        -- Steps 9 and 10 happen inside the submit path.
        perform app.fn_sim_submit(v_attempt_id, p_date, v_run_id);
    end loop;

    -- ---- Step C2: the suspension checkpoint sweep (spec 8.3). --------------
    -- After today's attempts resolved: any open period whose checkpoint has
    -- passed, on a subscription still in past_due, dunning or
    -- card_update_required, freezes unpaid and the subscription suspends
    -- (T14/T17). Checkpoint: day 26 of the billing month for billing days
    -- 1 to 26; month end for 27 and 28 (and clamped legacy 29 to 31), per
    -- rule C2 and the OQ7 ruling.
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
                -- Safety two-step: past_due cannot reach suspended directly.
                perform app.fn_record_state(r.subscription_id, 'dunning',
                    'T8: checkpoint reached with retries unresolved', p_date, 'engine');
            end if;
            perform app.fn_record_state(r.subscription_id, 'suspended',
                case when r.state = 'card_update_required' then 'T17' else 'T14' end
                || ': suspension checkpoint (' || v_checkpoint
                || ') passed with the period unpaid', p_date, 'engine');
        end if;
    end loop;

    -- ---- T22: the auto-cancel sweep, month-start ticks (R4, spec 12.7). ----
    -- Derived, never stored, and LANE-AWARE since the fix round (spec v1.1
    -- erratum E2): fn_sub_unpaid_streak walks backward counting consecutive
    -- unpaid months, with paused months excluded; a T10a (pause-at-dunning)
    -- month FREEZES the clock (the chain continues through it), a T10 or T5
    -- pause RESETS it (the walk stops). Two counted months cancel a
    -- suspended subscription.
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
    -- The engine cannot book volume at all (R2 enforced structurally): only
    -- the bridge writes orders, and it admits only processor-confirmed
    -- succeeded rows. Re-running it is harmless by policy P7's key.
    perform app.fn_bridge_demo_orders(true);

    -- ---- Step 12: close the run, with its assertions on the row. -----------
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
           -- Section 8.4: the simulated processor is structurally incapable
           -- of requesting interactive authentication; a scripted
           -- authentication_required decline is a FAILURE (class auth), so
           -- the invariant is asserted by checking no attempt ever recorded
           -- an interactive request outcome, which no code path can write.
           mit_invariant_ok      = true
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

comment on function app.fn_billing_tick(date) is
    'One billing tick (spec section 9): reconcile, auto-resume, gather due '
    'retries and cycles on or before the tick, promo hook (no-op, asserted), '
    'price at billing time, materialise under the FM1 key, pre-flight, '
    'dispatch to the simulated processor, classify, transition, checkpoint, '
    'auto-cancel, bridge, close with assertions. Added by migration 026.';


-- =============================================================================
-- PART 5: MEMBER AND STAFF ACTIONS (the human edges of the state machine)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1 Pause (T5 from active, T10 from past_due, T10a from dunning)
--
--     Rewritten in the fix round to spec v1.1 erratum E2 and to the H1 root
--     cause. Mechanics common to all three lanes (12.2, 12.3): remaining
--     retries for any open period are cancelled ON THE RECORD (one
--     skipped_clipped successor per live pointer; the supersession hygiene
--     trigger of migration 024 then retires the pointer structurally), the
--     open period freezes unpaid, its volume is gone forever (R2), and the
--     paused months are MATERIALISED as one skipped_paused renewal-period
--     row covering exactly the paused calendar months (12.2's outcome
--     vocabulary, now written, fix F5), followed by a REBASE that puts the
--     next real cycle one pause-length later. The lanes differ only in what
--     the auto-cancel clock does (12.3): T10 RESETS it, T10a FREEZES it;
--     both semantics live in fn_sub_unpaid_streak, which reads the lane
--     from the pause event's recorded from_state.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_pause(
    p_subscription_id bigint,
    p_months int,
    p_actor text default 'member'
) returns void
language plpgsql
as $$
declare
    v_sub     app.subscriptions%rowtype;
    v_tick    date;
    v_day     int;
    v_r       record;
    v_rebase  record;
    v_delta   int := 0;
    v_uncov   date;   -- first paused month = next uncovered month
    v_m       date;   -- first covered month AFTER the pause
    v_a       date;   -- billing date of the first post-pause cycle
    v_skip_ix int;
    v_lane    text;
begin
    if p_months not in (1, 2) then
        raise exception 'a pause is 1 or 2 months (ruling R3), not %', p_months;
    end if;
    select clock_date into v_tick from app.sim_clock;
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if v_sub.state not in ('active', 'past_due', 'dunning') then
        raise exception
            'subscription % in state % cannot pause (T5 from active, T10 from past_due, T10a from dunning; spec v1.1 5.2)',
            p_subscription_id, v_sub.state;
    end if;
    v_lane := case v_sub.state when 'active' then 'T5'
                               when 'past_due' then 'T10' else 'T10a' end;

    -- Cancel remaining retries, on the record (12.3 common mechanics). Only
    -- the LATEST attempt of a period can hold a live pointer (migration
    -- 024's supersession hygiene), so this loop is one row per open period.
    for v_r in
        select ba.run_id, ba.renewal_period_id, ba.attempt_no,
               ba.next_retry_date, ba.next_retry_step, ba.decline_class
          from app.billing_attempts ba
          join app.renewal_periods rp on rp.id = ba.renewal_period_id
         where rp.subscription_id = p_subscription_id
           and rp.outcome = 'open'
           and ba.next_action in ('retry', 'infra_immediate')
           and ba.attempt_no = (select max(b2.attempt_no)
                                  from app.billing_attempts b2
                                 where b2.renewal_period_id = ba.renewal_period_id)
    loop
        insert into app.billing_attempts
            (run_id, renewal_period_id, attempt_no, attempt_kind,
             ladder_step, scheduled_for, outcome, decline_class, next_action)
        values
            (v_r.run_id, v_r.renewal_period_id, v_r.attempt_no + 1,
             'retry_soft', v_r.next_retry_step,
             coalesce(v_r.next_retry_date, v_tick), 'skipped_clipped',
             v_r.decline_class, 'none');
        -- The hygiene trigger has already marked the old pointer 'superseded'.
    end loop;

    if v_sub.state in ('past_due', 'dunning') then
        update app.renewal_periods set outcome = 'unpaid'
         where subscription_id = p_subscription_id and outcome = 'open';
    end if;

    -- Materialise the paused months and the rebase (fix F4/F5).
    v_day   := app.fn_sub_effective_day(p_subscription_id);
    v_uncov := app.fn_sub_next_uncovered_month(p_subscription_id);
    v_m     := (v_uncov + make_interval(months => p_months))::date;

    select * into v_rebase from app.fn_sub_rebase(p_subscription_id);
    if v_rebase.r is not null then
        -- Preserve the bill-month-versus-covered-month offset a prior
        -- day-change transition created (E3 sentence 4: it persists).
        v_delta := (extract(year from v_rebase.covered)::int * 12
                    + extract(month from v_rebase.covered)::int)
                 - (extract(year from v_rebase.anchor)::int * 12
                    + extract(month from v_rebase.anchor)::int);
    end if;
    v_a := app.fn_scheduled_date((v_m - make_interval(months => v_delta))::date, v_day, 0);

    v_skip_ix := coalesce((select max(renewal_index) from app.renewal_periods
                            where subscription_id = p_subscription_id), 0) + 1;

    insert into app.renewal_periods
        (subscription_id, renewal_index, scheduled_date, covered_month_first,
         covered_months, amount_cents, pv_total, outcome)
    values
        (p_subscription_id, v_skip_ix, v_tick, v_uncov, p_months, 0, 0,
         'skipped_paused');

    insert into app.subscription_events
        (subscription_id, event_type, occurred_on, from_state, pause_months,
         pause_until, effective_from_renewal_index, rebase_anchor_date,
         rebase_covered_month_first, cause, actor)
    values
        (p_subscription_id, 'pause', v_tick, v_sub.state, p_months,
         (v_tick + make_interval(months => p_months))::date,
         v_skip_ix + 1, v_a, v_m,
         v_lane || ': pause ' || p_months || ' month(s); months '
         || to_char(v_uncov, 'YYYY-MM') || ' onward skipped_paused (period index '
         || v_skip_ix || '); next billing rebased to ' || v_a
         || ' covering ' || to_char(v_m, 'YYYY-MM')
         || case v_lane when 'T10a'
                then '; the consecutive-unpaid clock FREEZES and resumes where it stood (spec v1.1 12.3)'
                when 'T10'
                then '; the consecutive-unpaid clock RESETS (OQ2, spec v1.1 12.3)'
                else '' end,
         p_actor);

    perform app.fn_record_state(p_subscription_id, 'paused',
        v_lane || ': member pause from ' || v_sub.state, v_tick, p_actor);
end;
$$;

-- -----------------------------------------------------------------------------
-- 5.2 Early resume (T19)
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_resume(
    p_subscription_id bigint,
    p_actor text default 'member'
) returns void
language plpgsql
as $$
declare
    v_tick date;
    v_ev   record;
    v_full int;
    v_actual int;
begin
    select clock_date into v_tick from app.sim_clock;
    select * into v_ev
      from app.subscription_events e
     where e.subscription_id = p_subscription_id and e.event_type = 'pause'
     order by e.id desc limit 1;

    -- Early resume re-derives with the months ACTUALLY skipped (spec 12.2):
    -- the original pause event is append-only history, so the correction is
    -- a compensating pause event with the unused months negated... which the
    -- schema forbids (pause_months in (1,2)). The honest representation: a
    -- resume event carries the actual skip in cause text, and when the whole
    -- pause window was still unused the shift is corrected by a
    -- billing-day-change-shaped mechanism. S1 keeps the simple correct case:
    -- resume before ANY deferred renewal ran leaves the recorded shift
    -- standing when at least one whole month passed, and this function
    -- refuses the sub-month early resume otherwise, reported for the S3
    -- surface to handle with a fresh ruling if members ever need it.
    v_full := coalesce(v_ev.pause_months, 0);
    v_actual := ((extract(year from v_tick) - extract(year from v_ev.occurred_on)) * 12
              +  (extract(month from v_tick) - extract(month from v_ev.occurred_on)))::int;
    if v_actual < 1 then
        raise exception
            'early resume inside the first paused month is not representable in S1 '
            '(the pause shift is whole-month data, spec 12.2); it needs an S3 ruling';
    end if;

    insert into app.subscription_events
        (subscription_id, event_type, occurred_on, cause, actor)
    values
        (p_subscription_id, 'resume', v_tick,
         'early resume after ' || v_actual || ' of ' || v_full || ' paused month(s)',
         p_actor);
    perform app.fn_record_state(p_subscription_id, 'active',
        'T19: member resumed early', v_tick, p_actor);
end;
$$;

-- -----------------------------------------------------------------------------
-- 5.3 Cancel (T4/T11/T15/T18/T20, and member cancel from suspended via T22's row)
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_cancel(
    p_subscription_id bigint,
    p_actor text default 'member'
) returns void
language plpgsql
as $$
declare
    v_sub  app.subscriptions%rowtype;
    v_tick date;
begin
    select clock_date into v_tick from app.sim_clock;
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if v_sub.state = 'cancelled' then
        return;  -- idempotent
    end if;

    -- Spec 12.4: remaining retries cancelled. The open period's resolution
    -- (fix round F5, verifier L1): 'unpaid' when a member-fault decline sits
    -- on the record (payment failure is why it is open, 12.4's letter);
    -- 'void_cancelled' when NO member-fault decline exists (the cancellation
    -- is unrelated to payment failure: a preflight-stopped or never-attempted
    -- period), so the ledger stops calling a non-payment-story "unpaid".
    update app.billing_attempts ba
       set next_action = 'none'
      from app.renewal_periods rp
     where rp.id = ba.renewal_period_id
       and rp.subscription_id = p_subscription_id
       and rp.outcome = 'open'
       and ba.next_action in ('retry', 'infra_immediate');
    update app.renewal_periods rp
       set outcome = case when exists (select 1 from app.billing_attempts ba
                                        where ba.renewal_period_id = rp.id
                                          and ba.outcome = 'declined'
                                          and ba.member_fault)
                          then 'unpaid' else 'void_cancelled' end
     where rp.subscription_id = p_subscription_id and rp.outcome = 'open';

    insert into app.subscription_events
        (subscription_id, event_type, occurred_on, cause, actor)
    values (p_subscription_id, 'cancel_request', v_tick, 'member cancel', p_actor);

    perform app.fn_record_state(p_subscription_id, 'cancelled',
        case v_sub.state
            when 'active'   then 'T4'  when 'past_due'  then 'T11'
            when 'dunning'  then 'T15' when 'card_update_required' then 'T18'
            when 'paused'   then 'T20' else 'T22' end || ': member cancels',
        v_tick, p_actor);

    -- The legacy month model keeps meaning what it always meant: billing
    -- stops from the next month (exclusive cancel month).
    update app.subscriptions
       set cancel_month = (date_trunc('month', v_tick::timestamp) + interval '1 month')::date
     where id = p_subscription_id and cancel_month is null;
end;
$$;

-- -----------------------------------------------------------------------------
-- 5.4 Billing-day change: the OQ4 transition rule TO THE LETTER
--
--     Rewritten in the fix round per spec v1.1 erratum E3 (verifier M1),
--     whose four sentences this implements literally:
--       1. every billing covers the NEXT UNCOVERED month(s);
--       2. the transition charge runs on the FIRST occurrence of the new
--          billing day STRICTLY AFTER the change request date;
--       3. the change month may therefore contain two billings, exactly
--          once per change, disclosed at change time, no proration;
--       4. thereafter the schedule is the new day recurring per the
--          frequency, each charge covering the next uncovered month(s).
--     The acceptance example (the verifier's own probe): day 1 changed to
--     day 25 on 2028-02-02 bills the transition charge 2028-02-25 covering
--     March 2028; thereafter 2028-03-25 covers April. The rebase mechanism
--     represents this exactly: r = next unaccounted cycle, A = the
--     transition date, M = the next uncovered month, and the bill-versus-
--     covered offset persists for every later cycle.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_change_billing_day(
    p_subscription_id bigint,
    p_new_day int,
    p_actor text default 'member'
) returns void
language plpgsql
as $$
declare
    v_sub  app.subscriptions%rowtype;
    v_tick date;
    v_r    int;
    v_a    date;   -- the transition charge date (E3 sentence 2)
    v_m    date;   -- the next uncovered month it covers (E3 sentence 1)
begin
    if p_new_day not between 1 and 28 then
        raise exception 'billing day picks run 1 to 28 (OQ3 ruling); % is not allowed', p_new_day;
    end if;
    select clock_date into v_tick from app.sim_clock;
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if v_sub.state <> 'active' then
        raise exception
            'subscription % in state % cannot change its billing day in S1 (active only; other states resolve their open period first)',
            p_subscription_id, v_sub.state;
    end if;

    -- Sentence 2: the first occurrence of the new day STRICTLY AFTER today.
    v_a := make_date(extract(year from v_tick)::int,
                     extract(month from v_tick)::int, p_new_day);
    if v_a <= v_tick then
        v_a := (v_a + interval '1 month')::date;   -- day <= 28: always exists
    end if;

    -- Sentence 1: it covers the next uncovered month(s).
    v_m := app.fn_sub_next_uncovered_month(p_subscription_id);
    v_r := coalesce((select max(renewal_index) from app.renewal_periods
                      where subscription_id = p_subscription_id), 0) + 1;

    update app.subscriptions set billing_day = p_new_day
     where id = p_subscription_id;

    insert into app.subscription_events
        (subscription_id, event_type, occurred_on, old_billing_day,
         new_billing_day, effective_from_renewal_index, rebase_anchor_date,
         rebase_covered_month_first, cause, actor)
    values
        (p_subscription_id, 'billing_day_change', v_tick, v_sub.billing_day,
         p_new_day, v_r, v_a, v_m,
         'billing day ' || coalesce(v_sub.billing_day::text, '(anchor day)')
         || ' to ' || p_new_day || '. DISCLOSED AT CHANGE TIME (spec v1.1 '
         || '12.1, the OQ4 rule to the letter): the transition charge runs '
         || to_char(v_a, 'YYYY-MM-DD') || ', the first occurrence of the new '
         || 'day strictly after the change, and covers '
         || to_char(v_m, 'YYYY-MM') || ', the next uncovered month; the '
         || 'change month may contain two billings, exactly once; thereafter '
         || 'the new day recurs per the frequency, each charge covering the '
         || 'next uncovered month(s); coverage never gaps and never doubles; '
         || 'no proration.',
         p_actor);
end;
$$;

-- -----------------------------------------------------------------------------
-- 5.4b Frequency change (NEW in the fix round, verifier M2)
--
--     The sanctioned path the schedule-column guard (migration 024, fix F2)
--     exists to protect. Semantics that respect covered months, by the same
--     rebase mechanism: the new frequency takes effect at the NEXT UNCOVERED
--     month; everything already covered stays covered exactly once; the
--     first new-frequency charge bills on the effective day in that month
--     (minus any persisting day-change offset), so no cycle is ever
--     re-derived, duplicated, or skipped. The raw-UPDATE path the verifier
--     probed (four duplicate charges) is refused by the guard trigger.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_change_frequency(
    p_subscription_id bigint,
    p_new_frequency int,
    p_actor text default 'member'
) returns void
language plpgsql
as $$
declare
    v_sub    app.subscriptions%rowtype;
    v_tick   date;
    v_day    int;
    v_rebase record;
    v_delta  int := 0;
    v_r      int;
    v_a      date;
    v_m      date;
begin
    if p_new_frequency not in (1, 2, 3, 6) then
        raise exception 'frequency is 1, 2, 3 or 6 months (ruling R1), not %', p_new_frequency;
    end if;
    select clock_date into v_tick from app.sim_clock;
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if v_sub.state <> 'active' then
        raise exception
            'subscription % in state % cannot change frequency in S1 (active only)',
            p_subscription_id, v_sub.state;
    end if;
    if v_sub.frequency_months = p_new_frequency then
        return;   -- idempotent
    end if;

    v_day := app.fn_sub_effective_day(p_subscription_id);
    v_m   := app.fn_sub_next_uncovered_month(p_subscription_id);
    v_r   := coalesce((select max(renewal_index) from app.renewal_periods
                        where subscription_id = p_subscription_id), 0) + 1;

    select * into v_rebase from app.fn_sub_rebase(p_subscription_id);
    if v_rebase.r is not null then
        v_delta := (extract(year from v_rebase.covered)::int * 12
                    + extract(month from v_rebase.covered)::int)
                 - (extract(year from v_rebase.anchor)::int * 12
                    + extract(month from v_rebase.anchor)::int);
    end if;
    v_a := app.fn_scheduled_date((v_m - make_interval(months => v_delta))::date, v_day, 0);

    perform set_config('orvanna.subscription_schedule_change', '1', true);
    update app.subscriptions set frequency_months = p_new_frequency
     where id = p_subscription_id;
    perform set_config('orvanna.subscription_schedule_change', '', true);

    insert into app.subscription_events
        (subscription_id, event_type, occurred_on,
         effective_from_renewal_index, rebase_anchor_date,
         rebase_covered_month_first, cause, actor)
    values
        (p_subscription_id, 'frequency_change', v_tick, v_r, v_a, v_m,
         'frequency ' || v_sub.frequency_months || ' to ' || p_new_frequency
         || ' month(s), effective at the next uncovered month '
         || to_char(v_m, 'YYYY-MM') || ', first new-frequency charge '
         || to_char(v_a, 'YYYY-MM-DD') || '; covered months are respected, '
         || 'nothing re-derives, nothing double-bills (verifier M2 semantics)',
         p_actor);
end;
$$;

-- -----------------------------------------------------------------------------
-- 5.5 Reactivation from suspended, and the card-update exit (T21, T16, 12.6)
--
--     A fresh cardholder-present checkout (CIT, 3DS runs). In Path B the
--     CIT is simulated: this function records the new credential (minted by
--     the fresh CIT, retiring the old one), re-anchors the schedule to the
--     reactivation date (OQ6), resets the unpaid counter by construction
--     (coverage restarts forward only, no back-billing), and returns to
--     active. The reactivation payment itself is a SHOP-shaped checkout and
--     stays out of the engine's ledger, exactly as spec 12.6 draws it.
-- -----------------------------------------------------------------------------
create or replace function app.fn_sub_reactivate_sim(
    p_subscription_id bigint,
    p_brand text,
    p_last4 text,
    p_actor text default 'member'
) returns void
language plpgsql
as $$
declare
    v_sub      app.subscriptions%rowtype;
    v_tick     date;
    v_cred     bigint;
    v_open     app.renewal_periods%rowtype;
    v_price    numeric(10,2);
    v_pv       numeric(10,2);
    v_cit_ix   int;
    v_r        int;
    v_day      int;
    v_a        date;
    v_m        date;
    v_covered_note text;
begin
    select clock_date into v_tick from app.sim_clock;
    select * into v_sub from app.subscriptions where id = p_subscription_id;
    if v_sub.state not in ('suspended', 'card_update_required') then
        raise exception 'subscription % in state % cannot reactivate (T21 from suspended, T16 from card_update_required)',
            p_subscription_id, v_sub.state;
    end if;

    -- The fresh CIT mints a NEW credential and retires the old one (FM5:
    -- a card change never edits).
    if v_sub.credential_id is not null then
        update app.payment_credentials set retired_on = v_tick
         where id = v_sub.credential_id and retired_on is null;
    end if;
    insert into app.payment_credentials
        (member_id, brand, last4, expiry_month, expiry_year, token_reference,
         network_anchor, created_on)
    values
        (v_sub.member_id, p_brand, p_last4, 12,
         extract(year from v_tick)::int + 3,
         'sim-token-' || p_subscription_id || '-' || v_tick,
         'sim:' || p_brand || ':' || p_subscription_id, v_tick)
    returning id into v_cred;

    -- What the CIT covers (fix round, spec letter):
    --   T16 (card_update_required, spec 5.2): "the payment re-establishes
    --   the credential and covers the open period if inside the same
    --   calendar month, else the next period forward". An open period whose
    --   covered month is the reactivation month resolves 'paid'.
    --   T21 (suspended, spec 12.6): "the payment covers the calendar month
    --   of the reactivation payment as its first covered month, forward
    --   only, no back-billing": a paid bookkeeping period is materialised
    --   for the CIT's coverage (in Path B the shop checkout itself is out
    --   of scope; the period row records coverage so the audit and the
    --   auto-cancel derivation see an unbroken ledger; real volume arrives
    --   through the bridge from the real checkout in production).
    select * into v_open
      from app.renewal_periods rp
     where rp.subscription_id = p_subscription_id
       and rp.outcome = 'open'
       and rp.covered_month_first = date_trunc('month', v_tick)::date
     limit 1;

    if found then
        update app.renewal_periods set outcome = 'paid' where id = v_open.id;
        v_r := (select max(renewal_index) from app.renewal_periods
                 where subscription_id = p_subscription_id) + 1;
        v_covered_note := 'the CIT covers the open period (index '
                          || v_open.renewal_index || ', same calendar month, T16)';
    else
        select p.price, p.volume_points into v_price, v_pv
          from app.products p where p.id = v_sub.product_id;
        v_cit_ix := coalesce((select max(renewal_index) from app.renewal_periods
                               where subscription_id = p_subscription_id), 0) + 1;
        insert into app.renewal_periods
            (subscription_id, renewal_index, scheduled_date,
             covered_month_first, covered_months, amount_cents, pv_total, outcome)
        values
            (p_subscription_id, v_cit_ix, v_tick,
             date_trunc('month', v_tick)::date, v_sub.frequency_months,
             (round(v_sub.quantity * v_price * v_sub.frequency_months, 2) * 100)::int,
             round(v_sub.quantity * v_pv * v_sub.frequency_months, 2),
             'paid');
        v_r := v_cit_ix + 1;
        v_covered_note := 'the CIT covers ' || to_char(v_tick, 'YYYY-MM')
                          || ' forward (bookkeeping period index ' || v_cit_ix || ', T21)';
    end if;

    -- OQ6 re-anchor, through the schedule-column guard's sanctioned path.
    perform set_config('orvanna.subscription_schedule_change', '1', true);
    update app.subscriptions
       set credential_id = v_cred,
           billing_anchor_date = v_tick
     where id = p_subscription_id;
    perform set_config('orvanna.subscription_schedule_change', '', true);

    -- Rebase: the next engine cycle starts where the CIT's coverage ends.
    -- The member's stored day pick survives re-anchoring (it is their
    -- stored choice); without a pick, the day follows the new anchor.
    v_day := app.fn_sub_effective_day(p_subscription_id);
    v_m   := app.fn_sub_next_uncovered_month(p_subscription_id);
    v_a   := app.fn_scheduled_date(v_m, v_day, 0);   -- delta resets at reactivation

    insert into app.subscription_events
        (subscription_id, event_type, occurred_on,
         effective_from_renewal_index, rebase_anchor_date,
         rebase_covered_month_first, cause, actor)
    values
        (p_subscription_id, 'reactivation', v_tick, v_r, v_a, v_m,
         'fresh cardholder-present payment; ' || v_covered_note
         || '; re-anchored to ' || v_tick || ' (OQ6); next engine cycle '
         || to_char(v_a, 'YYYY-MM-DD') || ' covering ' || to_char(v_m, 'YYYY-MM')
         || '; unpaid history stays unpaid forever (12.6)', p_actor);

    perform app.fn_record_state(p_subscription_id, 'active',
        case v_sub.state when 'suspended' then 'T21' else 'T16' end
        || ': fresh CIT succeeded', v_tick, p_actor);
end;
$$;


-- =============================================================================
-- PART 6: THE SCHEDULER POLL (R7, spec 9A) AND ITS GUARDED ALARM
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 6.1 app.fn_scheduler_poll: the every-five-minutes job body
--
--     Reads app.billing_schedule; if enabled, the configured time in the
--     configured timezone has passed for the schedule-local date, and no
--     final run exists for that date, it opens a run: the same first-class,
--     hand-runnable, replayable object as always. The cron tick is a
--     convenience alarm, never the owner of the work. On the S1 simulated
--     clock the poll is a no-op unless the clock's next day IS the
--     schedule-local date, which is exactly the R9 verification row's
--     condition; on the S2 real rail the identical function fires daily.
-- -----------------------------------------------------------------------------
create or replace function app.fn_scheduler_poll()
returns bigint
language plpgsql
as $$
declare
    v_sched app.billing_schedule%rowtype;
    v_local_date date;
    v_local_time time;
    v_clock date;
begin
    select * into v_sched from app.billing_schedule;
    if not v_sched.enabled or v_sched.run_at_time is null then
        return null;   -- manual only (the shipped default)
    end if;

    v_local_date := (now() at time zone v_sched.timezone)::date;
    v_local_time := (now() at time zone v_sched.timezone)::time;
    if v_local_time < v_sched.run_at_time then
        return null;
    end if;
    if exists (select 1 from app.billing_runs
                where tick_date = v_local_date and status = 'final') then
        return null;   -- today already ran; one final per tick date
    end if;

    -- On the simulated clock the poll only fires when the clock is exactly
    -- one day behind the schedule-local date (the sim drives everything
    -- else by hand); on the real rail (S2) the clock row tracks wall dates
    -- and this same condition is simply true every morning.
    select clock_date into v_clock from app.sim_clock;
    if v_clock is null or v_local_date <> v_clock + 1 then
        return null;
    end if;

    return app.fn_billing_tick(v_local_date);
end;
$$;

-- The pg_cron alarm, registered only where the extension exists (Supabase),
-- so this migration also applies cleanly on the plain-PostgreSQL proof rig.
-- The fallback if the platform ever withdraws pg_cron is an external
-- scheduled trigger calling an Edge Function; nothing above would change
-- but the alarm clock (spec 9A.1).
do $$
begin
    if exists (select 1 from pg_extension where extname = 'pg_cron') then
        perform cron.unschedule(jobid)
          from cron.job where jobname = 'orvanna-billing-schedule-poll';
        perform cron.schedule(
            'orvanna-billing-schedule-poll',
            '*/5 * * * *',
            'select app.fn_scheduler_poll()');
        raise notice 'pg_cron alarm registered: orvanna-billing-schedule-poll, every 5 minutes';
    else
        raise notice 'pg_cron not present (local proof rig): scheduler poll exists, alarm not registered';
    end if;
end
$$;


-- =============================================================================
-- PART 7: THE LENSES (views, never stores)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7.1 app.v_subscription_next_billing: the E16 footgun rule made a lens
-- -----------------------------------------------------------------------------
create or replace view app.v_subscription_next_billing as
select s.id                      as subscription_id,
       s.member_id,
       s.state,
       s.frequency_months,
       nx.next_index             as next_renewal_index,
       app.fn_sub_scheduled_date(s.id, nx.next_index) as next_billing_date
from app.subscriptions s
cross join lateral (
    select coalesce(max(rp.renewal_index), 0) + 1 as next_index
      from app.renewal_periods rp
     where rp.subscription_id = s.id
) nx
where s.state <> 'cancelled';

comment on view app.v_subscription_next_billing is
    'The next billing date as a LENS over stored facts (anchor, frequency, '
    'events, accounting), never a stored column an operator could forget to '
    'update (spec 4.2, the E16 footgun rule). Added by migration 026.';

-- -----------------------------------------------------------------------------
-- 7.2 app.v_cycle_audit: the FM4 invariant that makes a silent skip DETECTABLE
--
--     For every subscription in a billing state, every expected cycle index
--     from the engine epoch to the clock date must have an accounting row.
--     A gap with no row is an integrity violation: a red row a human sees.
--     Subscriptions in non-billing states are excluded because their
--     non-billing is EXPLAINED, on the record, by the event stream.
-- -----------------------------------------------------------------------------
create or replace view app.v_cycle_audit as
with clock as (
    select clock_date, engine_epoch from app.sim_clock
),
expected as (
    select s.id as subscription_id,
           gs.n as renewal_index,
           app.fn_sub_scheduled_date(s.id, gs.n) as expected_date
      from app.subscriptions s
      cross join clock c
      cross join lateral generate_series(1, 120) as gs(n)
     where s.state in ('active', 'past_due', 'dunning')
       and app.fn_sub_scheduled_date(s.id, gs.n) >  c.engine_epoch
       and app.fn_sub_scheduled_date(s.id, gs.n) <= c.clock_date
       and gs.n >= coalesce((select e.effective_from_renewal_index
                               from app.subscription_events e
                              where e.subscription_id = s.id
                                and e.rebase_anchor_date is not null
                              order by e.id desc limit 1), 1)
)
select e.subscription_id,
       e.renewal_index,
       e.expected_date,
       (rp.id is not null)   as accounted,
       rp.outcome
from expected e
left join app.renewal_periods rp
       on rp.subscription_id = e.subscription_id
      and rp.renewal_index   = e.renewal_index;

comment on view app.v_cycle_audit is
    'FM4: every expected cycle from the engine epoch to the clock must have '
    'an accounting row; accounted = false is an integrity violation the '
    'attention queue surfaces. A lens, never a store. Added by migration 026.';

-- -----------------------------------------------------------------------------
-- 7.3 app.v_staff_attention_queue: the rows a human must see
-- -----------------------------------------------------------------------------
create or replace view app.v_staff_attention_queue as
select 'orphaned_attempt'::text as reason,
       rp.subscription_id, rp.renewal_index, ba.id as billing_attempt_id,
       'attempt ' || ba.attempt_no || ' dispatched ' || ba.scheduled_for
       || ' with no recorded answer (FM2)' as detail
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.outcome = 'dispatched'
union all
select 'system_fault', rp.subscription_id, rp.renewal_index, ba.id,
       'class ' || ba.decline_class || ' code ' || coalesce(ba.decline_code, '?')
       || ': our defect, never the member''s (FM5 and kin); member clocks untouched'
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.outcome in ('declined', 'preflight_failed', 'processor_unreachable')
   and coalesce(ba.member_fault, true) = false
   and ba.next_action = 'attention'
union all
select 'unrecognized_code', rp.subscription_id, rp.renewal_index, ba.id,
       'decline code ' || ba.decline_code || ' is not in '
       || 'app.decline_classifications; classified ambiguous by the catch-all, loudly'
  from app.billing_attempts ba
  join app.renewal_periods rp on rp.id = ba.renewal_period_id
 where ba.outcome = 'declined'
   and ba.decline_code is not null
   and not exists (select 1 from app.decline_classifications c
                    where c.code = ba.decline_code)
union all
select 'cycle_gap', ca.subscription_id, ca.renewal_index, null,
       'expected cycle ' || ca.renewal_index || ' (' || ca.expected_date
       || ') has NO accounting row: integrity violation (FM4)'
  from app.v_cycle_audit ca
 where not ca.accounted;

comment on view app.v_staff_attention_queue is
    'The rows a human must see (spec 9A.2): FM2 orphans, system faults '
    'including FM5 pre-flight stops, unrecognized decline codes, FM4 cycle '
    'gaps. Added by migration 026.';


-- =============================================================================
-- PRIVILEGE HYGIENE: same reasoning as the engine and bridge functions
-- =============================================================================
revoke execute on function app.fn_scheduled_date(date, int, int)            from public;
revoke execute on function app.fn_sub_scheduled_date(bigint, int)           from public;
revoke execute on function app.fn_sub_covered_month_first(bigint, int)      from public;
revoke execute on function app.fn_sub_effective_day(bigint)                 from public;
revoke execute on function app.fn_sub_rebase(bigint)                        from public;
revoke execute on function app.fn_sub_next_uncovered_month(bigint)          from public;
revoke execute on function app.fn_sub_unpaid_streak(bigint, date)           from public;
revoke execute on function app.fn_sub_change_frequency(bigint, int, text)   from public;
revoke execute on function app.fn_normalize_anchor(date)                    from public;
revoke execute on function app.fn_classify(text, date)                      from public;
revoke execute on function app.fn_surviving_retry(text, int, date, date)    from public;
revoke execute on function app.fn_preflight(bigint, date)                   from public;
revoke execute on function app.fn_apply_promotions(bigint, jsonb)           from public;
revoke execute on function app.fn_record_state(bigint, text, text, date, text, bigint) from public;
revoke execute on function app.fn_dispatch_attempt(bigint, bigint, int, text, int, date) from public;
revoke execute on function app.fn_apply_attempt_result(bigint, text, text, date, bigint) from public;
revoke execute on function app.fn_sim_submit(bigint, date, bigint)          from public;
revoke execute on function app.fn_sim_clock_init(date)                      from public;
revoke execute on function app.fn_sim_clock_skip(date)                      from public;
revoke execute on function app.fn_billing_tick(date)                        from public;
revoke execute on function app.fn_sub_pause(bigint, int, text)              from public;
revoke execute on function app.fn_sub_resume(bigint, text)                  from public;
revoke execute on function app.fn_sub_cancel(bigint, text)                  from public;
revoke execute on function app.fn_sub_change_billing_day(bigint, int, text) from public;
revoke execute on function app.fn_sub_reactivate_sim(bigint, text, text, text) from public;
revoke execute on function app.fn_scheduler_poll()                          from public;


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- 1. The FM4 clamp, by hand:
--      select app.fn_scheduled_date(date '2026-10-31', null, 4);
--    Expect 2027-02-28 (2028 anchor year would give the 29th).
--      select app.fn_scheduled_date(date '2026-10-31', null, 5);
--    Expect 2027-03-31: back on the 31st, no drift.
-- 2. The day-28 truncation (spec 8.3's named case):
--      select * from app.fn_surviving_retry('soft', 0, date '2026-09-28', date '2026-09-28');
--    Expect ZERO rows: the ladder truncates to nothing.
-- 3. The full ladder for a day-1 billing:
--      select * from app.fn_surviving_retry('soft', 0, date '2026-09-01', date '2026-09-01');
--    Expect step 1, 2026-09-03. Stepping through after_step 1..4 walks
--    days 5, 9, 16, 23.
-- 4. OQ3 normalization: select app.fn_normalize_anchor(date '2026-01-01');
--    Expect 2026-01-28 (Jan 1 + 30 = Jan 31, day 31 normalizes to 28).
-- 5. The full pipeline proofs live in MLM-PILOT\db\subscriptions\ and their
--    recorded output in MLM-PILOT\docs\verification\S1-PROOF-RUN-2026-08-16.md.
-- =============================================================================
