-- Migration 004: ranks seed rows
-- Purpose: seed the five ranks of COMP-PLAN-SPEC.md v1.1 section 4 with their
--          paid depths. Qualification RULES stay in the spec and the comp
--          engine; this table only names ranks and depths.
-- Date: 2026-08-13
-- Project: MLM Pilot (Globex persona, personal project)

insert into app.ranks (rank_code, rank_name, sort_order, paid_depth) values
    ('member',    'Member',    1, 1),
    ('builder',   'Builder',   2, 2),
    ('leader',    'Leader',    3, 3),
    ('director',  'Director',  4, 4),
    ('executive', 'Executive', 5, 5)
on conflict (rank_code) do nothing;
