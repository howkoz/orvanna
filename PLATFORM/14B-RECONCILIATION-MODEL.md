# Orvanna - Reconciliation Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\14B-RECONCILIATION-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Feature F10 | Money truth, for the merchant and for us
Added during Phase B review. Howard's catch: reconciliation was only a node in the flow, never modeled.

> House style: PART 1 see it, PART 2 the words. This model exists because a payment is not "done"
> when it is approved. It is done when the money is proven to have landed and any gap is found and
> worked. Orvanna does not hold money, so reconciliation here means matching records from three
> independent sources until they agree.

---

# PART 1 - SEE IT

## The one idea

```
   Approved  is NOT the same as  Paid.
   Reconciliation proves the money landed, and flags anything that did not.
```

## The three-way match (the heart)

```
   1. WHAT WE RECORDED        2. WHAT THE PROCESSOR SAYS      3. WHAT THE BANK SHOWS
      Orvanna event ledger       settlement / payout file        actual deposit
      captured $100              cleared $100, fee $2.90         deposited $97.10
            \                            |                            /
             \___________________  MATCH ENGINE  ____________________/
                                         |
                      agree  -->  tie-out clean  (no action)
                                         |
                   disagree  -->  EXCEPTION queue  (worked in the console)
```

Matching one source is bookkeeping. Matching all three is reconciliation. Only the third leg, the
bank, proves the cash is real and not just promised.

## Two views, one engine

| View | Who it is for | The question it answers | What it flags |
|------|---------------|-------------------------|---------------|
| **Platform recon** ("for us") | Orvanna (you) | Across every merchant and processor, is everything we routed accounted for? | Fee leakage, missing settlements, our recovery-revenue proof, our own billing ties out |
| **Merchant recon** ("for the user") | The merchant (Globex) | Did every order I captured land in my bank, with fees clear? | Short-pays, missing payouts, chargebacks, refunds not netted |

## Three levels it checks

| Level | Ties out when... |
|-------|------------------|
| Transaction | each capture matches one settlement line, amount and fee as expected |
| Payout / batch | settled minus fees minus refunds minus chargebacks = the bank deposit |
| Period (close) | for the day or month, captured = settled + in-flight, and the books close |

## Where it lives (answering "is this the operator console?")

| Piece | Home | Under the console? |
|-------|------|--------------------|
| Ingest settlement files, run the match, keep the recon ledger | recon ENGINE (own subsystem, on Data model 06) | no, behind the glass |
| See the tie-out, drill a payment, work the exception queue | Operator console (11) | **yes, this part** |
| "File late / job failed" health and alerts | Observability + ops (14) | no, ops layer |

## What an exception can be

```
   missing in settlement   we captured, the processor never settled it     (in-flight or lost)
   amount short-pay        settled for less than we captured
   fee mismatch            processor took a fee we did not contract for
   refund not netted       a refund is missing or double-counted
   chargeback              a dispute was deducted from the payout
   timing                  settled in a later batch (resolves itself)
   deposit shortfall       the payout says X, the bank shows less
```

---

# PART 2 - THE WORDS

## Why this model exists (F10)

A payment is not finished when the processor says "approved." It is finished when the money is proven
to have arrived and every difference is explained. Orvanna does not hold or move money (it is not an
acquirer; see the non-goals in 03), so reconciliation here is not about moving cash. It is about
matching records from three independent sources until they agree, and surfacing anything that does
not so a human can work it. This was a gap in the first pass: reconciliation appeared only as a single
node at the end of the end-to-end flow. It earns its own model.

## The three sources, and why all three

1. **What we recorded.** Orvanna's own event ledger (from the Data model, 06): every authorize,
   capture, refund, and void, with amount, currency, processor, token or PAN reference, and the full
   attempt history. This is our book of what we believe happened.
2. **What the processor says.** Each processor delivers a settlement or payout file: which
   transactions actually cleared and what fee it took. Every processor's file is a different format
   and cadence, so each needs a thin normalizing adapter, the same "own the doorway" discipline as the
   connector adapters (10).
3. **What the bank shows.** The deposit that actually landed in the bank account. This is the hardest
   leg to automate (it often needs a bank feed or an imported statement) and the one that proves money
   truly arrived rather than was merely promised.

Matching one source is bookkeeping. Matching all three is reconciliation, and only the third leg makes
it real.

## The two audiences, in depth

**Platform reconciliation (for us).** Across every merchant and every processor, is each payment we
routed accounted for end to end? This is where we catch fee leakage (a processor charging more than
contracted), prove our recovered-revenue and approval-lift claims in numbers an investor can trust,
and make sure our own platform billing itself reconciles. The platform's books tying out is a
credibility asset, not just hygiene.

**Merchant reconciliation (for the user).** For a merchant running many processors, matching captures
to bank deposits is the single most painful back-office job. Today it is done by hand, a spreadsheet
stitched per processor. Orvanna collapses that into one reconciled view across every processor, with
fees broken out and every exception flagged. That is a headline reason a merchant switches to us, and
a reason they stay.

## Levels of matching

- **Transaction level.** Each capture in our ledger matches exactly one line in a settlement file:
  same reference, same amount and currency, with the fee inside the contracted range.
- **Payout level.** For a batch payout, the settled transactions minus fees, refunds, and chargebacks
  equal the single deposit that hits the bank.
- **Period close.** For a day or month, total captured equals total settled plus still-in-flight, and
  total deposited equals total settled minus fees and adjustments. The books close.

## What happens to an exception

Anything that does not agree within tolerance becomes an exception and lands in a queue worked in the
operator console (11). Common kinds: a capture with no matching settlement (in-flight or lost), a
short-pay, a fee that does not match contract, a refund missing or double-counted, a chargeback
deducted from a payout, a timing difference that will clear in a later batch, or a deposit short of
what the payout promised. Tolerance and FX-rounding rules keep the queue honest, so it holds real
problems and not noise.

## Where it sits (and the console question, answered plainly)

Reconciliation is a subsystem, not a screen. The **engine** (ingest settlement files, run the match,
keep the recon ledger) is its own component built on the Data model (06). The **operator console**
(11) is where a human sees the tie-out, drills into a single payment, and works the exception queue,
and that part is "under the console." The **observability and ops** layer (14) watches the recon jobs
themselves and alerts when a file is late or a job fails. So the honest answer to "is this under the
operator console?" is: the view is, the engine is not.

## Leverage, not from scratch

HyperSwitch ships a reconciliation module. Consistent with the console decision (11), we adopt and
extend it rather than build from zero: take its settlement ingest and matching, add the bank-deposit
leg and the two-audience views (platform and merchant), and re-skin to Orvanna. This keeps us on the
base we are already standing on.

## The honest hard parts

- Every processor's settlement file is a different shape and schedule; normalizing them is ongoing
  work (mitigated by the adapter discipline, but real).
- The bank-deposit leg is the hardest to automate and may start as a manual import.
- Disputes and chargebacks arrive on their own timeline and must be matched back to the original
  payment, sometimes weeks later.
- The exception queue needs an owner. Tooling shrinks it; it does not erase it. This ties directly to
  the staffing honesty in the observability model (14) and is funded, not assumed, in the cost model (16).

## What this hands to the next steps

- The **Data model** (06) holds the event ledger this matches against, and gains a reconciliation ledger.
- The **Operator console** (11) presents the tie-out and the exception worklist.
- The **Observability and ops** model (14) watches the recon jobs and owns the alerts.
- The **Cost and team model** (16) funds the human who works exceptions.
- The **Connector-adapter** discipline (10) is reused to normalize each processor's settlement file.
- It extends the PBV spec (03) with a tenth feature, F10 Reconciliation.
