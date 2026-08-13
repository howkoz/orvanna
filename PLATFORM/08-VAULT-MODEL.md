# Orvanna - Vault and Tokens Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\08-VAULT-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Features F2, F4 | See also `NOTES-Network-Tokens.md`

> House style: PART 1 see it, PART 2 the words. The rule that drives everything here: the vault is
> SEPARATE and NEUTRAL, and the token is registered under OUR control so it is portable.

---

# PART 1 - SEE IT

## The boundary

```
   +================ Orvanna core ================+        +========= NEUTRAL VAULT =========+
   |  holds only a REFERENCE to the credential     | <----> |  holds the SECRETS:             |
   |  never the real card number                   |  by    |   - network token (portable)    |
   |                                               |  ref   |   - PAN (fallback)              |
   +===============================================+        |   - registered under OUR control|
                                                            +================================+
                              the SAME token goes to ANY processor (Worldpay, Nuvei, Adyen, KSNET...)
```

## First time a card is stored

```
   shopper enters card  -->  VAULT stores the PAN
                         -->  VAULT provisions a NETWORK TOKEN under our Token Requestor control
                         -->  VAULT returns a reference to the core
   (the core never sees the raw card; it gets a reference)
```

## At charge time

```
   core asks VAULT (by reference)  -->  token first  -->  to the chosen processor
                                          │ fails / not supported
                                          └► PAN (fallback)  -->  retry (F2)
```

## What lives where

| Data | Lives in the core? | Lives in the vault? |
|------|--------------------|---------------------|
| Real card number (PAN) | no | yes |
| Network token | no (reference only) | yes |
| Brand, last 4, expiry | yes (display only) | yes |
| Who the token is registered to | n/a | OUR control (portable) |

---

# PART 2 - THE WORDS

## Why the vault is separate and neutral

The vault is a different vendor from the orchestrator and from every processor. That separation is
the locked rule of the whole project, and it buys three things: we OWN the card data, no processor
can hold our tokens hostage, and we can switch or add processors without re-collecting a single
card. (Cross-vendor rule and the decoupled-vault decision.)

## Tokenization and lifecycle (F4, F2)

The first time a customer provides a card, the vault stores the PAN and provisions a **network
token** for it. Because the token is registered under **our** Token Requestor control (not a
processor's), it is portable: the same token can be presented to any processor we route to. The card
networks keep the token current automatically when the underlying card is reissued or re-dated, so
recurring charges keep working without an Account Updater batch. (Full detail and the make-or-break
"under whose Token Requestor ID" question are in `NOTES-Network-Tokens.md`.)

## Charging: token first, PAN fallback (F2)

At charge time the core never handles the raw card. It asks the vault for the credential by
reference. The token is tried first because token transactions tend to approve at higher rates. If
the issuer is not token-ready or the token is declined for a token-specific reason, the core asks the
vault for the PAN and retries. We own that second chance instead of renting it from a processor.

## The PCI boundary (feeds `13`)

Because the real card number lives only in the neutral vault and the core handles references, the
core stays out of the heaviest part of PCI scope. The vault provider carries the card-data burden.
This is a deliberate design choice that shrinks our compliance load, detailed in the security model.

## The hard requirement when we choose a vault

A vault is only acceptable for Orvanna if it can provision **portable network tokens under our
control** (act as a neutral Token Requestor). A vault that only issues tokens locked to one
processor breaks the whole portability promise. This is a must-have, not a nice-to-have, and it
carries into the vault scoring.

## What this hands to the next steps

- **3DS** (09) runs alongside this at charge time when authentication is required.
- **Security** (13) builds the PCI scope picture on top of this boundary.
- The **connector adapter** (10) presents whatever the vault returns (token or PAN) to the processor.
