# `.claude/evals/` — scored acceptance rubrics for user-facing workflows

Durable, runnable evals for this control plane. Each file here defines **what
"good" looks like** for one workflow *and* how to check it — a rubric with a
concrete pass threshold, not prose. The rule of the house (per `eval-harness`):
an eval must define expected behavior **and** be executable. No stubs.

## The convention

This directory implements the **`eval-harness`** skill's layout. One rubric per
feature, named for the feature:

```
.claude/evals/
  <feature>.md      # the scored definition — dimensions, thresholds, test cases, how-to-run
  <feature>.log     # append-only run history (per-run scores / PASS-FAIL), created on first run
  README.md         # this file
```

- `<feature>.md` is authored **before or alongside** the feature and is a
  first-class, version-controlled artifact — evals live with the code they judge.
- `<feature>.log` accumulates run results over time so regressions are visible.
  It doesn't exist until a run appends to it.
- Grader tiers (from `eval-harness`): **code** graders (deterministic — git diff,
  grep, `bun run build`) run first and can veto; **model** graders (LLM-as-judge
  against the written rubric) handle taste/quality judgments; **human** review is
  the backstop for security-sensitive calls.

## Two scoring shapes, by what the workflow needs

Correctness workflows and quality workflows are scored differently on purpose:

| Rubric | Shape | Threshold | Why this shape |
|---|---|---|---|
| [`brain-ingest.md`](./brain-ingest.md) | 4 binary PASS/FAIL invariants | **all 4 PASS** (`pass^4 = 1.00`) | Data-integrity path — a mis-file or a leaked secret is disqualifying; there's no "80% correct" for append-only archival. |
| [`neon-forge-component.md`](./neon-forge-component.md) | 7 weighted 1-10 dimensions behind 5 hard code gates | normalized **≥ 8.0** to ship; 6.0-7.99 **revise** | Component quality is taste + correctness; unit tests can't capture "looks AI-made," so it's a GAN-style scored rubric with hard gates that can veto the score. |

Both borrow the repo's existing conventions: `pass@k` / `pass^k` from
`eval-harness`, and the weighted-1-10-dimensions-with-a-threshold pattern from
`gan-style-harness` / `harness-quality` (whose default pass threshold is 7.0).

## Running an eval today

Each rubric carries its own **How to run** section — start there. In short:

- **`brain-ingest`** — copy the brain to a throwaway dir so the eval never
  mutates the real `C:/Dev/brain`, drop the fixture for a test case, run the
  ingest skill against the copy, then grade with the git-diff / secret-scan
  commands in the rubric (code graders) plus a model grader for distill-quality
  and the rotate-flag check.
- **`neon-forge-component`** — build the candidate via the `neon-forge-ui`
  skill's 4-file flow, run the hard gates (`bun run typecheck && bun run build`,
  slug-uniqueness grep, `wrangler dev` on `:8787`), and if they pass, score the
  seven dimensions against the live component with a `gan-evaluator` subagent.

Runs are graded manually or by a model-grader subagent for now, and each appends
a line to the matching `<feature>.log`.

## Wiring into CI over time

These are written to be **promotable to CI without a rewrite** — the code-graded
gates are already plain shell. Intended path:

1. **Now — manual / model-graded.** Rubrics are the contract; runs are recorded
   in the `.log` files. No gate blocks a commit yet.
2. **Next — a runner script.** Add `bin/run-evals.sh` that executes the
   code-graded portions (git-diff and secret-scan for `brain-ingest`;
   `typecheck` + `build` + slug-uniqueness for `neon-forge-component`) and exits
   non-zero on failure. The model-graded dimensions stay advisory (reported, not
   blocking) so CI never hangs on an LLM judge — matching the `eval-harness`
   anti-pattern "no flaky graders in release gates."
3. **Then — CI job.** The apex CI (`.github/workflows/apex.yml`) currently runs
   `bin/apex-gates.sh all`. The deterministic eval runner can be added as a
   separate, non-apex job (or a step) so an eval regression is visible on a PR
   **without** entangling it with the apex trunk-protection gates. Keep evals out
   of `apex-gates.sh` itself — apex guards the control plane's integrity; evals
   judge feature behavior, a different concern.
4. **Release snapshots.** Per `eval-harness`, capture a
   `docs/releases/<version>/eval-summary.md` when a batch of eval runs backs a
   release, so pass rates are pinned to a version.

Guardrails when wiring CI:
- Only **deterministic** graders gate. Model/human graders report but never
  block, so CI stays fast and non-flaky.
- Evals run against **throwaway copies / built artifacts**, never mutating real
  data (`C:/Dev/brain`) or requiring secrets in CI.
- A new user-facing workflow that ships without a rubric here is itself an
  eval-coverage gap — add the `<feature>.md` in the same change.

## Adding a new eval

1. `cp` the closest-shaped existing rubric (`brain-ingest.md` for a
   correctness/PASS-FAIL workflow, `neon-forge-component.md` for a
   quality/scored one).
2. Ground every criterion in the **real** code/skill it judges — read the source,
   don't invent behavior. Cite what you read.
3. Give it a **concrete pass threshold**, at least 3 test cases (for correctness
   rubrics) or explicit hard gates + weighted dimensions (for quality rubrics),
   and a **How to run** section whose code-graded parts are copy-pasteable shell.
4. Add a row to the table above.
