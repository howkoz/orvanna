-- S1 proof run, segment 10: tick every day 2026-09-01 through 2026-11-14,
-- with THE MEMBER-ACTION YEAR woven in at its scripted dates (fix round,
-- QA M3, verifier H1 scenarios). Actions run AFTER that date's tick, which
-- is when a member acts: the morning billing has happened, the afternoon
-- click follows.
--
--   Sep  4  PETE pauses 2 months from past_due, AFTER a retry has executed:
--           the exact shape that crashed fn_sub_pause before the fix (H1).
--   Sep 12  QUINN pauses 1 month from dunning (T10a, clock freeze);
--           TINA cancels during dunning (T15).
--   Sep 15  XENA reactivates from card_update_required (T16, same month:
--           the fresh cardholder-present payment covers the open period).
--   Sep 20  RITA pauses 2 months from active (T5).
--   Sep 25  RITA tries to resume INSIDE the first paused month: the S1
--           refusal path, expected to raise, caught and recorded.
--   Oct  5  SAM pauses 2 months from active.
--   Oct 10  WALT reactivates from suspended (T21, forward only).
--   Nov 10  SAM resumes early (allowed: one whole month elapsed);
--           NORA changes frequency quarterly to monthly through the
--           sanctioned function (verifier M2 semantics).
do $$
declare
    d date;
    v_pete  bigint; v_quinn bigint; v_rita  bigint; v_sam  bigint;
    v_tina  bigint; v_walt  bigint; v_xena  bigint; v_nora bigint;
    v_zoe   bigint;
begin
    select s.id into v_zoe   from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9021';
    select s.id into v_pete  from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9011';
    select s.id into v_quinn from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9012';
    select s.id into v_rita  from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9013';
    select s.id into v_sam   from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9014';
    select s.id into v_tina  from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9015';
    select s.id into v_walt  from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9018';
    select s.id into v_xena  from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9019';
    select s.id into v_nora  from app.subscriptions s join app.members m on m.id = s.member_id where m.member_code = 'GW-9009';

    for d in
        select generate_series(date '2026-09-01', date '2026-11-14',
                               interval '1 day')::date
    loop
        perform app.fn_billing_tick(d);

        if d = date '2026-09-04' then
            perform app.fn_sub_pause(v_pete, 2, 'member');   -- H1: pause mid-ladder
        elsif d = date '2026-09-12' then
            perform app.fn_sub_pause(v_quinn, 1, 'member');  -- T10a from dunning
            perform app.fn_sub_cancel(v_tina, 'member');     -- T15 during dunning
        elsif d = date '2026-09-15' then
            perform app.fn_sub_reactivate_sim(v_xena, 'visa', '1111', 'member');  -- T16
        elsif d = date '2026-09-20' then
            perform app.fn_sub_pause(v_rita, 2, 'member');   -- T5 from active
        elsif d = date '2026-09-25' then
            begin
                perform app.fn_sub_resume(v_rita, 'member');
                raise warning 'RITA early resume inside the first paused month UNEXPECTEDLY SUCCEEDED (should refuse)';
            exception when others then
                raise warning 'RITA early-resume refusal recorded, as designed: %', sqlerrm;
            end;
        elsif d = date '2026-10-05' then
            perform app.fn_sub_pause(v_sam, 2, 'member');
        elsif d = date '2026-10-10' then
            perform app.fn_sub_reactivate_sim(v_walt, 'mastercard', '2222', 'member');  -- T21
        elsif d = date '2026-10-15' then
            perform app.fn_sub_cancel(v_zoe, 'member');  -- open system-fault periods resolve void_cancelled
        elsif d = date '2026-11-10' then
            perform app.fn_sub_resume(v_sam, 'member');      -- early resume, allowed
            perform app.fn_sub_change_frequency(v_nora, 1, 'member');  -- M2 sanctioned path
        end if;
    end loop;
end
$$;

select 'segment 10 complete, clock now' as label, clock_date from app.sim_clock;
