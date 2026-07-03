# PROGRESS — session handoff

> Last updated: 2026-07-03 (peak-condition audit session). Read this first;
> if it conflicts with the code, the code wins.

## Where we are

Full control-plane audit is DONE and all fixes are on branch
**`audit/peak-condition`** (pushed). Gates: skill-doctor HARD=0 SOFT=0;
apex-gates all green. 411 skills, 67 agents.

**Open PR manually** (gh CLI was just installed via winget this session — new
terminals should have it; authenticate with `gh auth login` first):
https://github.com/Kariimc/my-skills/compare/master...audit/peak-condition
PR body ready in the session scratchpad as pr-body.md (or regenerate from the
commit messages of d718068 + f1fb946 + the rules-restructure commit).

## What changed this session (all on audit/peak-condition)

1. **Hook latency fixes** — the big one. observe.sh (continuous-learning-v2)
   cost ~19s per run on EVERY tool call (pre+post); guard-destructive ~3s more.
   User ran `bin/apply-hook-tuning.sh`: observer unhooked from settings.json,
   guard scoped to matcher "Bash". Guard rewritten (pure-bash pre-filters +
   single fast python); harness-router 2707ms → 377ms. Verified semantics
   unchanged (guard blocks rm -rf / and bare force-push; router routes same).
2. **skill-doctor SOFT 9 → 0** — trimmed 7 over-long descriptions, fixed README
   counts, tracked 3 machine-local skills (codebase-memory, neon-forge-ui,
   windows-env-repair) in the repo.
3. **New `advisor` skill** (skills/advisor) — interview → goals → 12-month plan
   → check-ins → metrics dashboard → interactive HTML trainings. Data home:
   `~/.claude/advisor/` (profile.md, goals.md, plan-12mo.md DRAFT v0,
   metrics.json, check-ins.md, trainings/claude-code-power-moves.html).
4. **Rules restructure** — global CLAUDE.md 2235 → 1326 words. Deleted
   00-communication-style + 01-teach-as-we-go (their behavior lives in
   C:\Dev\my-coding-journey\CLAUDE.md, which already had it); 04-response-mode
   now self-contained; idp-control-plane slimmed 524 → ~180 words;
   rules/README.md table refreshed. ~/.claude/CLAUDE.md recompiled.
5. **pre-commit dedupe** — doctor ran twice per commit (~10 min on this box);
   now once (--fix run doubles as the gate; remaining gates run individually).
6. **docs-lookup agent** — WebSearch/WebFetch fallback (context7 MCP is not
   configured on this machine).

## Next actions (in order)

1. Open + merge the PR (user gates merges to master).
2. **Run the advisor interview** — say "advisor, interview me" (~15 min).
   Turns plan-12mo.md DRAFT v0 into v1 with real numbers. This is the highest-
   leverage pending item.
3. Optional: authorize the MCP connectors actually used (claude.ai connector
   settings / `/mcp`); ~40 plugin servers are unauthenticated noise right now.
4. Optional: `claude mcp add context7` if doc-indexed lookups are wanted.

## Machine gotchas (full detail in project memory)

- `python3`/`python` = slow WindowsApps shim (~1.2s/spawn). Fast interpreter:
  `C:\Users\karii\AppData\Local\Python\pythoncore-3.14-64\python.exe`.
- Git Bash forks are slow; bulk per-file shell loops over 400+ dirs time out —
  use single-pass awk/python.
- Commits/pushes here run the apex gate suite: expect ~5 min each even after
  the dedupe. Run them in background with a 10-min budget.
- Editing ~/.claude/settings.json is classifier-blocked for the agent — hand
  the user a script (pattern: bin/apply-hook-tuning.sh).
- Never put guarded strings (rm -rf /, force push) literally in a Bash command
  line — the live guard blocks the call; pipe test payloads from files.
