---
name: harness-autonomous
description: >-
  The Autonomous-Ops Harness — a persistent loop with memory and a schedule that
  keeps working between sessions. Wires crons, task queues, file-based memory,
  and a quality gate into a self-directing agent that runs on an interval and
  recovers from stalls. Use when the user wants continuous or scheduled
  operation, a recurring/looping task, monitoring, or an agent that keeps making
  progress on its own and remembers context across sessions.
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# Autonomous-Ops Harness

The "Claude that keeps working between sessions" pattern: loop + memory +
schedule + quality gate + recovery. This repo's own SessionStart sync hook is a
tiny instance of it; this harness generalizes it to real recurring work.

## When to use
- "Keep working on …", "run this every N minutes", "monitor X", "on a schedule".
- Long-running goals that outlast a single session.

## When NOT to use
- One-off tasks → use the matching harness directly and stop.

## The loop

```
WAKE (cron) → LOAD memory → pick next task → DO → GATE → WRITE memory → SCHEDULE next
                  ▲                                                          │
                  └──────────────────────── on stall, recover ──────────────┘
```

### 1. Schedule
- Use crons (`CronCreate`) for fixed intervals, or `ScheduleWakeup` / the
  `/loop` skill for self-paced ticks. Pick the cadence from what actually
  changes — don't poll faster than the world moves.

### 2. Memory
- Persist state to disk so the next wake has context: `ck` for per-project
  memory, `remembering-conversations` to recover prior sessions, plain files
  for a task queue / blackboard. Never rely on in-context memory across wakes.

### 3. Act + gate
- Each tick: load state → pick the next task → execute (often via another
  harness) → run a quality gate before committing the result.

### 4. Recover
- Detect stalls (no progress for K ticks) and intervene via the
  **loop-operator** agent. Always have an explicit termination condition —
  no unbounded loops.

## Output contract

Every wake writes exactly one report line to the run log (file-based memory),
even when nothing happened — silence is indistinguishable from a crash:

`WAKE <iso-ts>: picked=<task|none> did=<one line> gate=<pass/fail+evidence> next=<iso-ts> state=<progress|stalled(k)|done>`

Worked example:
`WAKE 2026-07-07T08:00: picked=brief did=wrote PROGRESS summary, 3 repos gate=pass(file exists, 41 lines) next=2026-07-08T08:00 state=progress`

Hard rules: `stalled(k)` at k≥3 triggers the recover step, k≥5 notifies the
user and pauses the schedule — an autonomous loop that can only fail loudly.
`done` requires the explicit termination condition, quoted.

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
`autonomous-agent-harness`, `agentic-os`, `continuous-agent-loop`.
Underlying agent: `loop-operator`.

## Worker contract & fidelity gate (mandatory)

Prepend `skills/AGENT-CONTRACT.md`'s CONTRACT block verbatim to every worker
subagent prompt — workers never saw the global rules and start cold without it.
On receiving each worker's output, score it with the `agent-evaluator` agent
with **fidelity as the first axis** (everything asked present? anything present
that was NOT asked?); freelanced output is rejected and re-dispatched with the
deviation named. Before the final deliverable reaches Kariim, dispatch the
`deliverable-verifier` agent on the actual artifacts — its PASS is the finish
line, not the builder's self-assessment.
