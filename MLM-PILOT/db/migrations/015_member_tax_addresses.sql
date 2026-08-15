-- Migration 015: real tax jurisdictions for the three demonstration accounts.
-- Date: 2026-08-15
-- Project: MLM Pilot (Orvanna, personal project)
--
-- RECOVERED FILE, BODY COPIED VERBATIM. This migration was applied to the cloud
-- project through the management interface on 2026-08-15 (ledger version
-- 20260815182513) and no file was written at the time. The statements below are
-- copied verbatim from supabase_migrations.schema_migrations, so this file and
-- production agree exactly. Recovered 2026-08-15 during migration recovery.
-- Nothing was applied to production by the recovery.
--
-- RE-RUN SAFETY: already safe as written. Every column add carries
-- 'if not exists', the coalesce update only fills nulls, and the three address
-- updates set the same constant values every time, so a second run is a no-op
-- in effect. No guard needed to be added.
--
-- WHY. Tax is about to be calculated by a real engine (Stripe Tax) instead of
-- the flat five percent the pricing mirror applies today. A real engine
-- calculates from a DESTINATION, so the demo needs real destinations. Howard,
-- 2026-08-15: "we need to at least use correct zip codes... a California zip
-- which is high tax, florida zip like mine 33483... and New York Tax so we
-- will have three test accounts with real zip codes."
--
-- THE PRIVACY LINE, held deliberately. The CITY, STATE and POSTAL CODE are
-- real, because those are the only parts a tax engine actually reasons about
-- and inventing them would produce invented tax. The STREET is obviously
-- synthetic on every row, because this project collects no real addresses from
-- anyone and should not appear to. A postal code is not personal data; a
-- street address is.
--
-- WHERE THE ADDRESS LIVES, and why it is not in the browser. The tax
-- destination is read SERVER SIDE from the signed-in member's row. It is never
-- sent up from the page. If the browser could supply the tax address it could
-- choose its own tax rate, which is the same class of mistake as letting the
-- browser supply a price.

alter table app.members add column if not exists demo_address_line1  text;
alter table app.members add column if not exists demo_address_city   text;
alter table app.members add column if not exists demo_address_state  text;
alter table app.members add column if not exists demo_address_zip    text;
alter table app.members add column if not exists demo_address_country text;

-- Everyone starts at the house default, so a guest or any unlisted member
-- still has a valid destination and tax never silently becomes zero.
update app.members
   set demo_address_line1  = coalesce(demo_address_line1, '1 Demonstration Way'),
       demo_address_city   = coalesce(demo_address_city, 'Springfield'),
       demo_address_state  = coalesce(demo_address_state, 'IL'),
       demo_address_zip    = coalesce(demo_address_zip, '62701'),
       demo_address_country = coalesce(demo_address_country, 'US');

-- The three teaching accounts. One per state, chosen because the three treat
-- software as a service DIFFERENTLY, which is the point worth demonstrating:
-- the intuition that a high headline sales-tax state means a high bill does
-- not hold for digital services. Whatever Stripe Tax actually returns is the
-- authority here; these rows only decide WHERE the sale lands.
update app.members set
    demo_address_line1 = '1 Demonstration Way',
    demo_address_city  = 'Los Angeles',
    demo_address_state = 'CA',
    demo_address_zip   = '90012',
    demo_address_country = 'US'
  where member_code = 'GW-000001';

update app.members set
    demo_address_line1 = '1 Demonstration Way',
    demo_address_city  = 'Delray Beach',
    demo_address_state = 'FL',
    demo_address_zip   = '33483',
    demo_address_country = 'US'
  where member_code = 'GW-000002';

update app.members set
    demo_address_line1 = '1 Demonstration Way',
    demo_address_city  = 'New York',
    demo_address_state = 'NY',
    demo_address_zip   = '10001',
    demo_address_country = 'US'
  where member_code = 'GW-000003';
