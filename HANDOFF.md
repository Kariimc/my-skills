# HANDOFF - Kariimc/my-skills

> Continuity doc. Any agent must resume cold from this file with zero briefing.
> Update it in the same commit as any code change.

**Seeded:** 2026-07-15 from verified repo state. Sections marked UNVERIFIED were not
provable from the repo alone - fill them in, do not guess.

## Verified facts

| | |
|---|---|
| Repo | `Kariimc/my-skills` |
| Namespace | user `Kariimc` |
| Default branch | `master` |
| Visibility | public |
| Language | Python |
| Files | 1335 |
| Last commit | 2026-07-15 - docs: rules README lists 01, 09, 10 - table had drifted from its own f |
| Branches | 26 |
| Open PRs | 3 |

**Top-level dirs:** `.claude`, `.codex`, `.githooks`, `.github`, `adr`, `agents`, `apex`, `bin`, `commands`, `datasets`, `docs`, `golden-examples`, `hooks`, `loops`, `nano`, `rules`, `scaffolds`, `skills`, `wargames`

**Root files:** `ARCHITECTURE.md`, `CHANGELOG.md`, `PROGRESS.md`, `README.md`, `always-load.txt`, `global-skills-guide.pdf`, `install-global.sh`

**Existing docs:** `ARCHITECTURE.md`, `CHANGELOG.md`, `PROGRESS.md`, `README.md`, `adr/README.md`, `agents/README.md`, `agents/gan-planner.md`, `agents/planner.md`, `agents/seo-specialist.md`, `agents/spec-miner.md`, `agents/type-design-analyzer.md`, `commands/README.md`

## Open PRs

- #7 ci: bump actions/setup-python from 5 to 6  `dependabot/github_actions/actions/setup-python-6`
- #6 ci: bump actions/checkout from 4 to 7  `dependabot/github_actions/actions/checkout-7`
- #5 ci: bump dependabot/fetch-metadata from 2 to 3  `dependabot/github_actions/dependabot/fetch-metadata-3`

## Current state

**UNVERIFIED.** Percent-complete and working/broken status cannot be derived from
the repo alone. Do not write a number here you have not proven. Read the code, run
the build, then record what you observed and how you observed it.

## Exact next steps

**UNVERIFIED.** Fill in on first real session in this repo.

## Open decisions

**UNVERIFIED.**

## Rules

- Repos span TWO namespaces: user `Kariimc` AND org `shift9-studio`. Enumerate with
  `gh api '/user/repos?affiliation=owner,collaborator,organization_member'`, never
  `gh repo list Kariimc` alone. See `Kariimc/my-skills` `rules/10-repo-topology.md`.
- Never assert an absence, status, or completion without proving your scope was exhaustive.
- Update this file in the same commit as any code change. A global pre-commit hook enforces it.

## 2026-07-15 - pre-commit doctor scoped to staged skills
- bin/skill-doctor.sh: new --staged flag scopes the per-skill scan to skill folders with staged changes; the triage report is only rewritten on full runs, so a partial scan can never clobber it.
- .githooks/pre-commit: doctor now runs --fix --staged. One-file commits drop from ~3 min to seconds.
- Coverage unchanged at push time: pre-push (apex-gates all) still runs the FULL doctor.
