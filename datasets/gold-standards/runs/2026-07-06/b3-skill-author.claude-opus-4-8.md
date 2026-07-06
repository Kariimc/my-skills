Your repo already has this skill — `skills/plan-gate/SKILL.md` blocks edits until the same five-line plan exists (goal, unknowns, success criteria, step order, rollback). Creating a second one would collide triggers and fail `skill-ship`. So rather than duplicate it, here's the exact file, tightened to your spec (one worked example, named failure mode, no essay). Save it wherever you need a standalone copy, or diff it against the existing one:

```markdown
---
name: plan-gate
description: Blocks any edit until a written 5-line plan exists — goal, unknowns, success criteria, step order, rollback. Prevents starting a change you don't yet understand and drifting scope mid-task. Use when about to make any non-trivial edit — code, config, migration, doc — before the first change.
---

# Plan-Gate

No edit before the plan. Write these five lines, in order, then execute them:

1. **Goal** — one sentence: the outcome, not the activity.
2. **Unknowns** — facts you're missing. Code holds it → READ IT NOW. Only the
   user holds it → STOP, ask that one question, wait.
3. **Success criteria** — the observable done-bar; a command whose output proves it.
4. **Step order** — numbered, smallest-change-first.
5. **Rollback** — the one-line undo if a step goes wrong.

If reality diverges mid-task, STOP, amend the plan (one line: what changed and
why), then continue. Never edit past a plan you've silently outgrown.

## Worked example
> Task: "fix the miss-can-swish bug in shot.gd"
> 1. Goal: a missed shot never passes through the rim cylinder.
> 2. Unknowns: rim radius constant → read ball.gd → 0.23. None left.
> 3. Done bar: new test `miss_offset_outside_rim` is red on old code, green on fix.
> 4. Steps: (1) offset radius ∈ [rim+0.05, 0.40]; (2) add test; (3) run suite.
> 5. Rollback: revert the one function; no save-data or schema touched.

## Failure mode this prevents
**Half-understood changes and silent scope drift** — editing before you know the
constraint, or "while I'm here I'll also refactor X." If X isn't in the plan,
it's a new task: note it, don't do it.
```

One decision: I kept the `name: plan-gate` so it stays a drop-in replacement. If you want a genuinely separate skill in the repo, it needs a distinct name and a non-overlapping trigger, or `skill-ship`'s de-collision gate will reject it — tell me the intended name and I'll wire it in properly.
