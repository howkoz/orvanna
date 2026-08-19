# Handoff: the Orvanna checkout, and nothing else

**Scope: `shop.html`'s checkout view only** — the `#viewCheckout` section and the styles it uses in `css/shop.css`. Do not touch the catalog view, the confirmation view, or any other page in the repo. Other pages have their own redesigns in a separate package; none of them are in scope here.

## What is in this folder

| File | What it is |
| --- | --- |
| `Checkout.dc.html` | The redesigned checkout. Open it in a browser to click through all four steps and all five payment methods. |
| `support.js` | Runtime file `Checkout.dc.html` loads. Keep it beside the design file; it does not belong in orvanna.io. |

The design is a live mock: the stepper, method switching, activation choice, currency, tax, PV meter and payment gating all work. Read it as the specification.

## The four defects it fixes

**1. Four numbered panels open at once.** `#accountPanel`, `#addressPanel`, `#deliveryPanel` and `#paymentPanel` all render simultaneously — eleven fields, three `<details>` disclosures and a five-button payment row in one column, each panel with its own `.accent-bar`. There is no sense of progress and no review state.

Becomes a four-tab stepper across the top. One step's content shows at a time, and **each tab carries that step's answer** (`Guest`, `Dana Ortiz, IL 60642`, `Standard, free`, `Card`), so the bar doubles as the review summary. Completed tabs are clickable to go back. Keep the existing panel markup and IDs if that is cheaper — the change is which panel is visible plus the tab bar above.

**2. The payment method buttons were text.** The live page renders `.pay-mark` spans containing the literal strings `Apple Pay`, `GPay`, `PayPal`, `Card` and `Plaid`, styled with CSS. That is the single most amateur element on the page.

Becomes five drawn marks on the system's 2px ink in a uniform 40×26 box — card with magstripe and chip, device, wallet, bank pediment, payment link — each with the method name and its **honest state**: `LIVE ON SANDBOX`, `APPROVAL PREVIEW`, `STAGED`. Lift the SVGs from `Checkout.dc.html` verbatim; the repo has no payment icon assets today.

> **On brand artwork.** The five method marks are original neutral glyphs, safe to ship. The *detected network* label (VISA / MASTERCARD / AMEX) is deliberately **typographic, not redrawn brand artwork** — an earlier draft imitated the Mastercard device and it was removed. At implementation, drop the official SVGs from each network's and each wallet's own brand kit into the same 34×22 and 40×26 boxes. The networks require their own artwork; this is a trademark question, not a design one.

**3. Currency and Tax ID lived inside the order summary.** `#currencySelect` and `#taxId` are inputs sitting in a receipt column. Both move below the totals, and the USD card guard now renders **where the shopper would act on it**, with the resolving action attached — which is what the "WHY THERE ARE NO CARD FIELDS" comment block above `#currencyGuardNote` already asks for.

**4. `#placeOrderBtn` stayed live when payment was impossible.** Select bank debit (staged) or a non-USD currency with card selected, and the live button remains enabled and accent-red, offering to place an order on a rail that cannot take one.

Now gated: `disabled` plus a muted fill plus a plain reason line beneath it —

```
method === 'bank'                        -> "Bank debit is staged, not live. Pick Card to complete this order."
method === 'card' && currency !== 'USD'  -> "Card settles in USD only. Switch the currency back to USD to place this order."
```

`css/shop.css` already carries disabled treatments for `.pay-btn` and `#placeOrderBtn` under `body.payment-in-flight` (~line 2234) — reuse them.

## Two smaller corrections

- **3-D Secure showed under every method.** `#threeDsNotice` renders regardless of selection. 3DS is a card-network identity check; it is wrong under Google Pay, PayPal and bank debit. Gate it to `method === 'card'`.
- **The place-order button now carries the amount.** `PLACE ORDER · $207.38` on the button, so nobody scrolls back up to check what they are about to be charged.

## What is deliberately unchanged

- Every field, ID and hook in the existing markup. This is a reorganisation and a restyle, not a new form.
- The public demonstration credentials, and the reasoning printed beside them.
- All four `<details>` explanations — the honesty copy is good. It moves from stacked disclosures into the step it belongs to.
- The PV meter. It was the best thing in the summary; it now sits in an ink band where it reads first.
- The tax rule: tax stays uncalculated until State and postal code exist, and says so in place of a number.

## Colour and type

Oat ground `#eae4d9`, ink `#1b1917`, one accent `#ec3013`, surfaces `#f1ede6` / `#f6f4f0`, Archivo throughout, zero corner radius, 2px rules. If the site's palette pass has not landed yet, this page can adopt it alone — nothing here depends on another page's tokens.
