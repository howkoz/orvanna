# 008_comp_engine (pointer)

The live migration ledger entry `008_comp_engine_v12` (and its v1.3 successor) was
applied from `..\comp\001_comp_engine.sql`, which is the canonical home of the engine
source. This pointer exists so a rebuild from the repository can reproduce the live
ledger without relying on the comp README's run-order table alone (quality assurance
finding QA-L4, Phase 3 gate, 2026-08-13). Run order for a fresh environment:
migrations 001 through 007 here, then ..\comp\001_comp_engine.sql, then data loaders,
then runs.
