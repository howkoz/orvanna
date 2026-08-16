-- =============================================================================
-- Migration 021: calendar-month containment, and the one-time volume schedule
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-15
-- Author:  mlm-comp-engineer
-- Answers: design decision 4.1, ANSWERED BY HOWARD 2026-08-15.
--          His words: "spread it for now but going forward lets keep everything
--          within a calendar month and we run the entire commissions end of
--          month".
-- Design:  DOCUMENTATION\09-LINKING-SHOP-TO-COMP.md, section 11.
--
-- STATUS: APPLIED 2026-08-16 to the live project (mlm-pilot, oiyibdczkokegaxkwulv)
--         as migration calendar_month_containment_021, immediately after 020, on
--         Howard's straight-to-production ruling. Decision record:
--         MLM-PILOT\docs\decisions\2026-08-16-bridge-seven-decisions.md.
--         Note: migration 022 (refunds) was applied BEFORE this file even though
--         its header names 021 in its run order; 022 detects the state of 019 and
--         021 at run time and behaves correctly either way.
--         From this point this file is FROZEN: applied SQL is never edited, a
--         follow-up change is a new numbered migration.
--
-- LAYERS ON TOP OF 019 AND 020, EDITS NEITHER. Migration 019 is byte-for-byte
-- unchanged and remains the file the verifier is recomputing against.
--
-- Acronyms: Personal Volume (PV), Sales Volume (SV), Commissionable Volume (CV),
-- Coordinated Universal Time (UTC).
--
-- =============================================================================
-- THE THREE RULES HOWARD FIXED, AND WHERE EACH ONE LIVES
-- =============================================================================
-- RULE 1. SPREAD. A one-time purchase is recognised across ten months, one
--         slice per month. Already implemented as policy P4 in migration 019.
--
-- RULE 2. EVERYTHING RESOLVES WITHIN A CALENDAR MONTH. A run reads the slice
--         belonging to its own month and nothing else, forward or back.
--         ALREADY TRUE OF THE ENGINE, and worth naming the exact line that
--         guarantees it: in app.fn_run_commission the member_sv common table
--         expression joins orders with "and o.volume_month = v_period". One
--         equality. There is no range, no window, no carry-forward and no
--         accumulator anywhere in the engine. A run is self-contained by
--         construction, which is also what makes decision 4.5 work: a late
--         settlement into a finalized month refuses rather than shifting.
--         What this migration ADDS is the guard that keeps rule 2 true from the
--         other direction: nothing may be written INTO a month that has already
--         been run and finalized. See step 1.
--
-- RULE 3. COMMISSIONS RUN ONCE, AT END OF MONTH, FOR THE WHOLE MONTH. Not
--         continuously, not per order. This is operational rather than
--         structural: app.fn_run_commission and app.fn_finalize_run are called
--         by hand and there is no scheduler in the project. Recorded here as
--         fixed policy so the absence of a scheduler is a known gap rather than
--         an accident.
--
-- =============================================================================
-- WHERE THE SCHEDULE LIVES: IT IS app.orders, AND IT IS ALREADY MATERIALISED
-- =============================================================================
-- Spreading introduces something the engine has never seen: volume landing in a
-- FUTURE month with no new purchase behind it. That needs a schedule, an
-- obligation table saying what each future month owes.
--
-- That table already exists, and it is app.orders. Migration 019's bridge writes
-- TEN REAL ORDER ROWS for a one-time purchase, stamped to ten consecutive
-- volume months, each carrying one tenth of the price and one tenth of the PV,
-- all ten linked to the one sale by demo_order_id. Each month's run picks up the
-- row for its own month through the same volume_month equality it has always
-- used. The schedule is not a new storage concept, only a new interpretation of
-- an existing one: an order row dated to a future month IS the obligation.
--
-- MATERIALISED, NOT DERIVED, AND THAT IS THE POINT. The ten rows are written
-- once, at bridge time, and carry copied price and volume figures. If the
-- spreading rule ever changes from ten months to twelve, every row already
-- written keeps its original schedule, because the rule was resolved into data
-- at the moment of sale. This is the same principle app.order_lines has always
-- used in copying unit_price and unit_volume rather than pointing at the live
-- catalogue: a rule change must never reach backwards and rewrite what was
-- already promised.
--
-- A derived schedule, computed at each run from the original order and the
-- current spreading rule, would do exactly that: change the rule and every past
-- and future month silently owes something different. It was rejected for that
-- reason alone.
--
-- The view in step 2 is a LENS over those materialised rows, never a derivation
-- of the rule. It labels slice 3 of 10; it does not decide that there are ten.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. THE GUARD: nothing may be written into a finalized month
--
--    WHAT STOPS A SLICE LANDING IN A CLOSED MONTH, asked and answered.
--
--    Today the answer is "policy P3 inside one function", which is a rule that
--    holds only as long as every writer remembers it. A hand-typed insert, a
--    future code path, or a data fix would sail straight past it, and the next
--    time that month was re-run it would produce different numbers from the
--    statement members had already been shown.
--
--    This trigger makes it a property of the database, in the same spirit as the
--    finalized-run immutability triggers from migration 002 and 006. Those
--    protect the OUTPUT of a run. This protects its INPUT, which until now had
--    no protection at all.
--
--    Note the ordinary case is untouched: slices two through ten are written at
--    bridge time, months before those months are ever run, so they pre-exist
--    their run and this trigger never fires on them.
--
--    OPERATIONAL NOTE FOR A REBUILD: the seed loaders write orders BEFORE any
--    run exists, and db\comp\003_reset_app_data.sql truncates commission_runs,
--    so a fresh environment never trips this. It only ever fires on a genuine
--    attempt to change history.
-- -----------------------------------------------------------------------------
create or replace function app.reject_order_into_finalized_period()
returns trigger
language plpgsql
as $$
declare
    v_run_id bigint;
begin
    select r.id into v_run_id
    from app.commission_runs r
    where r.period = new.volume_month
      and r.status = 'final'
    limit 1;

    if v_run_id is not null then
        raise exception
            'order refused: volume month % was finalized by run %. A finalized '
            'month is a published statement and its inputs may not change. '
            'Report the order instead (design decision 4.5).',
            to_char(new.volume_month, 'YYYY-MM'), v_run_id;
    end if;

    return new;
end;
$$;

create trigger orders_no_write_into_finalized_period
    before insert or update of volume_month on app.orders
    for each row
    execute function app.reject_order_into_finalized_period();

comment on function app.reject_order_into_finalized_period() is
    'Keeps rule 2 true from the input side: a month that has been run and '
    'finalized can never gain new volume. Added by migration 021.';


-- -----------------------------------------------------------------------------
-- 2. app.v_volume_schedule: the obligation, made legible
--
--    A lens over the materialised order rows. Answers, for any one-time sale:
--    which months does it owe, how much, which slices have already been consumed
--    by a finalized run, and how much is still outstanding.
--
--    slice_index and slice_count are computed by window function over the rows
--    that already exist. That is labelling, not deriving: if the spreading rule
--    changed tomorrow, this view would still report the ten rows that were
--    actually written, because it reads rows rather than re-applying a rule.
--
--    Applies to attributed sales. The unattributed equivalent carries its own
--    slice_index and slice_count columns directly in app.house_retained_volume
--    (migration 020), because that is a new table and could store them outright.
-- -----------------------------------------------------------------------------
create or replace view app.v_volume_schedule as
select o.demo_order_id,
       d.order_number,
       m.member_code,
       ol.product_id,
       p.sku                                   as product_sku,
       ol.billing_mode,
       o.volume_month,
       row_number() over (partition by o.demo_order_id, ol.product_id, ol.billing_mode
                          order by o.volume_month)      as slice_index,
       count(*)     over (partition by o.demo_order_id, ol.product_id, ol.billing_mode)
                                                        as slice_count,
       (ol.quantity * ol.unit_volume)::numeric(12,2)    as slice_pv,
       (ol.quantity * ol.unit_price)::numeric(12,2)     as slice_price,
       (fr.run_id is not null)                          as consumed_by_final_run,
       fr.run_id                                        as final_run_id
from app.orders o
join app.order_lines ol on ol.order_id = o.id
join app.products    p  on p.id = ol.product_id
join app.demo_orders d  on d.id = o.demo_order_id
join app.members     m  on m.id = o.member_id
left join lateral (
    select r.id as run_id
    from app.commission_runs r
    where r.period = o.volume_month and r.status = 'final'
    limit 1
) fr on true
where o.demo_order_id is not null;

comment on view app.v_volume_schedule is
    'Every slice of every bridged live sale, with slice N of M, the month it '
    'belongs to, and whether a finalized run has already consumed it. A lens '
    'over materialised rows in app.orders, never a re-derivation of the '
    'spreading rule. Added by migration 021.';


-- =============================================================================
-- 3. THE FOUR REMAINING SCHEDULE QUESTIONS, ANSWERED HERE AND IN SECTION 11
--    OF THE DESIGN DOCUMENT. Recorded in the file so the code carries its own
--    reasoning.
-- =============================================================================
--
-- Q. DOES A LATER SLICE COUNT TOWARD THE BUYER'S OWN 100 PV QUALIFICATION?
-- A. YES, in full, and it costs nothing to allow.
--
--    The tempting objection is that one purchase would then keep somebody
--    qualified for ten months without buying again. Check the arithmetic before
--    accepting that as a loophole:
--
--      one-time domain agent   $1,000.00 once, 1,000 PV, spread = 100 PV/month
--                              for ten months
--      subscription            $100.00/month, 100 PV/month, for ten months
--                              = $1,000.00 and 100 PV/month
--
--    Identical money, identical monthly volume, identical qualification,
--    identical upline pay. Spreading makes the two purchase modes EXACTLY
--    equivalent, which is precisely why it is the right rule and precisely why
--    counting the slices creates no exploit. A one-time buyer is qualified for
--    ten months because they paid for ten months, the same way a subscriber is.
--
--    The alternative, counting a slice for upline pay but not for the buyer's
--    own qualification, would split Sales Volume into two different numbers and
--    destroy the plan's stated single-gate property, where one threshold decides
--    both "may be paid" and "counts as an active leg". That is a large change to
--    the plan to solve a problem the arithmetic shows does not exist.
--
--    NOTE THE CONTRAST, because it validates Howard's decision: under the
--    all-at-once option he rejected, $1,000.00 would have bought 1,000 PV in one
--    month, ten times the qualification threshold, and then nothing. THAT would
--    have been the loophole. Spreading removes it.
--
-- Q. WHAT IF THE MEMBER CLOSES THEIR ACCOUNT MID-SCHEDULE?
-- A. The schedule survives, and it should.
--
--    The money was received in full at the sale. Closing an account is not a
--    refund, and the product was already paid for. The remaining slices continue
--    to book volume, continue to count toward the closed member's own months,
--    and continue to pay their upline, because the upline's entitlement was
--    earned by a sale that actually happened.
--
--    HONEST CAVEAT: this touches an unresolved question the engine's own README
--    already raises, that closed accounts are still included in every run. That
--    question is not settled here. What IS settled is that account closure alone
--    must not cancel a paid-for schedule, because that would let the company
--    keep the money and stop recognising the volume.
--
-- Q. WHAT WOULD A FUTURE CLAWBACK HAVE TO DO TO THE REMAINING SLICES?
-- A. Two separable jobs, and only the first is cheap. It must (1) stop every
--    slice not yet consumed by a finalized run, which is a delete against
--    app.orders filtered on demo_order_id and an open volume_month, and (2)
--    decide separately what happens to slices ALREADY consumed by finalized
--    runs, where commission has been computed and published and this migration's
--    own trigger correctly forbids changing the input. Those are different
--    problems and conflating them is how a clawback feature goes wrong.
--    Refunds remain unbuilt and no rule for (2) exists. Design decision 4.3.
--
-- Q. WHY IS THERE NO SEPARATE SCHEDULE TABLE?
-- A. Because a second table holding the same obligation would be a second truth
--    to keep in step with app.orders forever, and this project already carries a
--    named risk about the same rules living in three places. One obligation,
--    one table, one view to read it.
-- =============================================================================
