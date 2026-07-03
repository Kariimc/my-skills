# `adr/` — Architecture Decision Records for the control plane

Durable records of **decisions actually made** about how this repo (the skill
library + its control plane) is built. Not surveys, not options papers: each
file states a decision, the options weighed, the consequences accepted, and the
concrete signal that would make us reopen it.

## The convention

- **One decision per file**, numbered and slugged: `NNNN-short-slug.md`
  (`0001-…`, `0002-…`). Numbers are permanent; a superseded ADR is **not**
  deleted — it's marked `Superseded by NNNN` and the replacement links back.
- **Format: Agetnic OS ADR shape** — modeled on
  `C:/Users/karii/Agetnic OS/data/decisions/2026-07-02-unified-memory-
  architecture.md`. Every ADR carries, in order:
  1. **Context** — the situation and forces, grounded in real files/facts.
  2. **Options** — the real alternatives, with the chosen one marked.
  3. **Decision** — what we're doing, stated plainly.
  4. **Consequences** — what gets easier/harder, and the risk being carried.
  5. **Revisit trigger** — the specific condition that reopens the decision.
     (Every ADR here ends with one. A decision with no revisit condition is a
     decree, not an ADR.)
- **Grounded, not invented.** Each ADR cites the concrete files it reasons over
  (hooks, workflows, datasets, the brain's git state). Decisions are made
  against what the repo *actually is*, on the date recorded.

### Why this is separate from the `architecture-decision-records` skill

The repo also ships the `architecture-decision-records` skill
(`skills/architecture-decision-records/SKILL.md`), which writes **Nygard-format**
ADRs under **`docs/adr/`** for decisions captured live during coding sessions.
This directory is deliberately different: it holds the **control-plane's own**
standing decisions in the **Agetnic OS format** (Context/Options/Decision/
Consequences/Revisit-trigger), matching how decisions are recorded across the
wider system. Use `docs/adr/` (via the skill) for in-session code decisions;
use `adr/` (this dir) for durable decisions about the control plane itself.

## Index

| # | Decision | Outcome | Revisit when |
|---|----------|---------|--------------|
| [0001](./0001-harness-router-regex-vs-classifier.md) | Harness router: regex vs. LLM classifier | **Keep hand-maintained regex** — fast, deterministic, gradeable via the 182-case `eval-router.sh`; a classifier can't be CI-gated the same way | Pattern upkeep becomes a recurring chore, or `none`-class recall shows real tasks going silently unrouted, or a deterministic sub-100ms local classifier appears |
| [0002](./0002-evals-in-ci.md) | Where `.claude/evals` behavior evals run in CI | **Separate CI job, not apex** — apex guards control-plane integrity; evals judge feature behavior; only deterministic graders gate | The separate eval job proves too ignorable (make it a required check, still outside apex), or a deterministic secretless security-grader earns a place in apex |
| [0003](./0003-brain-git-remote.md) | Brain has no git remote (SPOF) | **Rotate + purge the in-history token first; then local-only + encrypted external backup; a remote only after scrub, and only private + client-side encrypted** | Token confirmed rotated & history-purged (re-evaluate a private encrypted remote), or manual backup becomes the bottleneck, or another plaintext secret is found |

## Adding an ADR

1. Copy the closest existing file; take the next `NNNN`.
2. Fill Context → Options → Decision → Consequences → **Revisit trigger**.
3. **Ground it in the real files** — read the source/config/state and cite it;
   never invent structure the repo doesn't have.
4. Add a row to the index above.
5. To reverse a past decision, write a **new** ADR that supersedes it (mark the
   old one `Superseded by NNNN`); don't edit the decision out of history.
