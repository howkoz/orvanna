-- Migration 014: real member sign-in for the shop checkout.
-- Date: 2026-08-15
-- Applied to the cloud project on 2026-08-15.
--
-- WHY. The checkout's "Sign in" accepted ANY username and ANY password and
-- then filled in a hard-coded person who does not exist in the roster. Howard,
-- 2026-08-15: "i want to move to next phase and it not be theater." So the
-- credential check moves into the database, exactly like migration 012 did for
-- the portal and the staff console, and the account a shopper signs in to is a
-- REAL row in app.members.
--
-- DESIGN. The username IS the member code. That is not a shortcut: it means
-- the existing demo-login function validates the credential server side with
-- no change at all, and the username it returns is already the value
-- create-payment needs to attribute the order to a member.
--
-- THE PASSWORD IS DELIBERATELY PUBLIC, and this is the one place in the
-- project where that is true. Migration 012 withheld the admin and staff
-- passwords on purpose. This one is the opposite: a visitor to a public
-- demonstration has to be able to sign in, so the credential is printed on the
-- checkout page itself. It guards nothing. The roster it opens is already
-- readable through the public v_demo_members view by design, and a member
-- account cannot open the member portal or the staff console because the
-- server-side role gate refuses it (verified 2026-08-15: role 'member'
-- against role 'staff' returns wrong_role).

-- 1. Allow the new role.
alter table app.demo_users drop constraint demo_users_role_check;
alter table app.demo_users add constraint demo_users_role_check
  check (role in ('admin', 'staff', 'member'));

-- 2. Which member the account belongs to. Null for admin and staff, which are
--    not members of anything.
alter table app.demo_users add column if not exists member_code text;

-- 3. One account per member, all sharing one bcrypt hash. The hash is computed
--    ONCE by the scalar subquery and reused, because hashing a thousand rows
--    individually at cost 10 would take about a minute for no benefit: they
--    all carry the same password anyway.
insert into app.demo_users (username, password_hash, role, label, member_code)
select m.member_code,
       (select extensions.crypt('OrvannaDemo2026', extensions.gen_salt('bf', 10))),
       'member',
       'Member demonstration account',
       m.member_code
  from app.members m
 where not exists (
         select 1 from app.demo_users u where lower(u.username) = lower(m.member_code)
       );

-- 4. Posture unchanged and re-asserted: the table stays sealed. Row-Level
--    Security on with zero policies, no privileges for the public roles, so
--    only a server-side connection inside an Edge Function can read it.
revoke all on app.demo_users from anon, authenticated;
