-- Migration 005: public demo views (the site's entire read surface)
-- Purpose: the five v_demo_* views of SCHEMA-SPEC.md section 3. Views are
--          definer views (security_invoker = false) owned by app_demo_reader,
--          which can read the app tables (migration 003). The anon role gets
--          SELECT on the views ONLY. Every view filters to commission runs
--          with status 'final'. No view exposes email or internal member ids:
--          member_code and display_name are the only member identifiers.
--          Views live in schema public so the Supabase data API can serve
--          them without exposing schema app.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)

-- ---------------------------------------------------------------------------
-- v_demo_members: member_code, display_name, enrolled_on, rank_name
-- rank_name is the member's rank from the LATEST final run (null when the
-- member has no row there, for example enrolled after that run's period).
-- ---------------------------------------------------------------------------
create view public.v_demo_members
with (security_invoker = false)
as
with latest_final_run as (
    select r.id
    from app.commission_runs r
    where r.status = 'final'
    order by r.period desc, r.id desc
    limit 1
)
select
    m.member_code,
    m.display_name,
    m.enrolled_on,
    rk.rank_name
from app.members m
left join app.run_member_results rmr
       on rmr.member_id = m.id
      and rmr.run_id = (select id from latest_final_run)
left join app.ranks rk
       on rk.rank_code = rmr.rank_earned;

-- ---------------------------------------------------------------------------
-- v_demo_tree: child member_code, sponsor member_code (edges only,
-- public-safe codes). The root appears with sponsor_code null so the site
-- can anchor the tree.
-- ---------------------------------------------------------------------------
create view public.v_demo_tree
with (security_invoker = false)
as
select
    c.member_code,
    s.member_code as sponsor_code
from app.members c
left join app.members s
       on s.id = c.sponsor_id;

-- ---------------------------------------------------------------------------
-- v_demo_member_months: member_code, period, sv, cv, tv, is_active,
-- rank_earned, from final runs only.
-- ---------------------------------------------------------------------------
create view public.v_demo_member_months
with (security_invoker = false)
as
select
    m.member_code,
    r.period,
    rmr.sv,
    rmr.cv,
    rmr.tv,
    rmr.is_active,
    rmr.rank_earned
from app.run_member_results rmr
join app.commission_runs r
  on r.id = rmr.run_id
 and r.status = 'final'
join app.members m
  on m.id = rmr.member_id;

-- ---------------------------------------------------------------------------
-- v_demo_statements: period, earner member_code, level, source member_code,
-- source_cv, rate, amount, from final runs only.
-- ---------------------------------------------------------------------------
create view public.v_demo_statements
with (security_invoker = false)
as
select
    r.period,
    e.member_code as earner_code,
    cl.level,
    s.member_code as source_code,
    cl.source_cv,
    cl.rate,
    cl.amount
from app.commission_lines cl
join app.commission_runs r
  on r.id = cl.run_id
 and r.status = 'final'
join app.members e
  on e.id = cl.earner_id
join app.members s
  on s.id = cl.source_member_id;

-- ---------------------------------------------------------------------------
-- v_demo_company: per final run: period, totals, members_paid, rank
-- distribution counts. run_id is included because the site footer's
-- data-basis line reads period plus run id from this view (schema spec
-- section 3); it is a run identifier, not a member identifier.
-- ---------------------------------------------------------------------------
create view public.v_demo_company
with (security_invoker = false)
as
select
    r.id as run_id,
    r.period,
    r.total_sv,
    r.total_cv,
    r.total_payout,
    r.members_paid,
    count(*) filter (where rmr.rank_earned = 'member')    as rank_member_count,
    count(*) filter (where rmr.rank_earned = 'builder')   as rank_builder_count,
    count(*) filter (where rmr.rank_earned = 'leader')    as rank_leader_count,
    count(*) filter (where rmr.rank_earned = 'director')  as rank_director_count,
    count(*) filter (where rmr.rank_earned = 'executive') as rank_executive_count
from app.commission_runs r
left join app.run_member_results rmr
       on rmr.run_id = r.id
where r.status = 'final'
group by r.id, r.period, r.total_sv, r.total_cv, r.total_payout, r.members_paid;

-- ---------------------------------------------------------------------------
-- Ownership and grants: views owned by the read-only definer role; the
-- public API roles may read the views and nothing else. Grants are guarded
-- so the migration also runs on plain Postgres without Supabase roles.
-- ---------------------------------------------------------------------------
alter view public.v_demo_members       owner to app_demo_reader;
alter view public.v_demo_tree          owner to app_demo_reader;
alter view public.v_demo_member_months owner to app_demo_reader;
alter view public.v_demo_statements    owner to app_demo_reader;
alter view public.v_demo_company       owner to app_demo_reader;

do $$
begin
    if exists (select 1 from pg_roles where rolname = 'anon') then
        grant select on public.v_demo_members,
                        public.v_demo_tree,
                        public.v_demo_member_months,
                        public.v_demo_statements,
                        public.v_demo_company
        to anon;
    end if;
    if exists (select 1 from pg_roles where rolname = 'authenticated') then
        grant select on public.v_demo_members,
                        public.v_demo_tree,
                        public.v_demo_member_months,
                        public.v_demo_statements,
                        public.v_demo_company
        to authenticated;
    end if;
end
$$;
