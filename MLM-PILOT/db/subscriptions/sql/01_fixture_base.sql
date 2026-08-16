-- =============================================================================
-- S1 proof fixture, part 1: catalog products, proof members, legacy rows.
-- Applied AFTER migrations 001..013 and BEFORE 015..022 (migration 019's
-- shop_sku_map insert joins these product rows, exactly as production had
-- them seeded before 019 applied) and BEFORE 024 (the legacy subscriptions
-- exist first so 024's backfill runs over real rows, proving the evolution).
--
-- Everything synthetic, persona-safe, deterministic. Acronym key: Personal
-- Volume (PV), Stock Keeping Unit (SKU).
-- =============================================================================

-- The twelve seeded catalog products (values verbatim from the catalog:
-- domain agents 100.00 / 100 PV, support agents 50.00 / 50 PV).
insert into app.products (sku, name, tier, price, volume_points, commissionable_value)
values
    ('AGT-D-001', 'Payment Agent',    'domain',  100.00, 100.00, null),
    ('AGT-D-002', 'Shipping Agent',   'domain',  100.00, 100.00, null),
    ('AGT-D-003', 'Pricing Agent',    'domain',  100.00, 100.00, null),
    ('AGT-D-004', 'Inventory Agent',  'domain',  100.00, 100.00, null),
    ('AGT-D-005', 'Marketing Agent',  'domain',  100.00, 100.00, null),
    ('AGT-D-006', 'Tax Agent',        'domain',  100.00, 100.00, null),
    ('AGT-S-001', 'Engineer Agent',   'support',  50.00,  50.00, null),
    ('AGT-S-002', 'QA Agent',         'support',  50.00,  50.00, null),
    ('AGT-S-003', 'Secretary Agent',  'support',  50.00,  50.00, null),
    ('AGT-S-004', 'Executive Agent',  'support',  50.00,  50.00, null),
    ('AGT-S-005', 'Accounting Agent', 'support',  50.00,  50.00, null),
    ('AGT-S-006', 'Care Agent',       'support',  50.00,  50.00, null)
on conflict (sku) do nothing;

-- Proof members. BETH is the upline of every scripted member, so the worked
-- examples' commission lines (earner BETH, level 1) are directly assertable.
insert into app.members (member_code, display_name, email, sponsor_id, enrolled_on)
values ('GW-9000', 'Beth Proof', 'beth.proof@example.com', null, date '2026-01-01');

insert into app.members (member_code, display_name, email, sponsor_id, enrolled_on)
select v.code, v.name, v.email, (select id from app.members where member_code = 'GW-9000'), date '2026-02-01'
from (values
    ('GW-9001', 'Ann A Proof',  'ann.a@example.com'),    -- worked example A
    ('GW-9002', 'Ann B Proof',  'ann.b@example.com'),    -- worked example B
    ('GW-9003', 'Carl Proof',   'carl@example.com'),     -- worked example C (quarterly)
    ('GW-9004', 'Dana Proof',   'dana@example.com'),     -- FM5 corrupted credential
    ('GW-9005', 'Fred Proof',   'fred@example.com'),     -- FM4 day-31 anchor
    ('GW-9006', 'Hank Proof',   'hank@example.com'),     -- FM3 price change
    ('GW-9101', 'Legacy One',   'legacy.one@example.com'),
    ('GW-9102', 'Legacy Two',   'legacy.two@example.com'),
    ('GW-9103', 'Legacy Three', 'legacy.three@example.com')
) as v(code, name, email);

-- The FM2 crash batch: sixty members, sixty monthly subscriptions all due
-- the same day (2026-11-15), so the crash-after-47 scenario has its 60.
insert into app.members (member_code, display_name, email, sponsor_id, enrolled_on)
select 'GW-92' || lpad(n::text, 2, '0'),
       'Batch Member ' || n,
       'batch.' || n || '@example.com',
       (select id from app.members where member_code = 'GW-9000'),
       date '2026-03-01'
from generate_series(1, 60) as n;

-- Legacy subscriptions, inserted BEFORE migration 024 in the old shape only
-- (member, product, quantity, start_month, cancel_month), exactly what the
-- 1,820 production seed rows look like. 024's backfill must turn these into
-- monthly / anchored-at-start-month / active-or-cancelled without changing
-- their meaning; the proof battery asserts it, plus the engine-epoch rule
-- (deviation D7): their first ENGINE cycle is September 2026, never a
-- two-year catch-up.
insert into app.subscriptions (member_id, product_id, quantity, start_month, cancel_month)
values
    ((select id from app.members where member_code = 'GW-9101'),
     (select id from app.products where sku = 'AGT-D-003'), 1, date '2025-01-01', null),
    ((select id from app.members where member_code = 'GW-9102'),
     (select id from app.products where sku = 'AGT-S-001'), 1, date '2025-01-01', null),
    ((select id from app.members where member_code = 'GW-9103'),
     (select id from app.products where sku = 'AGT-D-004'), 1, date '2025-01-01', date '2026-03-01');
