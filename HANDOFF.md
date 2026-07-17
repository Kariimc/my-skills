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

**2026-07-17 session (branch `claude/failure-ledger`):** Kariim declared a new 10-rule
"Standing Contract" the governing chat-surface rules. Installed as `rules/00-contract.md`
(named to sort FIRST in the concatenated `~/.claude/CLAUDE.md`). Removed the two real
clashes with it in `rules/00-idp-operating-law.md`: clarity-gate "exactly 2 questions"
→ recon-first, up to 2, zero ideal; two-strike cap → on METHOD CLASSES not attempts.
Fixed `rules/README.md` index (was missing `00-idp-operating-law.md` and
`11-failure-ledger.md`; added those + the new contract row). Manually rebuilt the live
`~/.claude/CLAUDE.md` from `rules/` and verified the contract + both fixes are present.
Root cause of the "rules keep reverting" symptom: `~/.claude/CLAUDE.md` is regenerated
from `rules/*.md` on every session start, so direct edits to it are always overwritten —
the source of truth is `rules/`, and that is where the contract now lives.

## Exact next steps

- **Awaiting Kariim's yes** to merge `claude/failure-ledger` → `master` and push, so the
  contract propagates to the other surfaces (cloud, cowork, steamdeck). Default branch is
  `master`; merge-to-master is the one git gate.
- The save-to-history commit was running through the pre-commit gate in the background —
  confirm it landed (`git log -1`) before merging.
- **Offered, awaiting yes:** delete 45 leftover `~/.claude/skills.tmp.*` junk folders from
  past syncs.

## Open decisions

- Whether to also restore the other newer IDP clauses (subagent-binding, preferences-
  precedence, ROLE precedence line) into `00-idp-operating-law.md`. Not done: they are not
  clashes, and `00-contract.md` already carries the equivalent behaviour. Left minimal on
  purpose (surgical).

## Rules

- Repos span TWO namespaces: user `Kariimc` AND org `shift9-studio`. Enumerate with
  `gh api '/user/repos?affiliation=owner,collaborator,organization_member'`, never
  `gh repo list Kariimc` alone. See `Kariimc/my-skills` `rules/10-repo-topology.md`.
- Never assert an absence, status, or completion without proving your scope was exhaustive.
- Update this file in the same commit as any code change. A global pre-commit hook enforces it.
