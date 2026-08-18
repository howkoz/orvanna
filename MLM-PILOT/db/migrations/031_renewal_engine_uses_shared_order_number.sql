-- 031_renewal_engine_uses_shared_order_number.sql
-- Howard, 2026-08-17: order numbers look the same "regardless how the order is
-- placed from shop or ran in the subscription batch".
--
-- Migration 030 gave the shop and the staff console one shared source of order
-- numbers. The renewal engine did not use it: app.fn_dispatch_attempt minted its
-- own name, REN-<subscription>-<renewal_index>-<attempt_no>, so the subscription
-- batch produced a THIRD shape of order number. This points it at the shared
-- source, leaving every other line of the function untouched.
--
-- WHY THE OLD NAME WAS SAFE TO DROP
--   The REN- name looked like the batch's duplicate guard, because it encoded
--   exactly the tuple that must never repeat. It was not the guard. The guard is
--   structural and lives elsewhere:
--       billing_attempts  UNIQUE (renewal_period_id, attempt_no)
--       renewal_periods   UNIQUE (subscription_id, renewal_index)
--   Those already forbid what the name encoded, so the name was a redundant
--   second copy of a rule enforced independently. Verified against pg_constraint
--   before this migration was written.
--
-- WHY IT IS WRITTEN AS A REPLACEMENT RATHER THAN A RETYPED FUNCTION
--   The function is ~3,700 characters and only ONE line changes. Retyping it by
--   hand risks a silent transcription error somewhere in the other 3,600. This
--   reads the live definition, performs one textual substitution, and REFUSES to
--   run if the substitution did not match, so it cannot quietly reinstall an
--   unchanged copy and report success.

do $$
declare
  v_old text;
  v_new text;
begin
  v_old := pg_get_functiondef(
    'app.fn_dispatch_attempt(bigint,bigint,integer,text,integer,date)'::regprocedure);

  v_new := replace(
    v_old,
    'v_order_no := ''REN-'' || v_period.subscription_id || ''-''
                  || v_period.renewal_index || ''-'' || p_attempt_no;',
    '-- One source of order numbers (migration 030): shop, staff console and
    -- this engine all mint from app.order_number_seq, so an order is an order
    -- whatever created it. The deterministic REN- name this replaced was NOT
    -- the duplicate guard it resembled: UNIQUE (renewal_period_id, attempt_no)
    -- on billing_attempts and UNIQUE (subscription_id, renewal_index) on
    -- renewal_periods already enforce that structurally.
    v_order_no := app.fn_next_order_number();');

  if v_new = v_old then
    raise exception
      'order-number line not found in fn_dispatch_attempt: refusing to replace the function with an unchanged copy';
  end if;

  execute v_new;
end $$;

-- VERIFICATION RUN AFTER APPLYING (all three held):
--   still_concatenates_ren_literal  false   -- no 'REN-' || remains
--   assigns_from_shared_source      true    -- v_order_no := app.fn_next_order_number();
--   assignment_count                1       -- exactly one assignment, not two
--
-- Note for anyone re-checking: a naive "does the definition still contain REN-"
-- test returns TRUE, because the explanatory comment above names the old format.
-- Test for the concatenation, not the substring.
