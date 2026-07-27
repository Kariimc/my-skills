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

**2026-07-27 session (branch `claude/machine-setup-2026-07-27`, NOT pushed, NOT
merged):** one-time setup of Kariim's local Windows laptop (HP EliteBook 840 G9,
`S-5CG3262FQB`). Fifteen steps, all completed and proven with real command
output. Machine-level changes live outside this repo; everything that belongs to
the control plane was added HERE, on the source side, so the session-start sync
can regenerate `~/.claude` without losing it.

### What changed in this repo this session

- `skills/preview/` (+ `tool/start-dev.ps1`) — new. Starts a project's own dev
  server on a free port in 5173-5250 with **no visible console window** (F-38),
  polls until it truly answers (45s cap, prints the server's own stderr and stops
  on timeout), then drives Playwright for 1280/768/390 screenshots into
  `.preview/` plus chrome-devtools console errors. Server is left running.
- `skills/intent-lock/` — new. Four plain questions before any task touching more
  than two files; writes `INTENT.md` at the project root. Explicitly hands off to
  the existing `intent-driven-development` skill for security/data/migration work
  rather than duplicating its `AC-NNN` method.
- `agents/verifier.md` — new. Adversarial diff reviewer; sees only the diff and
  the stated requirements, never the reasoning. Reports correctness/requirement
  gaps only. Reads `INTENT.md` as requirements of record.
- `hooks/verify-gate.sh` — new. Runs typecheck → lint → build → test (skipping
  what a project lacks), exits non-zero on first failure. Registered as a **Stop
  hook**, so a turn cannot end while a project is failing. Cheap by design: exits
  instantly if not a git repo or the tree is clean, and caches a pass fingerprint.
  Cannot deadlock — 8 consecutive blocks releases it, `VERIFY_SKIP=1` disables it,
  everything unexpected fails open. Also runnable by hand with `--run`.
- `hooks/guard-destructive.sh` — **extended, not rewritten**; fast pre-filter
  design kept. Added blocks for: force-push via `+refspec`, branch deletion (local
  and remote), writes outside the current project root, credential files
  (`.env`, `~/.ssh`, `~/.aws`, keys, `.npmrc`, `.netrc`, `.pgpass`, certs), and
  `DROP`/`TRUNCATE`/`dropDatabase`. DB destruction was promoted from warning to
  block. `.env.example`/`.sample`/`.template` stay allowed; reads are never
  blocked by the new rules; `--force-with-lease` still passes.
- `rules/15-verification.md` — new. Four standing rules: preview instead of
  deploying to look; deploy only on Kariim's word; no "done" without pasted
  verify output; every paste-able instruction names surface/repo/branch/folder/
  where-to-paste/on-screen choices by name/what done looks like, and says so
  explicitly when a field does not apply.
- `always-load.txt` — `preview` and `intent-lock` added to the tier-1 core
  (40 → 42).
- `README.md` / `ARCHITECTURE.md` — count drift auto-fixed by the skill-doctor
  gate (429 skills, 74 agents).

### Follow-up the same day — allowlist conflict resolved

Kariim spotted that `permissions.additionalDirectories` (which says "Claude may
work here") and the guard's outside-project-root block are two hand-maintained
lists that can drift apart. The my-skills carve-out already existed and worked,
but it was hardcoded. The guard now **reads `additionalDirectories` from
settings.json** and allows exactly those directories, plus its short built-in
list (`~/bin`, `~/.claude`, `~/.gitignore_global`, `/tmp`, the session
scratchpad). One source of truth; nothing wider. Unreadable settings fail
CLOSED — a broken settings file cannot silently disable the guard.

Proved three ways: a real Edit into my-skills succeeded while the working
directory was a different project; a real Write to `~/Documents` from that same
project was blocked and left no file; and in an isolated fake HOME, a directory
listed ONLY in `additionalDirectories` was allowed, an unlisted one was blocked,
and removing the setting made the previously-allowed path blocked again.
Kariim's real settings were never modified during the test.

### Second follow-up the same day — orphan files are no longer orphans

`sk.cmd`, `verify.cmd`, `preflight.ps1` and `.gitignore_global` existed on ONE
laptop and in no repo. They now live in `machine/` here, and **`install-global.sh`
was extended** (not replaced - it is still the only installer) with an
`install_machine_files` step that recreates all four in their correct places and
puts `~/bin` on the user PATH.

Details worth not rediscovering:

- `.gitattributes` was added forcing `*.cmd` / `*.bat` to `eol=crlf`. A batch
  file with LF endings makes cmd.exe chop the first characters off lines - it
  fails confusingly rather than cleanly. The installer ALSO normalises to CRLF
  on write, so a clone made with odd settings still produces a working `sk`.
- PATH is set from `machine/add-bin-to-path.ps1`, called as a real script FILE.
  Not a quoted multi-statement command through a layered shell (ledger F-35/F-49),
  and not `setx` - setx truncates a PATH over 1024 chars and would destroy it.
- The gitignore merge is line-by-line, so a machine's own entries survive.
- `add-bin-to-path.ps1` is skipped when copying `*.ps1` to `~/bin` - it is the
  installer's helper, not a user command.

Proved: installer run twice on this machine - files unchanged, PATH stayed at
exactly one `bin` entry. Then run against an empty fake HOME - all four
recreated, byte-identical to the originals, `sk.cmd` still 70 CRLF lines, helper
not leaked. Fake home deleted afterwards.

Also: PowerShell 7.6.4 installed at user scope; Windows PowerShell 5.1 left in
place and still working. It was never part of the original baseline list.

And the sync-survival claim from earlier was actually tested rather than
asserted: two back-to-back syncs, all seven rebuilt files present and
byte-identical to their sources afterwards (CLAUDE.md checked by content - all
18 rule sections present).

### Machine-level changes (outside this repo, for the record)

Long paths + developer mode enabled in the registry; `core.longpaths` on;
CurrentUser execution policy set to RemoteSigned. Baseline tools installed via
winget/npm (ripgrep, jq, fd, 7-Zip, CMake, turbo, vercel; git/gh/node/python/uv/
pnpm were already present). `~/bin` created and added to the user PATH, holding
`sk.cmd` (refuses to launch Claude outside a repo, off a repo root, or on
main/master; otherwise prints repo/folder/branch/remote and launches with the
skills repo added), `verify.cmd`, and `preflight.ps1` (doctor / install / ledger,
writes `~/.claude/stack-state.json` every run). `@playwright/mcp` and
`chrome-devtools-mcp` installed globally with a local chromium and registered at
user scope pointing at the installed binaries — both Connected. Global gitignore
now covers `.preview/` and `.playwright-mcp/`. Permission allowlist of 54 safe
entries added (package scripts, safe git verbs, test runners, browser MCPs);
nothing destructive is allowlisted — the guard stays authoritative.

### Proven, not assumed

- Guard selftest: the 8 `guard-destructive` checks pass. Two failures exist
  (`runcard blocks 3d session without card`, `cant blocks unsearched
  helplessness`) — **pre-existing**, proven by stashing the guard change and
  seeing the identical two failures on the untouched file. Not caused here, and
  not fixed here.
- Verify gate: broken a throwaway project → hook exit 2 with the real failure
  output; reverted → hook exit 0. Done twice, in two separate projects.
- Six newly-blocked commands each produced their block message; four legitimate
  cases (`--force-with-lease`, writing `.env.example`, writing inside the project,
  reading a credential path) still pass.
- All four `sk` branches exercised, including the success path.
- Only ONE copy of this repo exists on disk. Two extra hits under
  `.claude/worktrees/` share the same `git-common-dir` — they are worktrees, not
  clones. Do not re-flag them as duplicates.

### Exact next steps

1. **Decide on the branch.** `claude/machine-setup-2026-07-27` has two commits and
   is neither pushed nor merged. Pushing and opening a PR needs a word from
   Kariim; merging to `master` always needs a fresh yes.
2. **Watch the outside-project-root guard.** It is the new rule most likely to
   block legitimate work. Allowlist today: this repo, `~/bin`, `~/.claude`,
   `~/.gitignore_global`, temp dirs. Escape hatch is `GUARD_ALLOW_OUTSIDE=1`.
   Widen the list rather than removing the rule.
3. **Leave the scratch projects alone** — `C:\scratch-skilltest\{gate-demo,
   sk-demo,guard-demo}` are the gate/guard/sk evidence and were left in place
   deliberately.

### Open decisions

- **Unreal MCP:** no `unreal-mcp` package exists on PyPI (verified — uvx resolves
  to "not found in the package registry"), and only the Epic launcher is
  installed, not the engine. `preflight.ps1` registers nothing for Unreal and
  rolls back any creative-app server that fails to connect. Revisit if a real
  package appears.
- **Unity and Blender MCP servers** (`uvx unity-mcp-server`, `uvx blender-mcp`)
  are registered and Connected, but have not been exercised on a real project yet.
- **7-Zip is not on PATH** (installs to Program Files without one). Detection
  falls back to the known path so doctor and install agree; left as-is rather than
  growing the PATH.

---

**2026-07-23 session (branch `file-butler-skip-launchers`, PR #66):** file-butler
was in the repo but NOT synced to `~/.claude/skills/` — the `file-butler` agent
correctly refused to hand-roll move logic and stopped. Fix: copied
`skills/file-butler/` into `~/.claude/skills/`. Then a real dry-run exposed a
genuine bug: sorting `~/Desktop` planned to move all 19 `.lnk` shortcuts into
`_Sorted/Other`, i.e. wipe every icon off the screen.

Change made in `skills/file-butler/tool/organize.py`: added `NEVER_MOVE_SUFFIXES`
(`.lnk .url .desktop .webloc .bat .cmd`) and `NEVER_MOVE_NAMES` (`desktop.ini`,
`thumbs.db`, `.DS_Store`), skipped in BOTH `plan_zone()` and the
`--suggest-deletions` file walk (so a duplicate shortcut is never a deletion
candidate either).

Proof: scratch zone with 3 launchers + 3 real files → only the 3 real files
planned; duplicated `.lnk` pair absent from deletion suggestions. Live: Desktop
19 → 0 to sort, Downloads 169 → 168. Then `--apply` ran for real: 168 files
moved into `~/Downloads/_Sorted/<Category>/`, Desktop untouched, undo manifest
at `~/.file-butler/manifest-20260723-210017.jsonl`. All apex gates passed.

Next steps: (1) merge PR #66 after review — needs Kariim's yes, master is gated.
(2) The scheduled file-butler loop (`loops/file-butler.md`) is still NOT
registered on the laptop — Downloads/Desktop are now confirmed-safe zones, so
registering it is the natural follow-up, but auto-running tasks need an explicit
yes. (3) One Downloads file (`Godot_v4.7-stable_win64.exe`) was skipped as
younger than the 1-hour safety window; next run picks it up.

Open decision: whether `.exe` on the Desktop should also be never-moved.
Currently `.exe` still sorts into `Installers` — right for Downloads, arguably
wrong for a Desktop where a portable app lives.

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
Chat-surface fix (2026-07-22, from the titanium-forge chat incident): F-56
(unverified-baseline build) + F-57 (expensive channel over one-click) appended
to FAILURES.md (both copies); chat/CHAT-BOOTSTRAP.md created — the 7-law
chat-surface rulebook every plain-Claude chat loads via a settings pointer.
Kariim's one manual step: paste the pointer into claude.ai settings.
file-butler shipped (2026-07-23): agent + skill + stdlib engine
(moves-only, undo manifest, git/hidden/in-flight/<1h protected) + daily loop.
Proof-tested end to end (11 sorted, collision suffixed, protected intact,
undo 12/12). Relay inbox message left for code-local to run the first shown
dry-run and arm the laptop schedule — Kariim explicitly authorized automatic
operation 2026-07-23. Cloud cannot reach laptop files; laptop owns execution.
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
