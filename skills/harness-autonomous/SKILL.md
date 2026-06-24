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

## Related
`autonomous-agent-harness`, `agentic-os`, `continuous-agent-loop`,
`autonomous-loops`. Underlying agent: `loop-operator`.
