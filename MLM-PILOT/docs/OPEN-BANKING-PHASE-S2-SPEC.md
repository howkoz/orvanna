# Open Banking (Plaid) — what it would take to make it real

> Written 2026-08-20, after the bank tile was reported as "not working since the
> redesign". Two separate things were true and only one of them was a regression.

## What is actually true today

**The panel was never broken.** Driven in a browser: the tile enables in GBP, the
panel opens, the institutions list, sign-in and account selection work, and the
authorization step completes. No page errors.

**What broke was every colour in it.** The panel lives outside all four views, so
the checkout redesign's `#viewCheckout` scope never reached it and it kept the old
dark theme: a navy scrim, navy row fills, slate borders, and labels reading
`var(--shop-paper)` — a token the paper conversion repurposed from near-white to
ink. Ink on navy is why the bank rows read as unlabelled grey blocks. Fixed
2026-08-20.

**The payment has never existed.** That part is not a regression and never worked.

## The two server guards

`functions/create-payment/index.ts` refuses a bank payment twice, before anything
reaches HyperSwitch:

```
payment_method !== "card"   ->  409  payment_method_staged
currency       !== "USD"    ->  409  currency_staged
```

There is **no `open_banking` handling anywhere in the Edge Functions.** Zero
matches across the whole `functions/` tree.

## The contradiction, which is the thing to know before starting

The client and the server disagree about which currency bank debit lives in, and
the disagreement is invisible because the client-side guard stops the request
before the server ever gets to object:

| | Rule | Where |
| --- | --- | --- |
| The storefront offers Bank account in | **GBP or EUR only** | `bankMethodAllowed()`, shop.html |
| The server accepts | **USD only** | `create-payment`, guard two |

**Bank debit can never succeed, by construction.** Lifting the `payment_method`
guard alone does nothing: every order the storefront is capable of sending is
non-USD, so guard two refuses all of them. Lifting both without storing per-order
currency would settle a GBP order at USD figures.

Whoever picks this up will lift one guard, watch it still fail, and lose an hour.
That hour is the reason this document exists.

## What Phase S2 actually needs, in dependency order

1. **Per-order currency storage.** `app.demo_orders` records amounts with no
   currency column, which is the stated reason guard two exists at all. Nothing
   else on this list is safe until an order can say what currency it is in.
   Until then a non-USD order is a number without a unit.

2. **An `open_banking` branch in `create-payment`.** Guard one becomes a
   allowlist of `card` and `open_banking_pis` rather than a card-only test. The
   HyperSwitch create body needs the open-banking payment method data and the
   country, which the panel already collects and currently throws away.

3. **Reconcile the currency rules.** Pick one source of truth for where bank
   debit is offered and make both sides read it. The present split is two
   independent constants that were never compared.

4. **The return path.** Open banking redirects to the bank and back, the same
   shape as a 3-D Secure challenge. `buildReturnUrl` and the resume flow already
   handle exactly this for cards and should be reused rather than duplicated.

5. **Webhook handling** for the asynchronous settlement open banking uses, since
   authorization and settlement are not the same moment the way they are on a
   card.

## What ships in the meantime

The sandbox preview now **completes in the browser**, the same way Google Pay and
PayPal already did through `demoPlaceOrder`. A visitor can walk the whole flow and
reach a confirmation instead of a dead end.

**It writes nothing to the server, deliberately.** The shop-to-comp bridge selects
on `d.payment_status = v_state_gate` (migration 019), so an order row written as
succeeded becomes commission volume. A simulated payment reaching the commission
engine is exactly what produced 2,700 phantom Personal Volume in August. The
simulated order therefore exists only in the browser, carries the `O-SIM-` number
shape that cannot collide with a real order, and says on the confirmation that no
payment was created.

Verified: a full sandbox walk issues **zero** POST requests.

## The lesson worth carrying out of this

Two guards written months apart, each correct on its own, that together describe
an impossibility. Neither is wrong; the pair is. Nothing detected it because the
earlier guard prevents the later one from ever being exercised.

**A guard that is never reached is never tested, and a pair of guards is a
contract nobody wrote down.** When one refuses what the other requires, the
system is not conservative, it is closed — and it will look like a small
configuration problem to the next person who opens it.
