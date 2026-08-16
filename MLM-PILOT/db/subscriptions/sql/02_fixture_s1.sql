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

-- The fix-round cast (gate verdicts of 2026-08-16). Frequencies 2 and 6
-- (QA M2), and one subscription per member action (QA M3, verifier H1
-- scenarios). The actions themselves are invoked between ticks by the
-- driver segments; the scripts below supply the scripted adversity.
insert into app.subscriptions
    (member_id, product_id, quantity, start_month, billing_anchor_date,
     frequency_months, billing_day, state)
values
    -- OSCAR: bi-monthly, bills 200.00 every two months from Sep 1.
    ((select id from app.members where member_code = 'GW-9007'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 2, null, 'active'),
    -- SARA: semi-annual, bills 600.00 on Oct 1 and Apr 1.
    ((select id from app.members where member_code = 'GW-9008'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-10-01', date '2026-10-01', 6, null, 'active'),
    -- NORA: quarterly until the sanctioned frequency change (Nov 10).
    ((select id from app.members where member_code = 'GW-9009'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-10-01', date '2026-10-01', 3, null, 'active'),
    -- PAULA: monthly, billing day 5; changes to day 25 on 2027-03-08.
    ((select id from app.members where member_code = 'GW-9010'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-05', 1, 5, 'active'),
    -- PETE, QUINN, RITA, TINA, UMA, XENA, YVES: monthly, day 1, Sep 1.
    ((select id from app.members where member_code = 'GW-9011'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    ((select id from app.members where member_code = 'GW-9012'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    ((select id from app.members where member_code = 'GW-9013'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- SAM: monthly, day 1, anchored Oct 1 (pauses Oct 5, resumes early Nov 10).
    ((select id from app.members where member_code = 'GW-9014'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-10-01', date '2026-10-01', 1, null, 'active'),
    ((select id from app.members where member_code = 'GW-9015'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    ((select id from app.members where member_code = 'GW-9016'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- VIC holds TWO subscriptions; the 2018 decline on the FIRST must cancel
    -- both. Insert order fixes the id order the dispatch loop walks.
    ((select id from app.members where member_code = 'GW-9017'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    ((select id from app.members where member_code = 'GW-9017'),
     (select id from app.products where sku = 'AGT-S-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- WALT: the spec 8.3 named case, member-picked day 28: the ladder
    -- truncates to zero and the checkpoint is month end.
    ((select id from app.members where member_code = 'GW-9018'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-28', 1, 28, 'active'),
    ((select id from app.members where member_code = 'GW-9019'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    ((select id from app.members where member_code = 'GW-9020'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active'),
    -- ZOE: corrupted credential like DANA, but she CANCELS on Oct 15: her
    -- open periods carry NO member-fault decline, so cancellation resolves
    -- them 'void_cancelled', the ledger's word for cancelled-not-unpaid
    -- (fix round F5, verifier L1).
    ((select id from app.members where member_code = 'GW-9021'),
     (select id from app.products where sku = 'AGT-D-001'),
     1, date '2026-09-01', date '2026-09-01', 1, null, 'active');

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
     'visa', '9999', 12, 2030, 'sim-token-dana', 'sim:mastercard:999', date '2026-08-01'),
    ((select id from app.members where member_code = 'GW-9021'),
     'visa', '8888', 12, 2030, 'sim-token-zoe', 'sim:amex:888', date '2026-08-01');

update app.subscriptions s
   set credential_id = c.id
  from app.payment_credentials c
 where c.member_id = s.member_id
   and s.member_id = (select id from app.members where member_code = 'GW-9021');

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

-- ---------------------------------------------------------------------------
-- Fix-round scripts: the member-action year's adversity (QA M3).
-- ---------------------------------------------------------------------------

-- PETE: soft declines Sep 1 and Sep 3; the member pauses on Sep 4 with a
-- retry EXECUTED and another scheduled: the exact H1 crash shape.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, v.a, 'declined', '2001', 'H1 case: pause after an executed retry'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9011'
cross join (values (1), (2)) as v(a);

-- QUINN: the full escalation into dunning (attempts 1..4 fail; dunning when
-- the plus-8 fails on Sep 9), then pause-at-dunning on Sep 12 (T10a). Her
-- November cycle (index 3, after the October skipped_paused month) fails its
-- WHOLE ladder too: the frozen clock makes September plus November two
-- consecutive counted months and auto-cancel fires December 1, which is the
-- spec v1.1 12.3 micro-example, shifted onto real dates.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, v.a, 'declined', '2001', 'T10a setup: escalate into dunning'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9012'
cross join (values (1), (2), (3), (4)) as v(a);

insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 3, v.a, 'declined', '2001', 'T10a freeze proof: the resumed month fails fully'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9012'
cross join (values (1), (2), (3), (4), (5), (6)) as v(a);

-- TINA: same escalation into dunning; she CANCELS on Sep 12 (T15).
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, v.a, 'declined', '2001', 'T15 setup: cancel during dunning'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9015'
cross join (values (1), (2), (3), (4)) as v(a);

-- UMA: decline 2017, the cardholder-spoke lane: THIS subscription cancels.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'declined', '2017', 'T4: cardholder stopped this billing'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9016';

-- VIC: decline 2018 on his FIRST subscription: EVERY subscription he holds
-- cancels, and his second subscription must never bill at all.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'declined', '2018', 'cancellation_all: every subscription the member holds'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9017'
join app.products p on p.id = s.product_id and p.sku = 'AGT-D-001';

-- WALT: one soft decline on his day-28 billing. The ladder truncates to
-- ZERO surviving retries (spec 8.3's named case), dunning entered the same
-- day, suspension at the month-end checkpoint.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'declined', '2001', 'day-28: the zero-survivor ladder'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9018';

-- XENA: hard decline 2004 (expired card, the card-update front door).
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'declined', '2004', 'T3 then T16: reactivation from card_update_required'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9019';

-- YVES: hard decline 2005, no member action ever: T17 at the checkpoint,
-- then the R4 auto-cancel.
insert into app.sim_outcome_scripts
    (subscription_id, renewal_index, attempt_no, outcome, decline_code, note)
select s.id, 1, 1, 'declined', '2005', 'T17 then T22: suspension without a card update'
from app.subscriptions s
join app.members m on m.id = s.member_id and m.member_code = 'GW-9020';
