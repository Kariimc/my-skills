---
description: Push this repo's committed skill/rule/command changes UP to GitHub through the apex gate suite, so they reach the cloud and every other machine. (Down / live-now is /sync-skills.)
---

Sync the **my-skills control plane** UP to GitHub: commit local changes and run the
gated push to completion. This is the UP direction (local -> cloud); `/sync-skills`
is the DOWN direction (repo -> ~/.claude, live now).

Optional commit message: $ARGUMENTS

Never break these:
- NEVER use `--no-verify` or `--force`. The pre-commit guard and apex pre-push gates ARE the point.
- NEVER auto-merge a divergence. NEVER create an empty commit.

Steps:
1. Make sure you are in the my-skills clone (its `origin` remote is
   `github.com/Kariimc/my-skills`). If the current project is not it, `cd` to that
   clone; if you cannot find it, ask me for the path.
2. `git pull --ff-only`. If it fails because the branch diverged, STOP and tell me —
   I will reconcile by hand. Do not merge for me.
3. Look at `git status --porcelain` and whether HEAD is ahead of `origin/master`.
   If the tree is clean AND nothing is ahead -> report "already in sync" and STOP.
   Do not commit.
4. If there are uncommitted changes: `git add -A`, then commit. Use $ARGUMENTS as the
   message if I gave one; otherwise write one honest concise line from
   `git diff --cached --name-status` (e.g. `add skill: <name>`, `update rules: <file>`).
   The pre-commit guard runs here — if it blocks, show me exactly what failed and STOP.
5. `git push origin master`. This runs the full apex gate suite and takes ~30-60s —
   let it finish, do not interrupt. If a HARD gate failure blocks it, show me the
   failing gates, tell me to fix them or run `bin/apex.sh`, and STOP.
6. Confirm `git status -sb` shows `0 ahead`, then report ONE line: what was committed,
   that the gates passed, and that it is pushed.