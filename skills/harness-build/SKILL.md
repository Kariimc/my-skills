---
name: harness-build
description: >-
  The Build Harness — turn a feature/app/game/API request into a shipped,
  reviewed change. Drives the full intent → plan → parallel build → review →
  verify → PR loop using the planner, language build-resolvers, language
  reviewers, and verification skills. Use when the user wants to build,
  implement, add, or ship a feature, app, game, utility, endpoint, or any
  non-trivial code change (more than a single-file fix).
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# Build Harness

The IDP build loop, made concrete. Takes an intent and drives it to a reviewed,
verified change. This is the default harness for "build / implement / add / ship".

## When to use
- "Build me a …", "implement …", "add X to …", "ship a …"
- Any multi-file feature, app, game, utility, or API endpoint.

## When NOT to use
- One-line / single-file fixes → just edit directly.
- Visual-quality-critical UI where slop is unacceptable → use `harness-quality`.

## The loop

```
intent → PLAN → BUILD (parallel) → REVIEW → VERIFY → SHIP
   ▲                                              │
   └──────────── on failed gate, re-enter ────────┘
```

### 1. Plan
- Invoke `brainstorming` first if the request is ambiguous (don't assume).
- Use the **planner** / **code-architect** agents (or the `plan-orchestrate`
  / `blueprint` skills for multi-session work) to produce a step list with
  critical files, interfaces, and build order.

### 2. Build (fan out)
- Implement per the plan. For independent steps, dispatch parallel subagents.
- When a build breaks, route to the matching **`*-build-resolver`** agent
  (react / rust / go / java / kotlin / swift / cpp / django / dart / pytorch …)
  for minimal-diff fixes. Detect the stack from the repo first.

### 3. Review (gate)
- Always run `code-review` plus the language-specific reviewer
  (**`typescript-reviewer`**, **`python-reviewer`**, **`go-reviewer`**, etc.).
- Run **`security-reviewer`** on anything touching auth, input, or data.
- A failed review re-enters step 2 — do not ship past an open gate.

### 4. Verify (gate)
- Run `verify` / `test-engineer` to confirm behavior, not just compilation.
- Run `canary-watch` after a deploy.

### 5. Ship
- Branch per repo convention, commit with a clear message, open a PR **only if
  the user asked for one** (otherwise push to the working branch).
- Summarize: what changed, files touched, test results, risks, rollback.

## Quality gates (all must pass before SHIP)
correctness · security · performance · simplicity · loop-integrity.

## Related
`plan-orchestrate`, `software-implementation`, `orch-pipeline`,
`subagent-driven-development`, `verify`, `code-review`.
