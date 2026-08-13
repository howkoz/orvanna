# Orvanna - Payment Lifecycle Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\05-PAYMENT-LIFECYCLE-MODEL.md`
**Built:** 2026-06-15 | Stage 1 (system design) | Traces one payment through the components in `04`

> House style: PART 1 see it, PART 2 the words. This is "one payment, start to finish," including
> every branch (token fallback, 3DS, retry, stop).

---

# PART 1 - SEE IT

## One payment, step by step

```
  1. Merchant app  --charge stored card, $X, market M-->  API EDGE          [state: RECEIVED]
  2. API EDGE  -->  ROUTING CORE: pick best processor (rules + health)       [state: ROUTING]
  3. ROUTING CORE  -->  VAULT: give me the token for this card
  4. VAULT  -->  returns NETWORK TOKEN  (keeps the PAN back as fallback)
  5. need 3DS?  --yes-->  3DS MODULE: authenticate                           [state: AUTHENTICATING]
                 --no -->  skip
  6. ROUTING CORE  -->  ADAPTER(processor)  -->  PROCESSOR: authorize w/ token [state: AUTHORIZING]
  7. PROCESSOR  -->  result
         approved  -->  capture / settle  -->  DONE                          [state: APPROVED -> DONE]
         declined  -->  go to step 8
  8. what kind of decline?
         soft  -->  retry: token again, then PAN, then another processor (back to 6)  [state: RETRYING]
         hard  -->  STOP, no retry                                           [state: STOPPED]
         dead subscription  -->  STOP, unrecoverable                         [state: STOPPED]

  * OBSERVABILITY records every step end to end.
  * A charge-once key means retries and reroutes can NEVER double-charge.
```

## The states a payment moves through

| State | Plain meaning | Goes next to |
|-------|---------------|--------------|
| RECEIVED | instruction accepted | ROUTING |
| ROUTING | picking the processor + pulling the credential | AUTHENTICATING or AUTHORIZING |
| AUTHENTICATING | 3DS in progress (only if needed) | AUTHORIZING |
| AUTHORIZING | sent to a processor, waiting on yes/no | APPROVED or DECLINED |
| APPROVED | the processor said yes | DONE (after capture) |
| DECLINED | a processor said no | RETRYING (soft) or STOPPED (hard / dead) |
| RETRYING | trying token, then PAN, then another processor | AUTHORIZING |
| STOPPED | no more attempts (hard decline or dead subscription) | end |
| DONE | money captured | end |

## The branches (where the path forks)

| At this point | Condition | What happens | Feature |
|---------------|-----------|--------------|---------|
| credential | token not supported / token declined | pull the PAN, retry the same charge | F2 |
| 3DS | card or region requires it | authenticate before authorizing | F5 |
| result | soft decline (timeout, do-not-honor) | retry, then reroute to another processor | F3 |
| result | hard decline (stolen, closed account) | stop, no retry | F3 |
| result | dead subscription (over the streak limit) | stop, unrecoverable | F3 |
| anytime | success | charge once, record, done | F1 |

---

# PART 2 - THE WORDS

## The happy path, in words

1. **Received.** The merchant's system asks Orvanna to charge a stored card for an amount in a
   market. The API edge accepts it and the payment enters the RECEIVED state.
2. **Routing.** The core reads the active rules (card brand, country, amount, currency) and current
   processor health, and picks the best processor for this payment.
3. **Get the credential.** The core asks the neutral vault for the network token tied to this stored
   card. The raw card never enters the core. The vault returns the token and holds the PAN in
   reserve as a fallback.
4. **Authenticate if needed.** If the card or the region requires 3DS, the core runs the configured
   3DS provider first. Frictionless cases pass straight through; a challenge asks the shopper to
   confirm, then continues.
5. **Authorize.** The core hands the standard "authorize" call to the chosen processor's adapter,
   which translates it into that processor's API. The token is what gets sent, not the PAN.
6. **Result.** The processor approves. The payment moves to APPROVED, the charge is captured, and it
   reaches DONE. Every step is recorded for tracing.

## The branches, in words

- **Token fallback (F2).** If the issuer is not token-ready, or the token is declined for a
  token-specific reason, the core pulls the PAN from the vault and retries the same charge. This is
  the second chance we own ourselves, instead of renting it from a processor.
- **3DS challenge (F5).** When 3DS returns a challenge, the shopper completes it and the flow
  resumes at authorize. If the configured 3DS provider is swapped, nothing else in the flow changes.
- **Soft decline -> retry and reroute (F3).** Soft declines (timeouts, temporary issuer issues,
  do-not-honor) are retried per the rules: same processor, then the PAN, then a different processor.
  A success on any attempt ends the payment as a single charge.
- **Hard decline -> stop (F3).** Hard declines (stolen card, closed account, no such account) end
  the payment immediately. Retrying these wastes fees and annoys issuers.
- **Dead subscription -> stop (F3).** If the subscription is past the dead-streak threshold, the
  payment is marked unrecoverable and not retried. This is the honesty layer: we do not chase
  customers who are already gone.

## The charge-once guarantee

Every payment instruction carries a single charge-once key. The routing core uses it so that all
the retries and reroutes for that instruction can only ever produce ONE successful charge. This is
what makes aggressive recovery safe: we can try hard without any risk of double-billing a customer.

## What observability sees (F9)

Each state change and each processor attempt is recorded against the payment, so one payment can be
traced end to end: which processor, token or PAN, 3DS or not, how many attempts, final result. That
trace is also the raw material for the live health view and alerts.

## What this hands to the next steps

- The **data model** (06) names every thing mentioned here: payment, instruction, attempt, token,
  PAN reference, processor, result, state.
- The **routing engine model** (07) zooms into steps 2, 6, and 8 (selection, the cascade, the
  decline decisions).
- The **vault** (08) and **3DS** (09) models zoom into steps 3-5.
