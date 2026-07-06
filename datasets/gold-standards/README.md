# Gold Standards

Fable-5 reference answers on real tasks from this portfolio, captured 2026-07-06
while Fable was subscription-included. `bin/eval-models.sh` grades candidate
models against them; ≥8/10 on a task = "Fable parity" there.

Layout: one dir per task — `prompt.md` (sent verbatim to the candidate),
`gold.md` (Fable's reference), `rubric.md` (5 dimensions × 0–2, judge-facing).
Runs land in `runs/<date>/`, committed, so history shows model progress.
Grow the set from real PRs with executable done-bars; keep tasks ≤1 screen.
