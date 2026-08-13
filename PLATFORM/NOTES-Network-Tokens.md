# Orvanna design note - Network Tokens

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\NOTES-Network-Tokens.md`
**Captured:** 2026-06-15 | Source: Worldpay conversation (Howard) + public network-token knowledge
**Feeds:** Blueprint Row 5 (Vault) and Row 7 (Routing intelligence); models 07 and 08.

---

## What a network token is

| Thing | Real name | What it is | Who keeps it fresh |
|-------|-----------|------------|--------------------|
| Card number | PAN (Primary Account Number) | the real digits on the card | nobody; dies on reissue / expiry |
| Old way | Account Updater (Visa VAU / Mastercard ABU) | batch program that pushes updated card info periodically | the networks, in slow batches |
| New way | Network token (Visa VTS / Mastercard MDES) | a stand-in number mapped to the PAN | the networks, automatically and continuously |

A network token is a card number that never goes stale, because Visa/Mastercard keep what
is underneath it current. It is replacing the Account Updater program. It also tends to
lift auth rates and cut fraud.

## The portability catch: Token Requestor

Whoever requests the token controls portability.
- Worldpay (acquirer) requests it  ->  token tied to Worldpay (not portable).
- We / our vault request it (the "Token Requestor")  ->  token is ours, usable across providers.

## The two models Worldpay offered

| Question | A: Worldpay holds the token | B: We hold the token (Provisioning API) |
|----------|-----------------------------|------------------------------------------|
| Stores the token | Worldpay | Us, in our own vault |
| Portable to other providers | No (locked to Worldpay) | Yes (ours) |
| What we send each charge | PAN | the network token |
| Token fails (bank not token-ready) | Worldpay falls back to PAN, 2nd try | Worldpay can't (no PAN); we retry PAN or reroute |
| Who runs the retry | Worldpay ("Rev Boost") | Orvanna routing engine |
| Effort on us | Low | Higher (we provision + own retry) |
| Fits Orvanna | No | Yes |

## The flow

```
MODEL A  (Worldpay holds token + PAN):
   charge -> Worldpay -> try TOKEN ->done
                          \-> try PAN -> second chance      ("Rev Boost")

MODEL B  (We hold token + PAN  =  Orvanna):
   charge -> Orvanna vault [TOKEN + PAN]
                 \-> send TOKEN -> Worldpay -> done
                          \-> Orvanna retries with PAN, or reroutes to Provider #2
```

## Portability refinement: storing != owning (the key subtlety)

Storing the token yourself does NOT automatically make it portable. Portability is decided
by ONE thing: the Token Requestor ID (TRID), the registered owner of the token.

| How you get the token | Registered to (Token Requestor) | Portable to other providers? |
|-----------------------|----------------------------------|------------------------------|
| Worldpay tokenizes for you | Worldpay | No |
| Worldpay provisioning API, token under their TRID | Worldpay | No (you hold it, still theirs) |
| Neutral vault / TSP provisions under our control | Us | Yes (use it anywhere) |

The single deciding question: "Under whose TRID is the token issued, Worldpay's or ours?"
If Worldpay's, storing it ourselves buys almost nothing. A Worldpay provisioning API that
still issues under Worldpay's TRID is NOT true portability.

Right architecture: a provider-NEUTRAL vault / Token Service Provider is the Token Requestor,
holds PAN + network token, and Orvanna hands the same token to whichever processor it routes to.

Worldpay's incentive (Howard's read, confirmed sound): a portable token ends their lock-in
and their Rev Boost revenue, so they will provide the API but discourage it. Lesson: never
source the token strategy from a party that profits from our lock-in.

## Decision for Orvanna (leaning, to confirm)

**Merchant-managed network tokens, sourced from a provider-NEUTRAL vault / TSP (not an acquirer).**
1. The token is ours and portable across providers - the core Orvanna principle.
2. The "downside" (we own the retry) is exactly what the Orvanna routing engine is built to
   do: token-first, PAN-fallback, then reroute.
3. We keep the PAN in our own external vault precisely to power that fallback. No processor
   has to hold it for us.
4. **Vault-selection MUST-HAVE:** the vault has to provision portable network tokens under OUR
   control (be a neutral Token Requestor). Add this as a hard criterion to the vault scoring.

This sits inside the Vault model (token + PAN storage, neutral TRID) and the Routing model
(the token-first cascade).

## Open questions for Worldpay (make-or-break)

1. Does their Provisioning API make US the Token Requestor, so the token works at OTHER
   processors too? Or is it still Worldpay-scoped? (Decides true portability.)
2. What exactly is "Rev Boost," and is it only available in Model A (where they hold the PAN)?
3. Who pays the per-token and per-call fees in each model?
4. Which issuers / banks are not token-ready yet, so we know how often PAN fallback fires?

## Honest caveats

- "Universal / use with any provider" is true mainly when we are the Token Requestor. If the
  acquirer requests it, portability is limited. Model B is what makes it actually universal.
- "Rev Boost" specifics are from the Worldpay pitch and need confirming; do not quote exact
  mechanics until verified.
