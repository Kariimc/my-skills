# PROGRESS — session handoff

> Last updated: 2026-07-03 (final-week session, durable-leverage execution).
> Read this first; if it conflicts with the code, the code wins.

## Where we are

- PRs #19, #20, and **#21 (durable-leverage pack) all MERGED** to master.
  Global CLAUDE.md 804 words, Karpathy-shaped; the 25-item list is executed
  (scoreboard below).
- Brain repo: 16 wiki artifacts + ARCHITECTURE.md committed locally. NO
  remote — deliberate until token rotation + history purge
  (`adr/0003-brain-git-remote.md`). A tested in-memory purge script is ready
  at the session scratchpad (`purge_history.py`, .git backup taken); running
  it needs the user's explicit go (classifier-gated as destructive).
- **Machine migration incoming:** HP EliteBook arrives ~2026-07-06; Win11
  upgrade path found for the current Win10 box. Setup = follow
  `brain/wiki/machine-rebuild-runbook.md`; close the brain+advisor SPOF gap
  BEFORE retiring this box.
- Higgsfield token: after the user rotates it on the platform, the new value
  goes in **`C:\Dev\neon-forge-ui\token.txt`** (entire file = the token, one
  line; deploy.ps1 reads env-first then that file; no persistent HF_TOKEN env
  var exists). Then clear/refresh the old cached credential for
  apps-repos.higgsfield.ai in Windows Credential Manager and verify with
  `git ls-remote`.

## Portfolio remediation — Task 10 disposition (2026-07-06)

- Sub-Scraper = **EXECUTED** (PR #1 merged — 287 lines of network-free
  scrape/normalize tests, 38/38 green in CI, bite-proven).
- Omni-3d = **SKIPPED as parked** — last meaningful commit 2026-06-19
  (17 days stale), still on an abandoned `claude/dazzling-meitner-i36b3k`
  branch with 0 tests; not active enough to warrant the test-breadth pass per
  Task 10's conditional.

## 25-item scoreboard (was 0 DONE / 19 PARTIAL / 6 NOT_STARTED)

DONE (artifact exists, grounded, verified where runnable):
1 playbooks (wiki: debugging-heuristics, decision-frameworks,
  architecture-tradeoffs) · 2 evals (.claude/evals/ + runnable
  bin/eval-router.sh — 182/182) · 4 deep-maps (ARCHITECTURE.md ×3 repos;
  Agetnic OS already had one) · 5 user distillation (wiki/user-primer.md) ·
  6 scaffolds (scaffolds/) · 7 verification (gates + ratchet #9 + eval
  runner) · 8 golden examples (golden-examples/) · 9 ADRs (adr/0001–0004) ·
  10 debugging check-trees (in debugging-heuristics.md) · 11 instinct gates
  (ratchet #9 + fixed inert gate_secrets) · 12 hard-problems queue (wiki) ·
  14 model-agnostic stance (adr/0004) · 15 mid-tier curriculum (wiki +
  training) · 17 niche digest (wiki, cited) · 18 dataset
  (datasets/harness-routing, validated) · 19 undocumented systems
  (credential-map, machine-rebuild-runbook) · 20 taste rubric (wiki) ·
  21 migration guides (windows-10-eol-migration + SPOF plan) · 23 onboarding
  (cold-start test run; primer written; hoopclone memories corrected) ·
  24 worked-examples index (wiki) · nano-artifact (nano/nano_plane.py,
  tested: route/gate/loop all pass, incl. a planted-secret catch).

PARTIAL (core done, tail is ongoing habit or user-gated):
3 skill hardening — convention doc + 4 harnesses have output contracts; the
  other ~400 skills are an ongoing ratchet, not a one-shot ·
13 trainings — 2 interactive trainings live (~/.claude/advisor/trainings/);
  the habit is the asset · 16 ship — inventoried + ranked in
  hard-problems-queue; actual shipping = user decisions ·
22 automation — XAVIER scheduled task exists but has NEVER fired (run
  morning-briefing.ps1 once manually, then verify the 08:00 trigger) ·
25 roadmap — structure + adversarial inputs done; real numbers need the
  interview.

## USER-GATED (only you can do these)

1. ~~Rotate the Higgsfield token~~ **IMPOSSIBLE user-side** — verified twice
   2026-07-03: no regeneration exists AND the token is **account-scoped** (a
   fresh website returned the byte-identical token, so rebuild/delete cannot
   rotate it). Only rotation: a Higgsfield support ticket. Containment is
   permanent policy (credential-map.md §1). Delete the old handoff docs in
   `~/Downloads` that still carry it.
2. ~~Brain history purge~~ **DONE 2026-07-03** — user ran `purge_history.py`
   v2 (token-exact; v1's safety rail correctly caught its own 40-hex
   over-match and was rolled back cleanly). 26 occurrences purged, tree
   verified byte-identical, old objects pruned, re-scan shows only git SHAs.
   The unpurged .git backup was destroyed. Brain is now eligible for an
   encrypted off-machine backup / private encrypted remote per adr/0003.
3. **Advisor interview** (~15 min) → plan-12mo v1 + flagship decision (#25).
4. Authorize the MCP connectors you actually use (claude.ai settings).
5. When the EliteBook lands (~Jul 6): machine-rebuild-runbook.md, and back up
   brain + ~/.claude/advisor off-machine first.

(Resolved: Win10-vs-Win11 contradiction — it IS Win10 today; upgrade path
found; the wrong Agetnic-OS memory has been corrected.)

## Machine gotchas (full detail in project memory + wiki/debugging-heuristics)

- Fast python: `C:\Users\karii\AppData\Local\Python\pythoncore-3.14-64\python.exe`
  (PATH `python` = 1.2s WindowsApps shim). ASCII-only in printed strings —
  cp1252 consoles crash on unicode arrows.
- Apex gates ~5 min per commit/push; run in background with 10-min budget.
- Long-lived shells have stale PATH (gh/jq/rg/fd need full paths).
- settings.json edits are classifier-blocked — hand the user a script.
- Never put guarded strings or live tokens literally in a command line — the
  guard/classifier blocks the call; pipe from files.
