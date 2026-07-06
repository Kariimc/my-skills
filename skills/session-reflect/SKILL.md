---
name: session-reflect
description: A three-phase structured retrospective (durable facts, corrections, reusable workflows) that goes deeper than a routine handoff write and proposes new standing rules — never auto-applying them. Complements project-context-loader's routine PROGRESS.md handoff rather than replacing it. Use when the user explicitly asks to reflect, debrief, or "capture what we learned" from a session, or when the same correction has now repeated across sessions and needs escalating into a proposed rule.
---

# Session-Reflect

Run at session end. Three phases, in order, output appended to the repo's
PROGRESS.md (house format: where-we-are / done / user-gated / gotchas).

**Phase 1 — Durable facts.** What did this session establish that a future
session must not rediscover? (Versions, paths, constants, environment quirks,
"X is actually Y.") → PROGRESS.md `## Machine gotchas` or `## Where we are`.

**Phase 2 — Corrections.** Every place the user corrected me, or reality
corrected the plan. Each correction is a candidate STANDING RULE — phrase it as
one imperative line. → List them under `## Proposed rules (user approval needed)`.
NEVER write directly into rules/ — the user promotes; I propose. One correction
appearing twice across sessions = escalate the proposal to the top of the list.

**Phase 3 — Workflows worth keeping.** Any sequence I'd repeat (a debug recipe,
a verification ritual, a data pull). If it's ≥3 steps and likely to recur,
propose it as a skill (`/new-skill` candidate) in one line: name + trigger.

**Output contract:** a single PROGRESS.md diff, nothing else. If nothing durable
emerged, write exactly one line saying so — an empty reflection honestly reported
beats invented lessons.
