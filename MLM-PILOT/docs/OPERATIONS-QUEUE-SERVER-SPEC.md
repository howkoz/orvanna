# Operations queue: what the server must expose

Written 2026-08-18 while building handoff screen `8a`. This is the half of
that screen that could not be built in the browser, and the reason it could
not.

## What 8a asks for

Each attention row carries three things the console does not have:

1. **A severity** — `ACT NOW`, `DECIDE`, `BEFORE CLOSE`.
2. **Money at stake** — a figure per row, summed into the band's
   "money waiting on a decision", which "falls as you clear them".
3. **Exactly one action** — `REQUEST NEW CARD`, `OPEN CASE`,
   `CANCEL OR CONTACT`, `VOID ONE`, `REVIEW ID`, `WRITE NOTE`, `RECLASSIFY`.

## What was built, and what was not

**Built: severity.** It is a policy map over reason classes, in
`staff-operations.html`. Which classes of fault demand a human today is a
decision about classes, not a fact hidden in a row, so it belongs in code we
can read and change rather than in a column. The queue now sorts by it. The
server's own ordering was `order by q.reason, m.member_code`, which is an
ordering with no opinion: it put a cycle gap above a system fault on the
strength of the letter c.

**Not built: money at stake, and the actions.** Both need the server.

`app.v_staff_attention_queue` returns:

```
reason, member_code, subscription_id, renewal_index,
billing_attempt_id, detail, state
```

There is no amount, no deadline and no decline class in it. A money column
filled in by the browser would be a fabricated figure on the one page where
money decides what a human does first, and a Clear button with no audit
endpoint behind it would record nothing while looking like it had. Both are
worse than the empty space, so the space is empty and the page says why.

## The change

### 1. The view exposes consequence

`app.v_staff_attention_queue` gains, per row:

| Column | Type | Source | Notes |
| --- | --- | --- | --- |
| `amount_at_stake` | numeric | the subscription's current price, or the attempt's amount where one exists | null where the row genuinely has no money on it, e.g. a note owed on a superseded trail. Null is not zero and must not print as `0.00`. |
| `deadline_at` | timestamptz | the chargeback respond-by, the pause date, the close of the open month | null where there is no clock. |
| `decline_class` | text | the processor's decline code, mapped | null for reasons that are not declines. |

Nullable throughout, deliberately: a row with no money on it is a real row,
and the console must be able to say "—" rather than invent a zero.

### 2. The action returns them

`actionAttention` in `functions/billing-console/index.ts` selects and returns
the three new columns. Ordering stays as it is — the browser ranks, because
severity is policy.

### 3. Clearing a row writes an audit record

A new `action: 'clear_attention'` taking `{ subscription_id, renewal_index,
reason, note }`, which:

- writes to the audit log against the **operator's member number**, the way
  every other console action already does;
- **moves no money.** Clearing records that a human looked. The design says
  so on the page and it must stay true;
- is idempotent per `(subscription_id, renewal_index, reason)`, so a double
  click cannot write two records;
- returns the re-read row, so the console shows server state rather than
  trusting what it just sent.

Then the console re-reads rather than mutating a local `done` map: the
prototype's local state is a prototype's, and on a console two operators can
be looking at the same queue.

### 4. Both gates before any of it deploys

This touches a live payment rail. `2026-08-16-both-gates-before-deploy`
applies, and the standing debt of five ungated deploys on 08-17 is the reason
to be careful rather than a precedent.
