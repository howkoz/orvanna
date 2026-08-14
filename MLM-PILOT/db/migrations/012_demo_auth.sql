-- Migration 012: demonstration sign-in, validated server side
-- Purpose: move the site's sign-in OFF the page and INTO the database.
--          Before this migration login.html accepted anything and the
--          staff console had no gate at all. After it, credentials live
--          here as bcrypt hashes, an Edge Function checks them, and the
--          browser never holds or compares a password.
--
--          Two tables, both sealed exactly like the Phase 6 tables:
--          Row-Level Security (RLS) enabled with ZERO policies, and all
--          privileges revoked from anon and authenticated. Only the
--          service-role connection inside an Edge Function reads them.
--
--          app.demo_users        the sign-in accounts and their roles
--          app.demo_auth_config  the token signing key (server only)
--
--          HONEST SCOPE NOTE, recorded so nobody mistakes this for more
--          than it is: the site is static hosting, so any page's markup
--          can still be fetched directly, and the seven public v_demo_*
--          views remain readable with the public anon key by design
--          (that is what makes the portal a demonstration). This
--          migration makes the CREDENTIAL CHECK real and server side.
--          Making the GATE absolute would additionally require routing
--          portal and console data through an authenticated function.
--          Tracked as the Sunday follow-up.
-- Date: 2026-08-14
-- Project: MLM Pilot (Orvanna, personal project)

-- ---------------------------------------------------------------------------
-- Accounts. password_hash is a bcrypt hash produced by pgcrypto's crypt();
-- the plain password is never stored, and verification happens by hashing
-- the attempt with the stored salt and comparing, inside the database.
-- ---------------------------------------------------------------------------
create table app.demo_users (
    id            bigint generated always as identity primary key,
    username      text not null,
    password_hash text not null,
    role          text not null check (role in ('admin', 'staff')),
    label         text,
    created_at    timestamptz not null default now(),
    constraint demo_users_username_key unique (username)
);

-- Case-insensitive lookup: the sign-in accepts Orvanna_Admin in any casing.
create unique index demo_users_username_lower_key on app.demo_users (lower(username));

-- ---------------------------------------------------------------------------
-- Server-only configuration: the key that signs session tokens. Generated
-- here with cryptographically strong random bytes, so no human ever types
-- it and it appears in no repository, no page, and no chat window.
-- ---------------------------------------------------------------------------
create table app.demo_auth_config (
    key        text primary key,
    value      text not null,
    updated_at timestamptz not null default now()
);

insert into app.demo_auth_config (key, value)
values ('token_signing_key', encode(extensions.gen_random_bytes(32), 'hex'));

-- ---------------------------------------------------------------------------
-- The two demonstration accounts, hashed with bcrypt (blowfish salt).
-- Roles: admin opens the member portal, staff opens the call console.
-- ---------------------------------------------------------------------------
insert into app.demo_users (username, password_hash, role, label) values
  ('Orvanna_Admin', extensions.crypt('Orvanna2026', extensions.gen_salt('bf', 10)), 'admin', 'Member portal demonstration account'),
  ('Orvanna_Staff', extensions.crypt('2026Orvanna', extensions.gen_salt('bf', 10)), 'staff', 'Staff call console demonstration account');

-- ---------------------------------------------------------------------------
-- Posture: RLS on, zero policies, and every privilege stripped from the two
-- public roles. Same belt-and-suspenders pattern as migrations 003, 007, 010.
-- ---------------------------------------------------------------------------
alter table app.demo_users       enable row level security;
alter table app.demo_auth_config enable row level security;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        revoke all on app.demo_users       from anon;
        revoke all on app.demo_auth_config from anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        revoke all on app.demo_users       from authenticated;
        revoke all on app.demo_auth_config from authenticated;
    end if;
end
$$;
