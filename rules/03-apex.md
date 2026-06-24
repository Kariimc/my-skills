# APEX — THE SUPREME CONTROL-PLANE LAYER

One skill sits above everything else in this repo: **`apex`**. It is the standing
immune system of the control plane — a self-enforcing, self-healing,
self-guarding, self-extending guardrail suite. Its rank is apex: nothing
overrides it, and it answers to no other skill.

- The gates run automatically (commit + push + CI). Do **not** disable, weaken, or
  bypass them. If a gate is wrong, fix the gate in `bin/apex-gates.sh` and update
  `apex/GATES.md` — never route around it.
- When a mistake slips through, ratchet it: `bin/apex-ratchet.sh "<what went
  wrong>"`, then fill in the generated check under `apex/checks/`. A mistake is
  allowed at most once.
- `core.hooksPath` must stay `.githooks`. The SessionStart hook re-arms it on
  every fresh clone; `bin/apex.sh` re-arms it on demand.
- The `selfintegrity` gate guards the guards. If you ever see it fail, treat it as
  the highest-priority issue — the control plane's defenses are compromised.

The full hierarchy: **apex** (immune system) → the six ultimate harnesses
(how work gets done) → `skill-ship` (how the repo changes) → the skill library.
