-- =============================================================================
-- Migration 025: subscription engine Phase S1, the policy DATA
-- Project: MLM Pilot (Orvanna persona, personal project)
-- Date:    2026-08-16
-- Author:  mlm-db-engineer
-- Design:  MLM-PILOT\docs\SUBSCRIPTION-ENGINE-SPEC.md sections 6.2 (tables 5
--          and 6), 8 (the ladder, exactly), and ruling R5.
--
-- STATUS: AUTHORED AND PROVEN LOCALLY ONLY (see migration 024's status block;
--         the same rule governs this file). FROZEN once applied anywhere.
--
-- Acronym key: Non-Sufficient Funds (NSF), 3-D Secure (3DS, the card network
-- step that asks the shopper's bank to confirm identity), Merchant Initiated
-- Transaction (MIT), failure mode (FM).
--
-- -----------------------------------------------------------------------------
-- WHY THIS IS A SEPARATE MIGRATION
-- -----------------------------------------------------------------------------
-- The spec's rule: the decline classification table and the retry policies
-- are DATA, seeded rows, never code. This file is that data, and nothing
-- else. When a cadence or classification changes later, the change is a NEW
-- migration inserting new effective-dated rows (the 024 triggers refuse edits
-- and deletes outright), and every past run remains reconstructible against
-- the rows that were effective on its tick date.
--
-- The effective_from date for the initial seed is 2026-08-16, the day the
-- spec became law. Any tick on or after that date resolves these rows.
--
-- -----------------------------------------------------------------------------
-- THE GOVERNING PRINCIPLE, RESTATED FROM SPEC 6.2 TABLE 5
-- -----------------------------------------------------------------------------
-- Every class is labeled member-fault or system-fault. hard, soft, ambiguous,
-- ambiguous_contact, cancellation and auth are member-side facts about a card
-- or a cardholder. infra, config, duplicate and internal_config are OUR
-- faults. Only member-fault classes may ever consume the member's retry
-- ladder, dunning clock, or auto-cancel counter; system faults route to the
-- staff attention queue and are reported separately in run history, so our
-- own defects can never hide inside decline statistics.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. app.decline_classifications: spec 6.2 table 5, verbatim
--
--    Lookup precedence at classify time (pipeline step 9): connector code
--    first, orchestrator status second, refined reason third; anything
--    unrecognized resolves to the '__unrecognized__' row, class ambiguous,
--    printed loudly on the run report, because unknown never earns
--    aggressive retries.
-- -----------------------------------------------------------------------------
insert into app.decline_classifications
    (code, source, class, max_scheduled_retries, member_fault, needs_human, effective_from, note)
values
    -- hard declines: no retry will ever succeed; card_update_required.
    -- 2004 expired card is the card-update front door.
    ('2004', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'expired card, the card-update front door'),
    ('2005', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'invalid card number'),
    ('2006', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'invalid expiration date'),
    ('2007', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'no account'),
    ('2009', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'no such issuer'),
    ('2012', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'card account closed'),
    ('2013', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'card reported lost'),
    ('2014', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'card reported stolen'),
    ('2047', 'braintree', 'hard', 0, true,  false, date '2026-08-16', 'call issuer, pick up card'),

    -- the cardholder-spoke lane: the bank relayed a cancellation instruction.
    ('2017', 'braintree', 'cancellation',     0, true, false, date '2026-08-16', 'cardholder stopped billing: cancel THIS subscription (T4/T11/T15)'),
    ('2018', 'braintree', 'cancellation_all', 0, true, false, date '2026-08-16', 'cardholder stopped all billing: cancel EVERY subscription the member holds'),

    -- soft declines: the full five-step ladder (offsets in retry_policies).
    ('2001', 'braintree', 'soft', 5, true, false, date '2026-08-16', 'insufficient funds; the plus-15/plus-22 payday retries are the best NSF recovery moments'),
    ('2002', 'braintree', 'soft', 5, true, false, date '2026-08-16', 'limit exceeded'),
    ('2003', 'braintree', 'soft', 5, true, false, date '2026-08-16', 'cardholder activity limit exceeded'),

    -- infra: OUR side of the wire. One immediate retry first, not counted
    -- against the ladder; then the soft cadence. System fault: no member
    -- clock ever advances on these.
    ('3000',                  'braintree', 'infra', 5, false, false, date '2026-08-16', 'processor network unavailable; immediate uncounted retry then soft cadence'),
    ('processor_unreachable', 'internal',  'infra', 5, false, false, date '2026-08-16', 'same treatment as 3000'),

    -- ambiguous: the bank said no without saying why. Two backoff retries
    -- then dunning.
    ('2000', 'braintree', 'ambiguous', 2, true, false, date '2026-08-16', 'do not honor'),
    ('2038', 'braintree', 'ambiguous', 2, true, false, date '2026-08-16', 'processor declined, no reason given'),

    -- ambiguous_contact: the bank asked to talk to the cardholder. One retry
    -- then straight to dunning, because the fix is a phone call, not a ladder.
    ('2044', 'braintree', 'ambiguous_contact', 1, true, false, date '2026-08-16', 'issuer requests voice authorization'),
    ('2046', 'braintree', 'ambiguous_contact', 1, true, false, date '2026-08-16', 'contact issuing bank'),

    -- config: OUR merchant configuration is wrong; not a card fact. Flagged
    -- needs_human on the run report; never touches member clocks.
    ('2015', 'braintree', 'config', 0, false, true, date '2026-08-16', 'transaction not allowed: merchant configuration'),
    ('2019', 'braintree', 'config', 0, false, true, date '2026-08-16', 'invalid transaction for this merchant account'),
    ('2024', 'braintree', 'config', 0, false, true, date '2026-08-16', 'card type not enabled on this account'),

    -- duplicate: never retry, investigate. Retrying a duplicate warning is
    -- how double charges are born.
    ('2016', 'braintree', 'duplicate', 0, false, true, date '2026-08-16', 'duplicate transaction warning; investigate, never retry'),

    -- auth: ruling R5's invariant. A renewal is an MIT and never runs 3DS
    -- interactively; requires_customer_action on a renewal is failed,
    -- recoverable only through a fresh cardholder-present checkout.
    ('authentication_required', 'internal', 'auth', 0, true, false, date '2026-08-16', 'R5: MIT never authenticates interactively; exit is a fresh cardholder-present checkout (T16)'),

    -- internal_config: failure mode FM5, our own gateway refusing our own
    -- rebill (type mismatch and kin) or a failed pre-flight. SYSTEM FAULT,
    -- never the member's: never laddered, never counted against dunning or
    -- auto-cancel, routed to the staff attention queue, reported separately.
    ('gateway_type_mismatch', 'internal', 'internal_config', 0, false, true, date '2026-08-16', 'FM5: stored-credential anchor and card disagree; our defect, zero retries'),
    ('preflight_failed',      'internal', 'internal_config', 0, false, true, date '2026-08-16', 'FM5: credential incoherent at pre-flight; never reached the processor'),

    -- the catch-all: unknown never earns aggressive retries, and the run
    -- report prints the unrecognized code loudly.
    ('__unrecognized__', 'internal', 'ambiguous', 2, true, false, date '2026-08-16', 'any code this table does not name; printed loudly on the run report');


-- -----------------------------------------------------------------------------
-- 2. app.retry_policies: spec section 8.1, the ladder exactly (ruling R5)
--
--    Offsets are days from the BILLING ATTEMPT date D, all clipped by rule
--    C1 at dispatch time (same calendar month as D, day of month at most 26).
--    is_escalation_step marks the step whose FAILURE enters dunning
--    (spec 8.2): soft step 3 (the plus-8 retry, the brief's day-8 notice
--    point), ambiguous step 2, ambiguous_contact step 1. The plus-15 and
--    plus-22 soft retries still run while in dunning: the payday retry is
--    the single best recovery moment for Non-Sufficient Funds.
--
--    infra: step 0 is the immediate same-tick retry, consuming no ladder
--    step; steps 1 through 5 then mirror the soft cadence.
-- -----------------------------------------------------------------------------
insert into app.retry_policies
    (class, step, offset_days, is_escalation_step, effective_from, note)
values
    ('soft', 1,  2, false, date '2026-08-16', 'plus 2 days from the billing attempt'),
    ('soft', 2,  4, false, date '2026-08-16', 'plus 4'),
    ('soft', 3,  8, true,  date '2026-08-16', 'plus 8: dunning entered when THIS retry fails (spec 8.2)'),
    ('soft', 4, 15, false, date '2026-08-16', 'plus 15: runs while in dunning; the payday window'),
    ('soft', 5, 22, false, date '2026-08-16', 'plus 22: runs while in dunning'),

    ('ambiguous', 1, 2, false, date '2026-08-16', 'first backoff'),
    ('ambiguous', 2, 4, true,  date '2026-08-16', 'second backoff: dunning when this fails'),

    ('ambiguous_contact', 1, 2, true, date '2026-08-16', 'one retry, then dunning: the fix is a conversation'),

    ('infra', 0,  0, false, date '2026-08-16', 'immediate same-tick retry; consumes no ladder step (R5)'),
    ('infra', 1,  2, false, date '2026-08-16', 'then the soft cadence'),
    ('infra', 2,  4, false, date '2026-08-16', 'soft cadence'),
    ('infra', 3,  8, false, date '2026-08-16', 'soft cadence; NO escalation step: infra is system fault and never enters the member''s dunning'),
    ('infra', 4, 15, false, date '2026-08-16', 'soft cadence'),
    ('infra', 5, 22, false, date '2026-08-16', 'soft cadence');


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- 1. Row counts: select class, count(*) from app.decline_classifications
--    group by class order by class;
--    Expect: ambiguous 3 (2000, 2038, __unrecognized__), ambiguous_contact 2,
--    auth 1, cancellation 1, cancellation_all 1, config 3, duplicate 1,
--    hard 9, infra 2, internal_config 2, soft 3. Total 28.
-- 2. Every member-fault class is exactly {hard, soft, ambiguous,
--    ambiguous_contact, cancellation, cancellation_all, auth}:
--      select distinct class from app.decline_classifications
--       where member_fault order by class;
-- 3. Ladder shape: select class, count(*), max(step)
--      from app.retry_policies group by class;
--    Expect soft 5/5, ambiguous 2/2, ambiguous_contact 1/1, infra 6/5.
-- 4. Exactly one escalation step per member-fault laddered class:
--      select class, count(*) filter (where is_escalation_step)
--      from app.retry_policies group by class;
--    Expect soft 1, ambiguous 1, ambiguous_contact 1, infra 0.
-- 5. The append-only triggers hold: any UPDATE or DELETE against either
--    table must raise.
-- =============================================================================
