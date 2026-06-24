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

## Related
`simplify` (slash), `make-interfaces-feel-better`, `finding-duplicate-functions`.
Underlying agents: `code-simplifier`, `refactor-cleaner`, `type-design-analyzer`.
