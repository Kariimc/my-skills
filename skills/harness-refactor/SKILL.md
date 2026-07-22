---
name: harness-refactor
description: >-
  The Refactor/Simplify Harness — improve the shape of existing code without
  changing its behavior. Baselines behavior, finds duplication / dead code /
  needless complexity, refactors in small reversible steps, and verifies
  behavior is unchanged after each one. Use when the user wants to refactor,
  simplify, clean up, deduplicate, consolidate, or remove dead code — any
  structure-only change where the cardinal rule is "behavior must not change".
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# Refactor / Simplify Harness

Change the shape, never the behavior. Every step is small, reversible, and
gated by a behavior check — so the code gets cleaner while staying correct.

## When to use
- "Refactor / simplify / clean up / tidy this …"
- "Remove dead code", "deduplicate", "consolidate these", "reduce complexity".

## When NOT to use
- New behavior or features → `harness-build`.
- *Finding* problems without fixing them (read-only) → `harness-audit`.

## The loop

```
BASELINE → IDENTIFY → REFACTOR (small step) → VERIFY (behavior unchanged) → repeat
   ▲                                                    │ behavior drifted?
   └────────────────── revert the step ─────────────────┘
```

### 1. Baseline behavior
- The non-negotiable first step. Ensure there are tests that pin current
  behavior; if coverage is thin, write characterization tests **first** (use
  `test-engineer` / TDD) so you can prove nothing changed.

### 2. Identify
- Duplication → `finding-duplicate-functions` (semantic dupes, not just text).
- Dead/unused code → **refactor-cleaner** agent (knip / depcheck / ts-prune).
- Needless complexity / weak abstractions → `simplification-cascades`,
  **code-simplifier** agent, **type-design-analyzer** agent.

### 3. Refactor in small steps
- One behavior-preserving transformation at a time (extract, inline, rename,
  dedupe, delete). Keep each step independently revertible — never bundle a
  refactor with a behavior change.

### 4. Verify (gate)
- Run the baseline tests after each step. Green → keep. Red → revert that step
  and rethink. Optionally run `code-review` on the diff to confirm it's
  structure-only.

### 5. Stop
- Stop when the targeted smell is gone — refactoring has no natural "done", so
  bound it to the goal you started with. Don't gold-plate.

## Output contract

"Behavior unchanged" is evidenced, never asserted:

```
BASELINE: <test command + count green before any change>
STEPS:    <n> transformations, each named (extract/inline/dedupe/delete) + LOC delta
VERIFY:   <same test command + count green after — identical count or explained>
REVERTED: <steps rolled back mid-run, or "none">
SMELL:    <the targeted smell> → <gone|reduced, with the measurement>
```

Worked example:
`BASELINE: pytest -q → 47 passed · STEPS: 4 (extract crowd_bowl, extract spawner, dedupe texture-load, delete dead GameState wire) −212 LOC · VERIFY: pytest -q → 47 passed · REVERTED: none · SMELL: main.gd god-object → 430→61 lines`

## Subagent protocol (all dispatches)
- **Pick agents first (each run).** Before dispatching, ask the user which agents
  to use — one question for the workers, one for the judge/verifier — and
  dispatch nothing until they answer. Recommended (first) pick: workers =
  Sonnet 5 (high); judge/verify = Opus 4.8 (high) or Fable 5 (low). Same on
  every surface — Claude chat (incl. Windows) and Claude CLI.
- **Refusals escalate, never re-route.** A subagent safety refusal is returned
  verbatim to the operator/user; NEVER rephrase, split, or retry the request to
  get around it. Log it as `BLOCKED-SAFETY: <task>` and continue other lanes.
- **Artifacts, not claims.** A subagent's "done" counts only with pasted command
  output / diff / URL. No artifact → treat as not done, one revise cycle.
- **Two revisions, then up.** A subtask failing its gate twice escalates to the
  operator with the failing evidence — never a third silent retry.

## Related
`simplify` (slash), `make-interfaces-feel-better`, `finding-duplicate-functions`.
Underlying agents: `code-simplifier`, `refactor-cleaner`, `type-design-analyzer`.

## Worker contract & fidelity gate (mandatory)

Prepend `skills/AGENT-CONTRACT.md`'s CONTRACT block verbatim to every worker
subagent prompt — workers never saw the global rules and start cold without it.
On receiving each worker's output, score it with the `agent-evaluator` agent
with **fidelity as the first axis** (everything asked present? anything present
that was NOT asked?); freelanced output is rejected and re-dispatched with the
deviation named. Before the final deliverable reaches Kariim, dispatch the
`deliverable-verifier` agent on the actual artifacts — its PASS is the finish
line, not the builder's self-assessment.
