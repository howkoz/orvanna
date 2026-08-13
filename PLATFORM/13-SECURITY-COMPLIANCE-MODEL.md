# Orvanna - Security and Compliance Model

**Plain path:** `C:\Users\howar\Desktop\Desktop\CLAUDE-WORK\payment-projects\ORCHESTRATOR + VAULT + 3DS\ORCHESTRATOR\ORVANNA\13-SECURITY-COMPLIANCE-MODEL.md`
**Built:** 2026-06-15 | Stage 1 | Builds on the vault boundary in `08`

> House style: PART 1 see it, PART 2 the words. The big move: the neutral vault holds the card data,
> so the core stays out of the heaviest PCI scope.

---

# PART 1 - SEE IT

## Where the card data is (and is not)

```
   +============ Orvanna core ============+        +======== NEUTRAL VAULT ========+
   |  references only, no card numbers      | <----> |  the real PAN + token         |
   |  LIGHT PCI scope                       |   ref  |  HEAVY PCI scope lives HERE    |
   +========================================+        +===============================+
   The vault provider carries the hardest compliance load. We shrink ours by never holding the PAN.
```

## The layers of protection

| Layer | What it does |
|-------|--------------|
| Tokenization | the core works with tokens / references, not card numbers |
| Encryption | data encrypted in transit and at rest, everywhere |
| Access + roles | who can see or change what, least privilege |
| Audit trail | every console change and data access is logged |
| Residency | required data stays in-country where a law demands (see `12`) |
| 3DS | shifts fraud liability and meets regional auth mandates (see `09`) |

## Who is responsible for what

```
   VAULT provider   ─►  protecting stored card data (heaviest PCI duty)
   Orvanna        ─►  references only, access control, audit, secure transit
   PROCESSORS       ─►  their own PCI duty on their side
   Orvanna owner  ─►  governance: roles, reviews, keeping it healthy
```

---

# PART 2 - THE WORDS

## The core idea: shrink the scope

PCI compliance is heaviest wherever real card numbers live. Orvanna's design keeps the real card
number out of the core entirely: the core holds references, and the neutral vault holds the PAN and
the token. That single boundary moves the hardest part of the compliance burden onto the vault
provider, which is built and certified for exactly that. We still have real duties, but a much
lighter scope than a system that stored cards itself.

## The protection layers

- **Tokenization.** The core handles tokens and references, never raw card numbers, so even a breach
  of the core would not expose card data.
- **Encryption.** Everything is encrypted in transit and at rest, end to end.
- **Access and roles.** Least privilege: people and services can only see and do what their role
  needs. This governs who may change routing rules in the console.
- **Audit trail.** Every configuration change and every access to sensitive data is logged, so there
  is always an answer to "who changed what, when."
- **Residency.** Where a law requires it, the required data stays in-country (the regional model in
  `12`).
- **3DS.** Authentication shifts fraud liability to the issuer when it succeeds and satisfies
  regional mandates (the 3DS model in `09`).

## Who is responsible for what

Security is shared and the boundaries are clear. The **vault provider** carries the heaviest PCI
duty, protecting stored card data. **Orvanna** handles references, access control, audit, and
secure transport, and never stores a PAN. The **processors** carry their own PCI duty on their side.
And the **owner** carries governance: setting roles, running reviews, and keeping the system healthy,
which is the human duty that no design can replace.

## The honest part

A clean design shrinks the burden but does not erase it. Compliance is an ongoing discipline:
certifications get renewed, access gets reviewed, logs get watched. This is part of the real cost of
running a payments platform, and the build and cost models name it rather than pretending it is free.

## What this hands to the next steps

- **Observability** (14) is where audit and access logs are watched in practice.
- The **cost and team model** (16) prices compliance as an ongoing line, not a one-time task.
- The **risk register** (19) lists the specific compliance risks and their owners.
