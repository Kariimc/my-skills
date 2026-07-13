---
name: harness-quality
description: >-
  The Quality (GAN) Harness — generate ↔ adversarially evaluate ↔ iterate until
  output clears a strict rubric. A separate ruthless evaluator critiques the
  generator's work each round, driving quality past what one agent self-rating
  ever reaches. Use when the user wants production-quality, polished, or
  high-craft output and "AI slop" is unacceptable — beautiful UIs, refined copy,
  or any deliverable with a scorable quality bar.
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# Quality (GAN) Harness

Generation and evaluation are split into adversaries. Agents are pathological
optimists about their own work; a *separate* evaluator engineered to be strict
is far more reliable than teaching a generator to self-critique. Loop until the
evaluator — not the generator — says it passes.

## When to use
- Production-quality / polished / high-craft output is the goal.
- Visual UI work where templated "AI slop" is unacceptable.
- Any deliverable with a definable, scorable rubric.

## When NOT to use
- Quick fixes or well-specified tasks with existing tests → `harness-build`.
- Tight token budget — this loop spends to reach quality.

## The loop

```
PLAN → ┌─ GENERATOR ──build──▶ artifact ─┐
       │      ▲                          │
       │   feedback                      ▼
       └─ EVALUATOR ◀──score/test── (live)
   repeat until score ≥ threshold for N consecutive rounds
```

### 0. Pick the agents (each run — ask first, dispatch nothing until answered)
Before any generate/evaluate round, ask the user which agents to use — one
question for the generator (worker), one for the evaluator (judge). Recommended
(first) pick: generator = Sonnet 5 (high); evaluator = Opus 4.8 (high) or Fable 5
(low). Same on every surface — Claude chat (incl. Windows) and Claude CLI.

### 1. Plan
- Use the **gan-planner** agent (or `brainstorming`) to expand the one-line
  prompt into a spec: features, sprints, **explicit evaluation criteria**, and
  design direction. The rubric is the contract — write it down first.

### 2. Generate
- Use the **gan-generator** agent to implement against the spec and to read and
  act on the previous round's evaluator feedback.

### 3. Evaluate (adversarial)
- Use the **gan-evaluator** agent to test the *live running* artifact and score
  it against the rubric — instructed to refute, not to praise. For UI, that
  means driving the actual app (Playwright), not reading code.
- For non-UI work, fan out 3 independent evaluators with distinct lenses and
  require a majority pass.

### 4. Iterate
- Feed the evaluator's findings back to the generator. Repeat until the score
  clears the threshold for N consecutive rounds (loop-until-dry), then stop.

## Output contract

Before generating anything, the rubric must exist as a table — this IS the
contract; without it the loop cannot terminate:

```
| Dimension | Weight | 1-10 score meaning | Threshold |
```

Every round reports one line per dimension plus the verdict:
`ROUND <n>: total <x>/10 vs threshold <t> → CONTINUE|PASS(<n> consecutive)`

Final report:

```
RESULT:  PASS after <n> rounds (scores: <dim=score, ...>)
ARTIFACT: <path/URL of the final artifact>
EVAL LOG: <one line per round: round, total, top deficiency fixed>
RESIDUAL: <what still scores lowest and why it's acceptable>
```

Worked example verdict line:
`ROUND 3: total 8.4/10 vs 8.0 → PASS(2 consecutive) — motion=9 distinctiveness=8 copy=8`

The evaluator's score is the only one that counts. A generator claiming
quality without an evaluator round is a contract violation — re-run the loop.

## Subagent protocol (all dispatches)
- **Refusals escalate, never re-route.** A subagent safety refusal is returned
  verbatim to the operator/user; NEVER rephrase, split, or retry the request to
  get around it. Log it as `BLOCKED-SAFETY: <task>` and continue other lanes.
- **Artifacts, not claims.** A subagent's "done" counts only with pasted command
  output / diff / URL. No artifact → treat as not done, one revise cycle.
- **Two revisions, then up.** A subtask failing its gate twice escalates to the
  operator with the failing evidence — never a third silent retry.

## Related
`gan-style-harness` (full reference), `eval-harness`,
`agent-self-evaluation`, `benchmark-optimization-loop`. Underlying agents:
`gan-planner`, `gan-generator`, `gan-evaluator`.
