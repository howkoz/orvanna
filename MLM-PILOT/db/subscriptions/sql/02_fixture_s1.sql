-- =============================================================================
-- S1 proof fixture, part 2: the simulated year's cast. Applied AFTER
-- migrations 024..027 (the engine exists; the clock, scripts and credentials
-- tables exist).
--
-- Deterministic by construction: the scripts table IS the randomness, and it
-- is data. Acronym key: Personal Volume (PV), failure mode (FM), Customer
-- Initiated Transaction (CIT).
-- =============================================================================

-- The clock: epoch 2026-08-31, first tick 2026-09-01. Nothing anchored at or
-- before the epoch is ever gathered (deviation D7).
select app.fn_sim_clock_init(date '2026-08-31');

-- ---------------------------------------------------------------------------
-- Subscriptions. billing_day null = the anchor-day rule. All anchors are day
-- 1 except FRED (the FM4 day-31 defensive case, inserted directly the way a
-- legacy row would carry it) and the batch (day 15).
-- ---------------------------------------------------------------------------
insert into app.subscriptions
    (member_id, product_id, quantity, start_month, billing_anchor_date,
     frequency_months, billing_day, state)
values
    -- BETH: the qualified upline; monthly, succeeds all year.
    ((select id from app.members where member_code = 'GW-9000'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- ANN A (worked example A): soft decline recovered by the plus-8 retry.
    ((select id from app.members where member_code = 'GW-9001'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- ANN B (worked example B): retries exhaust; suspension; auto-cancel.
    ((select id from app.members where member_code = 'GW-9002'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- CARL (worked example C): quarterly, anchored 2026-10-01.
    ((select id from app.members where member_code = 'GW-9003'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-10-01', date '2026-10-01', 3, null, 'active'),
    -- DANA (FM5): monthly; her credential is deliberately corrupted below.
    ((select id from app.members where member_code = 'GW-9004'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- FRED (FM4): anchored on the 31st, crossing February.
    ((select id from app.members where member_code = 'GW-9005'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-10-01', date '2026-10-31', 1, null, 'active'),
    -- HANK (FM3): monthly on the product whose price changes mid-simulation.
    ((select id from app.members where member_code = 'GW-9006'),
     (select id from app.products where sku = 'AGT-D-002'),
     1, date '2026-12-01', date '2026-12-01', 1, null, 'active');

-- The FM2 crash batch: sixty monthly subscriptions anchored 2026-11-15.
insert into app.subscriptions
    (member_id, product_id, quantity, start_month, billing_anchor_date,
     frequency_months, billing_day, state)
select m.id,
       (select id from app.products where sku = 'AGT-D-001'),
       1, date '2026-11-01', date '2026-11-15', 1, null, 'active'
from app.members m
where m.member_code like 'GW-92%'
order by m.member_code;

-- ---------------------------------------------------------------------------
-- Credentials (FM5). BETH holds a COHERENT credential (pre-flight passes and
-- is proven harmless); DANA holds the deliberately corrupted one: brand visa,
-- network anchor minted by a mastercard. The pre-flight must stop her rebill
-- before any processor is asked, classify internal_config, retry zero times,
-- and leave her dunning and auto-cancel clocks untouched.
-- ---------------------------------------------------------------------------
insert into app.payment_credentials
    (member_id, brand, last4, expiry_month, expiry_year, token_reference,
     network_anchor, created_on)
values
    ((select id from app.members where member_code = 'GW-9000'),
     'visa', '4242', 12, 2030, 'sim-token-beth', 'sim:visa:1', date '2026-08-01'),
    ((select id from app.members where member_code = 'GW-9004'),
     'visa', '9999', 12, 2030, 'sim-token-dana', 'sim:mastercard:999', date '2026-08-01');

update app.subscriptions s
   set credential_id = c.id
  from app.payment_credentials c
 where c.member_id = s.member_id
   and s.member_id in (select id from app.members
                        where member_code in ('GW-9000', 'GW-9004'));

-- ---------------------------------------------------------------------------
-- The outcome scripts: the whole simulated year's adversity, as data.
-- No row means succeeded (the implicit happy path).
-- ---------------------------------------------------------------------------

-- Worked example A (ANN A, September, renewal 1): attempts 1, 2, 3 decline
-- soft 2001; attempt 4 (the plus-8 retry, Sep 9) has no row and succeeds.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, v.attempt_no, 'declined', '2001',
       'worked example A: soft decline, recovered by the plus-8 retry'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9001'
cross join (values (1), (2), (3)) as v(attempt_no);

-- Worked example B (ANN B, September, renewal 1): all six attempts decline
-- 2001 (initial plus the full five-step ladder).
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, v.attempt_no, 'declined', '2001',
       'worked example B: retries exhaust; day-26 suspension; auto-cancel Nov 1'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9002'
cross join (values (1), (2), (3), (4), (5), (6)) as v(attempt_no);

-- FM2 orphan (batch member 47, renewal 1, attempt 1): the processor NEVER
-- receives the dispatch. The reconciler must find it, surface it, consume
-- the strand, and re-dispatch idempotently.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'not_received', null,
       'FM2: the deliberate orphan inside the crash batch'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9247';
