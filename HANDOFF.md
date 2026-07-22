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

**2026-07-22 session (branch `claude/harnesses-agents-suggestions-dqaas2`):** Added
`docs/HARNESS-AGENT-ROADMAP.md` — a sharpened reusable prompt plus a ranked,
evidence-cited roadmap of 8 new harnesses/agents (build-first: deliverable-verifier,
env-scout, harness-visual), each tied to specific FAILURES/PLAYBOOK/audit entries.
ALL of it was then BUILT the same session (see below). Second ask: added
`docs/RULE-ENFORCEMENT-STREAMLINE-PLAN.md` — diagnosis of why agents violate
written rules + an enforcement pyramid (gates > hooks > verifier subagents >
minimal prose), one standard pipeline, and a 7-item build order. Third ask: added
`docs/3D-MASTER-MODELER-EXECUTION-PLAN.md` — run-card + phase-gate design so the
1,170-line 3d-master-modeler skill gets executed top-to-bottom, never sampled.

**BUILT (same session, per "build everything and land everything"):** agents
`deliverable-verifier` + `scribe` (global via agents/ sync); hooks
`env-scout.sh` (SessionStart fact sheet), `ledger-sentinel.sh`
(UserPromptSubmit F/P injection), `runcard-guard.sh` (Stop, 3D run-card
enforcement) — registered project-level AND in session-start block 6b2 for
global reach, KNOWN heal-set + selftest-guards extended; skills
`harness-visual` (with tested tool/imgdiff.py) + `harness-3d`;
`skills/AGENT-CONTRACT.md` + fidelity gate wired into all 6 harnesses;
`loops/skill-gardener.md`; `rules/14-surface-router.md` (+ rules README rows
12-14); `docs/RULES-ENFORCEMENT-MAP.md`; apex behavioral ratchet lane in
GATES.md; 3d-master-modeler `runcard.md` mandatory via operating rule 7.
Post-landing same session: runcard-guard re-armed on STRUCTURAL skill
invocation after false-blocking its own authoring session (PR #55, merged);
env-scout became a full agent (71 agents); cant-guard Stop hook + YOU-HAVE
capability inventory added so "can't" requires a search first (PR #56).
Rulebook-slimming pass (Kariim's explicit yes, 2026-07-22): the five
machine-carried rule files (01 plain-talk, 07 progress, 09 consult-skills,
11 failure-ledger, 12 playbook) shrunk 113 -> 64 lines, each ending in an
ENFORCED-BY pointer to docs/RULES-ENFORCEMENT-MAP.md; every duty preserved,
JUDGMENT rules untouched (00-contract, 00-core, 00-idp, 10-topology, etc.).
Generated ~/.claude/CLAUDE.md verified rebuilt: 638 -> 589 lines, slim text
live, zero old remnants.
Custodian + verifier decree (2026-07-22): github-custodian agent (72 agents)
wired into loops/repo-hygiene.md exposure-first sweep; verification decree —
deliverable-verifier + agent-evaluator now model: fable (HIGH), fallback
Opus 4.8 high then Sonnet 5 high, verdict names the model — encoded in
rules/06 and AGENT-CONTRACT. Cross-repo sweeps need gh/added repos; this
cloud session is scoped to my-skills only.
Flagged deviations: prose rulebook NOT shrunk (map first, cuts need Kariim's
review); env-scout shipped as script+hook, not an agent (plan's own smallest
version). Everything proof-tested pre-commit; landed via PR #54.

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

## 2026-07-15 - pre-commit doctor scoped to staged skills
- bin/skill-doctor.sh: new --staged flag scopes the per-skill scan to skill folders with staged changes; the triage report is only rewritten on full runs, so a partial scan can never clobber it.
- .githooks/pre-commit: doctor now runs --fix --staged. One-file commits drop from ~3 min to seconds.
- Coverage unchanged at push time: pre-push (apex-gates all) still runs the FULL doctor.
