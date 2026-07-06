---
name: plan-gate
description: Blocks any edit, command, or build step until a written 5-line plan exists — goal, unknowns, success criteria, step order, rollback. Prevents mid-task scope drift and half-understood changes. Use when starting ANY non-trivial task — code change, refactor, doc, config, migration — before the first edit is made.
---

# Plan-Gate

No edits before a written plan. Five lines, always the same five:

1. **Goal** — one sentence, the outcome not the activity.
2. **Unknowns** — facts you don't have. If the code holds the answer, READ IT NOW.
   If only the user holds it, STOP and ask that one question.
3. **Success criteria** — the observable "done bar." A command whose output proves it.
4. **Step order** — numbered, smallest-change-first.
5. **Rollback** — the one-line undo if step N goes wrong.

Write it, then execute it. If reality diverges from the plan mid-task, STOP,
amend the plan (one line: what changed and why), then continue. Silent divergence
is the failure this skill exists to prevent.

## Worked example — code task
> Task: "fix the miss-can-swish bug in shot.gd"
> 1. Goal: misses never pass through the rim cylinder.
> 2. Unknowns: rim radius constant location → read ball.gd → 0.23. None left.
> 3. Done bar: new test `miss_offset_outside_rim` red on old code, green on fix.
> 4. Steps: (1) polar offset radius ∈ [rim+0.05, 0.40]; (2) test; (3) run suite.
> 5. Rollback: revert the one function; no schema/save-data touched.

## Worked example — docs task
> Task: "write the README for Midnight-return-"
> 1. Goal: a stranger can open and run the project in <10 min.
> 2. Unknowns: Unity version → CLAUDE.md says 2023.2 LTS + HDRP 16. None left.
> 3. Done bar: README covers open/run/layout/state; no claim not verified in-repo.
> 4. Steps: skeleton from CLAUDE.md → verify each claim against Assets/ → prune.
> 5. Rollback: single new file; delete it.

## Failure smell this prevents
Mid-task drift: "while I'm here I'll also refactor X." If X isn't in the plan,
it's a new task — note it, don't do it.
