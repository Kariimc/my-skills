# 0002 — Where the `.claude/evals` behavior evals run in CI

- **Status:** Accepted
- **Date:** 2026-07-03
- **Deciders:** control-plane owner
- **Grounds:** `.github/workflows/apex.yml`, `.claude/evals/README.md`,
  `.claude/evals/brain-ingest.md`, `.claude/evals/neon-forge-component.md`,
  `bin/eval-router.sh`, `bin/apex-gates.sh`, `apex/GATES.md`, CLAUDE.md (APEX
  layer)

## Context

Two distinct kinds of quality check now live in this repo, and they answer
different questions:

- **apex gates** (`bin/apex-gates.sh all`, mirrored in CI by
  `.github/workflows/apex.yml`) guard the **integrity of the control plane** —
  hooks path intact, metadata in sync, `selfintegrity` guarding the guards. Per
  CLAUDE.md these are the standing immune system: they run on commit + push + CI
  and must not be weakened or routed around. The apex CI job also runs
  `skill-doctor.sh --fix` and fails if it produces any drift (apex.yml
  lines 29–37).
- **behavior evals** (`.claude/evals/`) judge whether **user-facing workflows
  produce good output** — `brain-ingest.md` (4 binary PASS/FAIL data-integrity
  invariants, all 4 must pass) and `neon-forge-component.md` (7 weighted 1-10
  dimensions behind 5 hard code gates, normalized ≥ 8.0 to ship). The router
  eval (`bin/eval-router.sh`, 182 cases) is a third, already fully
  deterministic, behavior eval.

The `.claude/evals/README.md` already lays out a staged path (Now manual →
`bin/run-evals.sh` runner → CI job) and states a guardrail directly: *"Keep
evals out of `apex-gates.sh` itself — apex guards the control plane's integrity;
evals judge feature behavior, a different concern."* The open decision is to
ratify **where** these evals execute in CI: inside the apex gate suite, as a
separate CI job, or manual-only.

## Options

1. **Fold evals into `apex-gates.sh` / the apex job.** One green check to rule
   them all. But it conflates two concerns the README deliberately separates:
   an eval regression (a component scored 7.4 instead of 8.0) would then read as
   a **control-plane integrity failure** and block the trunk exactly like a
   compromised hook. It also risks dragging non-deterministic model-graded
   dimensions and data fixtures into the apex path, whose whole value is being
   fast and deterministic. This is precisely what the README's guardrail
   forbids.

2. **Separate CI job (chosen).** A distinct job/step in CI — parallel to the
   `gates` job, not inside it — runs only the **deterministic, code-graded**
   portions of the evals (router accuracy via `eval-router.sh`; the git-diff /
   secret-scan gates for `brain-ingest`; `typecheck` + `build` +
   slug-uniqueness for `neon-forge-component`). An eval regression shows up
   red on the PR **without** entangling it with apex trunk protection. Model-
   and human-graded dimensions stay advisory (reported, never blocking) so CI
   never hangs on an LLM judge.

3. **Manual / model-graded only (status quo).** Rubrics are the contract; runs
   are recorded in the per-feature `.log` files; nothing gates. Zero CI cost,
   but a router or ingest regression can land unseen — the 182-case eval already
   exists and is a waste if nothing runs it on a PR.

## Decision

**Option 2 — a separate, deterministic-only CI job.** This ratifies the path
already written into `.claude/evals/README.md` step 3. The two check families
stay cleanly separated by concern:

- **apex** (`apex-gates.sh all`, existing `gates` job) — integrity. Untouched.
  Evals are **not** added to `apex-gates.sh`.
- **evals** (new job/step) — behavior. Runs only the deterministic graders:
  - `bash bin/eval-router.sh` (exits nonzero below its accuracy threshold —
    already a drop-in CI gate over 182 cases);
  - the code-graded gates from `brain-ingest.md` and
    `neon-forge-component.md`.

Hard rules carried from the README's guardrails:
- **Only deterministic graders gate.** Model/human graders report, never block —
  CI stays fast and non-flaky (matches the `eval-harness` anti-pattern "no flaky
  graders in release gates").
- Evals run against **throwaway copies / built artifacts** — never mutating the
  real `C:/Dev/brain`, never requiring secrets in CI.
- A failing behavior eval blocks **that PR's eval check**, not the apex trunk-
  protection gate. Someone reading the checks can tell integrity from behavior
  at a glance.

## Consequences

- **Good:** Router/ingest/component regressions become visible on every PR
  without weakening or slowing apex. The separation keeps the "immune system"
  (apex) legible and fast, and lets behavior thresholds evolve independently of
  trunk protection. `eval-router.sh` is already CI-shaped (nonzero exit on
  regression), so the router slice is effectively free to wire up.
- **Cost:** A second CI surface to maintain, and the intermediate
  `bin/run-evals.sh` runner (README step 2) still needs writing to wrap the
  `brain-ingest` / `neon-forge-component` code-graders behind one nonzero-on-
  failure entrypoint. Until that runner lands, only `eval-router.sh` is
  CI-ready; the other two evals remain manual/model-graded.
- **Boundary risk:** Someone will eventually be tempted to "just add the eval to
  apex" for one green check. That is explicitly out of bounds — if evals ever
  need to block the same way apex does, that is a *new* decision, not a quiet
  merge of the two jobs.

## Revisit trigger

Reopen if: the separate eval job proves too easy to ignore (regressions merge
because the eval check isn't required) — in which case make the deterministic
eval job a *required* status check while still keeping it **out of**
`apex-gates.sh`; **or** a genuinely deterministic, secretless, fast grader for a
security-sensitive workflow emerges that has a real case for living in apex
(promote that single grader deliberately, with its own ratchet entry — never the
whole eval suite).
