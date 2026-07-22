---
name: continuous-agent-loop
description: Quality-gate, eval-checkpoint, and recovery-control patterns for autonomous agent loops. Use when the user is wiring guardrails — eval checkpoints, exit conditions, failure recovery — into an autonomous loop. To run a loop prefer harness-autonomous.
metadata:
  origin: ECC
---

# Continuous Agent Loop

This is the canonical loop skill name. It supersedes the retired `autonomous-loops` skill.

## Loop Selection Flow

```text
Start
  |
  +-- Need strict CI/PR control? -- yes --> continuous-pr
  |
  +-- Need RFC decomposition? -- yes --> rfc-dag
  |
  +-- Need exploratory parallel generation? -- yes --> infinite
  |
  +-- default --> sequential
```

## Combined Pattern

Recommended production stack:
1. RFC decomposition (`ralphinho-rfc-pipeline`)
2. quality gates (`plankton-code-quality` + `/quality-gate`)
3. eval loop (`eval-harness`)
4. session persistence (`nanoclaw-repl`)

## Failure Modes

- loop churn without measurable progress
- repeated retries with same root cause
- merge queue stalls
- cost drift from unbounded escalation

## Recovery

- freeze loop
- run `/harness-audit`
- reduce scope to failing unit
- replay with explicit acceptance criteria
