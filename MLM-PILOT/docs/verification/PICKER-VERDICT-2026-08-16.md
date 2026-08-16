# Verification Verdict: the guest tax state picker, pre-deploy delta gate

Verifier: mlm-verifier, run 2026-08-16, on commit 651ac49 (not deployed). This
verdict gates the deploy of the site AND the three function files
(`functions\_shared\tax.ts`, `functions\quote-tax\index.ts`,
`functions\create-payment\index.ts`). Instruments: repository reads, diff
traces, and command-line probes of the live rail; the Browser pane belonged to
the quality assurance agent. Per charter: I grade, I fix nothing.

## GATE: PASS. Deploy YES from the verifier's half, with one ordering note.

One MEDIUM finding, recorded at the coordinator's instruction and awaiting the
owner's ruling; it is pre-existing in mechanism and does not block this gate.
Two LOW observations. The core design holds everywhere I probed it: one
implementation, one normalization point, the code inside the amount signature,
and no path by which the browser can hand Stripe an address.

THE ORDERING NOTE: deploy the three function files BEFORE or TOGETHER WITH the
site. If the site ships first, the deployed functions ignore the unknown
`guest_state` field, so the picker visibly does nothing: the estimate label
names the picked state and the quote then answers for Illinois, which is a
transient version of the exact label-versus-figure disagreement this feature
exists to end.

## Findings

### MEDIUM

**P-M1 (recorded, awaiting the owner's ruling; does not block this gate).
The referral-code precedence can quietly override the picked state.** A guest
who picks a state AND types a referring member's code is priced from the
REFERRER's stored address; the picked state is ignored (`resolveTaxAddress`:
any attached member wins). This is the pre-existing rule, unchanged in
mechanics, now documented in the resolver's precedence comment, and it is
symmetric between quote and charge, so no wrong-amount path exists. What the
picker adds is the EXPECTATION: the page now invites a pick ("Pick a state
and the tax engine prices this order for that state") and the estimate label
names the picked state, both of which the typed referral code silently
falsifies until the server's quote answer repaints the label with the real
jurisdiction. Not newly worsened in behavior, newly visible in consequence.
Until the ruling lands, a cheap softener would be annotating or disabling the
picker while the member-code field is non-empty; that is the owner's call.

### LOW

**P-L1.** The pre-existing `onTotalsApplied` hook updates the pay button when
`clientSecret` is set and the button visible, without the `checkOnly` and
`busy` guards the new `syncPayButtonToDisplayedTotal` carries. Reaching it
wrongly requires a totals-current repaint during check-again duty, which I
could not construct from any real trigger (every renderSummary trigger either
moves the signature, which forces the other branches, or follows a reset,
which clears `clientSecret`); recorded for symmetry, not for reachability.

**P-L2.** The eight display names in the page and the eight server addresses
must stay in step by convention (both sides carry MUST-match comments naming
each other). A drifted entry fails soft (server prices Illinois, label names
the picked state until the quote corrects it), which is the right failure
direction; noted because convention is the only thing holding it.

## What was verified sound

**1. One implementation (item 1).** `GUEST_STATE_ADDRESSES` holds exactly
eight canned addresses (IL is `HOUSE_TAX_ADDRESS` itself; the other seven are
synthetic at the street and real at city, ZIP code, and state).
`guestAddressFor` is the ONLY place a code becomes an address, and it does the
trim-and-uppercase normalization once for both callers. The resolver
precedence reads exactly as briefed: member with stored address wins; member
without a ZIP code gets the house default; no member (empty code or miss)
takes the picked state; unknown code silently prices as Illinois. quote-tax
and create-payment parse `guest_state` with VERBATIM-IDENTICAL expressions
(`typeof body.guest_state === "string" ? body.guest_state.trim().slice(0, 2) : ""`)
and both pass it to the same shared resolver, so the quote-versus-charge
asymmetry this project treats as the worst class of bug cannot arise from
parsing.

**2. The signature (item 2).** `guest_state: guestTaxState()` sits in the
shop's `signaturePayload`, which doubles as the quote body, and the identical
expression sits in `liveStart`'s create payload. The picker's change event
calls `renderSummary`, which ends in `liveEnsureQuote()` then
`liveEnsureCheckout()`: a changed state re-asks the tax question and, when a
payment is already open, mismatches the recorded signature and discards and
reopens it. `#guestTaxState` is in the inert selector list, so the state
cannot move while a payment is in flight, and the `liveConfirm` signature
guard remains the last rail before the card is handed over (untouched by this
commit). `guestTaxState()` returns an empty string for a signed-in member, so
the hidden picker can never churn a member's signature. The builder's live
proof orders exist on the rail: ORV-2026-08-17DKXS and ORV-2026-08-17G6S9
both answer from confirm-payment (status processing, identical carts),
consistent with the reported discard-and-reopen experiment.

**3. No injection path (item 3).** The only client inputs that can influence
the tax destination are: `member_code` (resolved against the members table,
address from the database), and `guest_state` (trimmed, sliced to two
characters, used solely as a lookup key into the server-side Record with a
`?? HOUSE_TAX_ADDRESS` fallback; two characters forecloses every prototype
key, and a missing key falls to the house address). The street, city, and ZIP
code the guest types into the billing form never leave the page: the create
and quote payloads carry exactly items, activation, tax_id, member_code,
guest_state, channel, and return_page, and `setAddress` writes only to the
document. `tax_id` reaches Stripe as an exemption identifier, never as an
address. No client-controlled address can reach Stripe.

**4. The referral-code precedence (item 4).** Recorded as P-M1 above.

**5. syncPayButtonToDisplayedTotal (item 5).** All three totals-painting
branches of `renderSummary` now move the button with the row: the
totals-current branch through `applyServerTotals` and the `onTotalsApplied`
hook, and both estimate branches (tax-exempt and ordinary) through the new
helper with the same figure they just painted. The helper is correctly silent
before the first open (no figure on the button yet), on check-again duty, and
while busy (inert holds every amount control, so the displayed total cannot
move mid-confirm). The remaining asymmetry is P-L1 above. The hard rail at
submission time is unchanged.

**6. Guardrails (item 6).** Zero em or en dashes across all six files. New
user-facing copy carries no unexpanded acronyms (the picker copy is plain
state names; "ZIP code" is spelled as a word in server comments). No Unicity
terminology. The owner's name appears only in server-side function comments
(dated rulings and asks, the established convention in files that never ship
to the public build and are not scanned by the dist name lint); it appears in
no shipped page or script. The staff console documents its deliberate
non-participation with a dated scope note in `signaturePayload`, and the
`payments.js` change is comment-only (the engine's contract documentation now
explains why a signature field automatically joins both the quote and the
discard-reopen behavior).

## SHA-256 of the graded artifacts (at commit 651ac49)

| Artifact | SHA-256 |
| --- | --- |
| `MLM-PILOT\functions\_shared\tax.ts` | `aada150c7dcdbf3f37cfd8391f86eec17d1cfe887c4d91003833bb311614bc72` |
| `MLM-PILOT\functions\quote-tax\index.ts` | `59894e5c489de97a03cc598f44861455758e1c1e4785afe03d421549e420bf57` |
| `MLM-PILOT\functions\create-payment\index.ts` | `5d34ff1b59f05eebaf94a13cefcd7f85bf09a2812509b49863e068f099146ea0` |
| `MLM-PILOT\www\shop.html` | `2fea93f47b56074325a158faff61ac444caa86dce84b78f4f06c99da1f0e9b64` |
| `MLM-PILOT\www\staff.html` | `9a2754b852239227796aa4a656aa76389332099267e7ddbb29d83113aa608676` |
| `MLM-PILOT\www\js\payments.js` | `1e8359c4c8592dc4166b567ab1ce6708c46e7cde9ea8b945df4706bb85c6aa8d` |

## What I did NOT probe

- The picker in a real browser (change the state, watch the quote and the
  reopen): QA's half; my trace is code-level plus the builder's live order
  evidence.
- The deployed behavior of `guest_state`: the functions are not deployed, so
  no live endpoint accepts the field yet; the live rail today ignores it,
  which is exactly why the ordering note above exists.
- Whether each of the seven non-Illinois states actually returns a nonzero
  figure: that is the owner's Stripe dashboard registration per state, and
  the page correctly labels a zero as `not_collecting` versus `none due`.
- The deploy byte-compare of the three function files against the cloud once
  shipped: that obligation opens at deploy time per the standing rule, along
  with the still-open N-M1-related compare noted in the delta verdict if not
  already discharged.
