---
description: End-of-session retrospective — capture durable facts, turn corrections into proposed standing rules, and flag workflows worth keeping. Writes one PROGRESS.md diff; never edits rules/ itself.
---

Run the `session-reflect` skill on this session. If the skill is loaded, follow
it exactly. If it is not loaded, run the same three phases below.

Scope: this session's transcript. `$ARGUMENTS`, if given, narrows the reflection
to that topic.

**Phase 1 — Durable facts.** What did this session establish that a future
session must not rediscover? (Versions, paths, constants, environment quirks,
"X is actually Y.") → PROGRESS.md `## Machine gotchas` or `## Where we are`.

**Phase 2 — Corrections.** Every place the user corrected me, or reality
corrected the plan. Each correction is a candidate STANDING RULE — phrase it as
one imperative line. → List them under `## Proposed rules (user approval needed)`.
NEVER write into `rules/` — the user promotes; I propose. A correction that has
now appeared twice across sessions goes to the top of the list.

**Phase 3 — Workflows worth keeping.** Any sequence I'd repeat (a debug recipe,
a verification ritual, a data pull). If it's ≥3 steps and likely to recur,
propose it as a skill (`/new-skill` candidate) in one line: name + trigger.

**Output contract:** a single PROGRESS.md diff, nothing else. If nothing durable
emerged, write exactly one line saying so — an empty reflection honestly reported
beats invented lessons.
