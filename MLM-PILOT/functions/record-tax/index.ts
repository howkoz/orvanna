/* ============================================================
   record-tax (Supabase Edge Function, Deno)

   Turns a Stripe Tax CALCULATION into a Stripe Tax TRANSACTION for
   every order that has actually been paid.

   WHY THIS IS ITS OWN FUNCTION.

   A calculation is a quote: it is what tells the shopper the figure
   at checkout. A transaction is the record that a sale happened,
   and it is what tax reports are built from. Liability is assumed
   when the sale COMPLETES, so this can only run after a payment
   succeeds.

   It is deliberately NOT inside the payment path. If Stripe is slow
   or unreachable, that is a bookkeeping problem, and a shopper whose
   money has already moved should not be left watching a spinner
   because of it. Recording is also naturally retryable, and the
   payment path is not. Separating them means a failure here costs a
   later retry rather than a broken receipt.

   IDEMPOTENT BY CONSTRUCTION, three ways over:
     - it only selects rows with a calculation and no transaction
     - it writes the transaction id back immediately
     - Stripe itself refuses a duplicate reference, and our order
       number is unique by construction, so even a double run cannot
       record the same sale twice

   It takes no input and returns counts only. Nothing it returns
   identifies an order, so it is safe to call from a browser: the
   worst a caller can do is ask us to do our own bookkeeping.

   Secrets: STRIPE_SECRET_KEY only, via Deno.env.get.
   ============================================================ */

import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

const STRIPE_TRANSACTION_URL =
  "https://api.stripe.com/v1/tax/transactions/create_from_calculation";

/* Bounded on purpose. A run is a background chore, not a batch job,
   and an unbounded loop against a third party is how a demo turns
   into an outage. Anything not taken this run is taken by the next. */
const MAX_PER_RUN = 10;

const PRODUCTION_ORIGIN = "https://orvanna.io";
const LOCALHOST_RE = /^http:\/\/localhost(:\d+)?$/;
const LOOPBACK_RE = /^http:\/\/127\.0\.0\.1(:\d+)?$/;

function isAllowedOrigin(origin: string | null): boolean {
  if (!origin) return false;
  return (
    origin === PRODUCTION_ORIGIN ||
    LOCALHOST_RE.test(origin) ||
    LOOPBACK_RE.test(origin)
  );
}

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin");
  if (!isAllowedOrigin(origin)) return {};
  return {
    "Access-Control-Allow-Origin": origin as string,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, apikey, x-client-info, content-type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

let pool: Pool | null = null;
function getPool(): Pool {
  if (pool === null) {
    const dbUrl = Deno.env.get("SUPABASE_DB_URL");
    if (!dbUrl) throw new Error("SUPABASE_DB_URL is not set");
    pool = new Pool(dbUrl, 2, true);
  }
  return pool;
}

interface Outstanding {
  order_number: string;
  tax_calculation_id: string;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(req) });
  }
  if (!isAllowedOrigin(req.headers.get("origin"))) {
    return new Response(
      JSON.stringify({ error: { code: "origin_not_allowed", message: "This demo only answers its own site." } }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) {
    return new Response(
      JSON.stringify({ recorded: 0, skipped: 0, note: "not_configured" }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders(req) } },
    );
  }

  const client = await getPool().connect();
  let recorded = 0;
  let failed = 0;
  try {
    /* A calculation expires after 90 days. One older than that can
       never be recorded, so it is left alone rather than retried
       forever; the tax_source column still says where the figure
       came from, which is the fact that matters on the order. */
    const outstanding = await client.queryObject<Outstanding>(
      `select order_number, tax_calculation_id
         from app.demo_orders
        where payment_status = 'succeeded'
          and tax_calculation_id is not null
          and tax_transaction_id is null
          and created_at > now() - interval '80 days'
        order by created_at asc
        limit ${MAX_PER_RUN}`,
    );

    for (const row of outstanding.rows) {
      const form = new URLSearchParams();
      form.set("calculation", row.tax_calculation_id);
      /* The order number IS the reference. Stripe requires it to be
         unique across all transactions and reversals, and ours
         already is, so no second identifier is invented. */
      form.set("reference", row.order_number);

      let resp: Response;
      try {
        resp = await fetch(STRIPE_TRANSACTION_URL, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${key}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: form.toString(),
          signal: AbortSignal.timeout(8_000),
        });
      } catch {
        failed++;
        continue; /* left outstanding; the next run takes it */
      }

      if (!resp.ok) {
        /* Log the status only, never the body. A 400 here usually
           means the calculation expired or the reference was already
           used, and the next run will re-read the row either way. */
        console.error(
          `record-tax: Stripe returned ${resp.status} for ${row.order_number}`,
        );
        failed++;
        continue;
      }

      const tx = (await resp.json()) as { id?: string };
      if (!tx.id) {
        failed++;
        continue;
      }

      /* Guarded: only fills a row that is still unrecorded, so two
         runs racing cannot overwrite each other's work. */
      await client.queryArray(
        `update app.demo_orders
            set tax_transaction_id = $1, tax_transaction_at = now()
          where order_number = $2
            and tax_transaction_id is null`,
        [tx.id, row.order_number],
      );
      recorded++;
    }

    return new Response(
      JSON.stringify({ recorded, failed, considered: outstanding.rows.length }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders(req) } },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`record-tax: unexpected error: ${message}`);
    return new Response(
      JSON.stringify({ error: { code: "internal_error", message: "Could not record tax transactions right now." } }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders(req) } },
    );
  } finally {
    client.release();
  }
});
