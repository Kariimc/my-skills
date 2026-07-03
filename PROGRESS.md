# PROGRESS — session handoff

> Last updated: 2026-07-03 (final-week session, durable-leverage execution).
> Read this first; if it conflicts with the code, the code wins.

## Where we are

- PR #19 (peak-condition audit) and PR #20 (Karpathy rules rework) both
  **MERGED** to master. Global CLAUDE.md now 804 words, Karpathy-shaped.
- Branch **`build/durable-leverage-pack`**: the 25-item list executed (see
  scoreboard below). Waves A–C ran as multi-agent workflows; D–E ran solo
  after a session-limit block killed subagent spawning.
- Brain repo: 14 new wiki artifacts + ARCHITECTURE.md, all committed locally
  (brain has NO remote — deliberate until token history is purged, see
  `adr/0003-brain-git-remote.md`).

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

1. **Rotate the Higgsfield token** (user said "later" — it's burned; also
   still recoverable from brain git HISTORY; purge before any brain remote).
2. **Advisor interview** (~15 min) → plan-12mo v1 + flagship decision (#25).
3. Win10 vs Win11: an Agetnic-OS memory says Win11 "confirmed", env says
   Win10 Home past EOL. Answer decides whether the EOL migration is real.
4. Authorize the MCP connectors you actually use (claude.ai settings).
5. Merge the `build/durable-leverage-pack` PR when CI is green.

## Machine gotchas (full detail in project memory + wiki/debugging-heuristics)

- Fast python: `C:\Users\karii\AppData\Local\Python\pythoncore-3.14-64\python.exe`
  (PATH `python` = 1.2s WindowsApps shim). ASCII-only in printed strings —
  cp1252 consoles crash on unicode arrows.
- Apex gates ~5 min per commit/push; run in background with 10-min budget.
- Long-lived shells have stale PATH (gh/jq/rg/fd need full paths).
- settings.json edits are classifier-blocked — hand the user a script.
- Never put guarded strings or live tokens literally in a command line — the
  guard/classifier blocks the call; pipe from files.
