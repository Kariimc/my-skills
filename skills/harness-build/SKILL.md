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

## Output contract

The harness's final report MUST be exactly this shape — no extra prose:

```
SHIPPED: <one line — what now exists and where (branch/PR/paths)>
CHANGED: <file list with one-phrase purpose each>
GATES:   correctness=<pass/fail+evidence> security=<..> simplicity=<..>
VERIFY:  <the actual command run and its real output line — not "tests pass">
RISKS:   <known risks + rollback step, or "none">
```

Worked example (real shape, minimal case):

```
SHIPPED: /export endpoint on branch feat/export (PR #12, draft)
CHANGED: api/export.ts (new route), api/router.ts (mount), export.test.ts (4 cases)
GATES:   correctness=pass(4/4 tests) security=pass(no input reaches shell) simplicity=pass(no new deps)
VERIFY:  `npm test -- export` → "4 passed, 0 failed"
RISKS:   large exports unpaginated — follow-up issue #13; rollback = revert PR
```

If any gate fails, STOP and report `BLOCKED at <gate>: <evidence>` instead of
shipping — a mid-tier model must never improvise past a failed gate.

## Subagent protocol (all dispatches)
- **Refusals escalate, never re-route.** A subagent safety refusal is returned
  verbatim to the operator/user; NEVER rephrase, split, or retry the request to
  get around it. Log it as `BLOCKED-SAFETY: <task>` and continue other lanes.
- **Artifacts, not claims.** A subagent's "done" counts only with pasted command
  output / diff / URL. No artifact → treat as not done, one revise cycle.
- **Two revisions, then up.** A subtask failing its gate twice escalates to the
  operator with the failing evidence — never a third silent retry.

## Related
`plan-orchestrate`, `software-implementation`, `orch-pipeline`,
`subagent-driven-development`, `verify`, `code-review`.
