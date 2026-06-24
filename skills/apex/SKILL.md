---
name: apex
description: >-
  The apex control-plane skill — the supreme, self-enforcing guardrail layer that
  makes the mistakes of the last month structurally impossible and guarantees no
  mistake ever recurs. One prompt installs and arms a tamper-resistant suite of
  gates (commit + push + CI) that self-heal drift, block regressions, guard
  themselves, and grow a new gate from every new mistake (the ratchet). Use when
  the user wants to fortify or lock down the control plane, prevent a class of
  mistakes from ever happening again, audit/repair the guardrails, or run /apex.
metadata:
  origin: authored
  family: ultimate-harness
  rank: apex
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# apex — the supreme control-plane layer

Above the six harnesses and `skill-ship` sits one skill whose only job is to make
sure nothing we got wrong can happen again. A skill you must *remember to run* is
still a thing you can forget; **apex converts every recurring mistake from a rule
you follow into a gate that runs itself.** You invoke it once — after that it
maintains, defends, and extends itself.

## The one prompt
```
/apex            # install, arm, verify the whole guardrail layer (idempotent)
/apex ratchet "<what went wrong>"   # turn a fresh mistake into a permanent gate
```
Mechanically: run `bin/apex.sh` (installer + dashboard) and, for the ratchet,
`bin/apex-ratchet.sh "<mistake>"`.

## Four apex properties
1. **Self-enforcing** — gates run on every commit (`.githooks/pre-commit`), every
   push (`.githooks/pre-push`), and in CI (`.github/workflows/apex.yml`). Local
   hooks are fast feedback; CI makes it true on every machine.
2. **Self-healing** — safe drift (README counts, triage report) is auto-fixed and
   re-staged before a commit can complete. You can't commit drift.
3. **Self-guarding** — the `selfintegrity` gate is the guard that guards the
   guards: if a hook is deleted, the doctor gutted, or `core.hooksPath` un-wired,
   the suite fails. Tamper-resistant by design.
4. **Self-extending** — the **ratchet**. Every mistake that slips through becomes
   a drop-in check under `apex/checks/`, auto-discovered and enforced forever.
   A mistake happens at most once.

## The gates
Defined once in `bin/apex-gates.sh`, declared in [`apex/GATES.md`](../../apex/GATES.md):

| Gate | Prevents |
|---|---|
| `gate_doctor` | stale counts, trigger-less skills, name≠folder, overlap |
| `gate_hooklint` | broken hooks, the heredoc-ate-stdin bug class |
| `gate_secrets` | credentials committed to history |
| `gate_selfintegrity` | the guards being deleted, gutted, or un-wired |
| `gate_extra` | every ratchet-generated check |
| `gate_live` | "is it actually synced & firing?" |

HARD failures block; soft issues warn. The full record of what each gate exists
to stop is in [`apex/MISTAKE-LEDGER.md`](../../apex/MISTAKE-LEDGER.md).

## How "never again" actually works
You cannot pre-list every future mistake — so apex does not try. It guarantees the
weaker-but-real thing: **each mistake is permanent at most once.** The first time
something breaks, `/apex ratchet "…"` captures it and writes a gate; from then on
the layer itself refuses to let it happen. Honest scope: a novel mistake can still
occur once; it can never occur twice.

## Relationship to the rest
`apex` governs the repo that ships everything else. It generalizes `skill-ship`'s
single pre-commit guard into the full multi-point, self-extending suite. Arm it
once with `/apex`; thereafter it is the standing immune system of the control
plane.
