# Orvanna: the complete documentation set

Plain path: `C:\Users\howar\Desktop\Desktop\ORVANNA\DOCUMENTATION\`

This folder is the full technical and business record of Orvanna as it stands
today. It exists so that one person, reading in order, can understand the whole
thing: what it is, what it sells, how the money moves, how it is built, who
built which part, and what is still unfinished.

Every document here was written by the specialist who owns that area, not by a
single narrator summarising second hand. Where a document says something is
true, it was verified in the actual file or the live system, and where
something is unverified or not yet built, it says so plainly.

---

## Read in this order

| # | Document | What it answers | Written by |
|---|----------|-----------------|------------|
| 01 | [Architecture](01-ARCHITECTURE.md) | What the system is made of, what language each part is written in, and how a purchase travels through it | Architect |
| 02 | [Data model](02-DATA-MODEL.md) | Every table and column, what each is for, and the rules that protect an order once money is involved | Database engineer |
| 03 | [Compensation plan](03-COMPENSATION-PLAN.md) | How anyone earns money, with the arithmetic worked out step by step | Compensation engineer |
| 04 | [Checkout and flows](04-CHECKOUT-AND-FLOWS.md) | One diagram and one explanation per flow: cart, account, tax, three-domain secure, confirmation, staff | Site builder |
| 05 | [Product catalog](05-PRODUCT-CATALOG.md) | All sixteen products, both pricing modes, what is inside each pack | Writer |
| 06 | [Quality assurance and verification](06-QA-AND-VERIFICATION.md) | What has been tested, what passed, what is still open, and what is not tested at all | Quality assurance and verifier |
| 07 | [Design system](07-DESIGN-SYSTEM.md) | Colours, type, components, and the Figma import pack | Designer |
| 08 | [The team and what we built](08-TEAM-AND-WHAT-WE-BUILT.md) | Who does what, the timeline of every phase, and the lessons that cost real time | Project historian |
| 09 | [Linking the shop to the compensation plan](09-LINKING-SHOP-TO-COMP.md) | The connection that now exists: how a paid shop order becomes commission volume. **LIVE as of 2026-08-16**: all seven of Howard's policy decisions ruled, migrations 019 to 021 applied, 11 real orders bridged into August, verifier gate PASS with zero findings. The first commission run over real volume happens at the end of August. | Compensation engineer |
| 10 | [Instant Payout terms](10-INSTANT-PAYOUT-TERMS.md) | The adopted fourth earning mechanism turned into concrete costed terms: what "first" means, what it pays on, what three rate levels cost against the 20 percent of revenue ceiling, how a chargeback is recovered, and a one-page recommended package | Compensation engineer |
| 11 | [Refunds](11-REFUNDS.md) | How a staff agent returns a customer's money: why hiding the button is not a gate and what the real one is, whether Braintree can refund at all, and every knock-on the refund creates on tax, commissions and Instant Payout. **LIVE as of 2026-08-16.** Migrations 022 and 023 applied, `refund-payment` deployed, ten direct-call refusals proven against the live endpoint, and one real refund executed: $109.75 returned in full. The staff screen that fronts it has not been graded; see document 06. | Architect |

**Diagrams** live in `diagrams\`. Every one is a standalone Scalable Vector
Graphics (SVG) file on a white background with fixed colours, so it drops
straight into Snagit, a document, or a slide without a theme fighting it.

**Figma** material lives in `FIGMA-IMPORT\`, with its own instructions.

---

## The shortest possible summary

Orvanna is a fictional direct-selling company that sells artificial
intelligence (AI) agents. It is Howard's own flagship demonstration project,
built to show a complete, working commerce and compensation system rather than
a mock-up. It is live at https://orvanna.io.

A shopper picks agents, chooses monthly subscription or a one-time purchase,
optionally names the member who referred them, and pays with a card. Behind
that simple screen: prices are recomputed on the server so the browser can
never name its own price, tax is calculated by a real tax engine against a
destination read from the database, the card is authenticated by the shopper's
own bank through three-domain secure (3DS), and the outcome is decided only by
asking the payment service directly, never by trusting the browser.

Nothing about the money is decided in the page. That single principle explains
most of the design decisions in every document here.

---

## Two honesty rules this documentation follows

**A claim that is not verified is labelled as such.** Several past errors on
this project came from a document confidently describing behaviour that the
code did not have. Where these documents describe something as working, it was
checked. Where something is specified but not built, it appears under its own
heading saying exactly that.

**Gaps are named, not omitted.** An untested area that goes unmentioned reads
as covered. Each document ends by saying what it does not cover and what is
still open.
