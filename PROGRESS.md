# PROGRESS — session handoff

> Last updated: 2026-07-03 (final-week session). Read this first;
> if it conflicts with the code, the code wins.

## Where we are

- **PR #19 (peak-condition audit) MERGED** to master as `ac27eca`. CI green.
- **Branch `rework/karpathy-rules` in flight:** rules/ rewritten Karpathy-style
  (9 files → 6, core loop + short leash + evidence-over-vibes; deleted
  06-silent-execution, 08-deliverable-only, idp-control-plane — essence folded
  into 00-core and 04). Adversarial review workflow ran before the PR.
- **25-item durable-leverage audit DONE** (12-agent evidence sweep, outputs
  the plan below): 0 DONE, 19 PARTIAL, 6 NOT_STARTED (#8 golden examples,
  #12 hard-problems queue, #15 mid-tier curriculum, #17 research digest,
  #18 synthetic data, #21 migration guides).
- gh CLI durably authenticated (keyring, account Kariimc). context7 MCP added
  (user scope, connected). jq / ripgrep / fd / shellcheck installed (user
  scope; new shells have them).

## THE 4-DAY PLAN (Karpathy-weighted; access ends in ~4 days)

Principle: convert intelligence into evals, playbooks, guardrails, finished
decisions. Skip: #14 orchestration layer, #18 synthetic data, most Tier 4.

**Day 1 — Prune + urgent hygiene (½d), start recipes (½d)**
- SECURITY (do first): move `C:\Dev\neon-forge-ui\token.txt` out of the repo;
  confirm rotation of the Higgsfield token found in plaintext in an archived
  transcript (`C:\Dev\brain\raw\inputs\`, flagged in ingestion-log.md).
- Prune the 411-skill library to the set actually used (delete-first; use
  agent-sort/config-gc). Complexity must pay rent.
- Start playbooks: distill `debugging-heuristics.md`, `decision-frameworks.md`,
  `architecture-tradeoffs.md` into `C:\Dev\brain\wiki\` from the 8 archived
  transcripts + the 2 Agetnic-OS ADRs.

**Day 2 — Recipes/playbooks (#1, #10, #24)**
- Symptom→hypothesis→check debugging trees per real stack: Windows/PowerShell
  (finish windows-env-repair DRAFT), Cloudflare Workers/wrangler, Claude Code
  hooks. Store in brain/wiki.
- Worked-examples index (`brain/wiki/worked-examples.md`): per hard problem —
  problem → approach → key moves → outcome, linking the 8 transcripts.

**Day 3 — Private evals (#2, #23)**
- Author `.claude/evals/` rubrics + runnable checks for top workflows:
  harness-router routing accuracy (expand the 1 smoke case to a 100+
  prompt→expected-harness suite), second-brain ingest correctness,
  neon-forge-ui component acceptance. Wire into apex-gates/CI.
- Cold-start onboarding test: fresh session gets only CLAUDE.md + PROGRESS.md +
  MEMORY.md; patch every gap it reveals; reconcile stale per-project memories
  (hoopclone memory contradicts reality).

**Day 4 — Tutoring→notes (#13, #20) + nano-artifact + decisions**
- Tutoring sessions on weakest fundamentals → spaced-repetition notes;
  1-2 more advisor trainings.
- Personal taste rubric (stop-slop format, scored 1-10 + threshold) extracted
  from loved examples, for UI and writing.
- Nano-artifact: minimal readable reimplementation of the control-plane core
  (router + gates + one harness loop) the user fully understands.
- END: advisor interview (~15 min, user parked it here) → plan-12mo v1 with
  real numbers + flagship decision + adversarial premortem (#25).

## Next actions (in order)

1. Merge PR for `rework/karpathy-rules` (user gates merges).
2. Execute Day 1 (security items first).
3. User-only: authorize the MCP connectors actually used (claude.ai connector
   settings); ~40 plugin servers are unauthenticated noise.
4. Advisor interview at the END of day 4 (user's explicit sequencing).

## Machine gotchas (full detail in project memory)

- `python3`/`python` = slow WindowsApps shim (~1.2s/spawn). Fast interpreter:
  `C:\Users\karii\AppData\Local\Python\pythoncore-3.14-64\python.exe`.
- Git Bash forks are slow; bulk per-file shell loops over 400+ dirs time out —
  use single-pass awk/python.
- Commits/pushes run the apex gate suite: ~5 min each. Run in background with
  a 10-min budget.
- Long-lived agent shells have stale PATH: gh/jq/rg/fd need full paths there;
  fresh terminals are fine.
- Editing ~/.claude/settings.json is classifier-blocked for the agent — hand
  the user a script (pattern: bin/apply-hook-tuning.sh).
- Never put guarded strings (rm -rf /, force push) literally in a Bash command
  line — the live guard blocks the call; pipe test payloads from files.
- Windows 10 Home 10.0.19045: past end-of-support since Oct 2025 — migration
  plan is an open item (#21).
