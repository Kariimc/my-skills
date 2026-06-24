---
name: harness-audit
description: >-
  The Audit Harness — evidence-first inventory of a live surface, severity-ranked
  findings, then code-first fixes. Reads what is actually there (never guesses),
  ranks issues by severity, and proposes concrete remediations. Use when the user
  wants to audit, review, or assess something for problems — security, config,
  agent/LLM architecture, dead code, production readiness, costs, or "what's
  broken / what's redundant / what's missing" in a system.
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Bash, Grep, Glob, Task
---

# Audit Harness

The recurring "don't trust, verify the live surface" pattern. Inventory what
actually exists, rank by severity, fix with code — in that order. Never report a
problem you haven't confirmed against the real artifact.

## When to use
- "Audit / review / assess … for problems."
- Security review, config bloat, agent-stack regressions, dead code,
  production readiness, cost spikes, automation overlap.

## The loop

```
SCOPE → INVENTORY (read live surface) → RANK (severity) → VERIFY → FIX (code-first)
```

### 1. Scope
- Name the target surface precisely (this repo, ~/.claude config, an auth flow,
  a deploy pipeline) and the lens (security / cost / dead code / structure).

### 2. Inventory (evidence-first)
- Read the actual files, configs, logs, and running state. Fan out parallel
  read-only explorers for breadth. Record what's *present*, not what's assumed.

### 3. Rank
- Sort findings by severity (impact × likelihood). Each finding cites the exact
  file:line or command output it came from.

### 4. Verify
- Adversarially confirm each high-severity finding is real before proposing a
  fix — kill false positives early.

### 5. Fix
- Propose minimal, code-first remediations. Flag anything that needs the user's
  call instead of silently changing it.

## Which specialist to route to
- Security → `security-scan`, `security-reviewer` agent, `cybersecurity`.
- Agent/LLM stack → `agent-architecture-audit`.
- Claude config bloat → `config-gc`, `context-budget`, `skill-audit`.
- Dead code → `refactor-cleaner` agent, `finding-duplicate-functions`.
- Production readiness → `production-audit`, `silent-failure-hunter` agent.
- Automation/cost → `automation-audit-ops`, `cost-tracking`.

## Related
`code-review`, `verification-before-completion`.
