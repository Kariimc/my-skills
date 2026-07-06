# Loop: overnight-brief

**Outcome:** every morning at 08:00 a briefing file exists summarizing repo
state and anything the overnight queue produced — so the day starts with
context, not archaeology.
**Trigger:** Windows Scheduled Task `XAVIER`, daily 08:00 → `bin/morning-briefing.ps1`.
**Scope:** read-only over local repo clones (PROGRESS.md, git log) and
`loops/queue/`. Writes exactly one file: `~/Desktop/morning-brief-<date>.md`.
May not touch repos, remotes, or ~/.claude.
**Act (per cycle):** collect each repo's PROGRESS.md "where we are" + last 24h
commit lines + any results dropped in `loops/queue/done/`; compose one brief.
If Claude Code CLI is present, one `claude -p` call summarizes; otherwise the
raw sections ARE the brief (the loop must not depend on the CLI).
**Verify:** the brief file exists, is non-empty, and names every repo scanned.
The script's last log line is the WAKE report (harness-autonomous contract).
**Stop:** success = brief written · clean no-op = impossible by design (an
empty day still writes "no changes") · blocked = repos root missing → log
BLOCKED, write a stub brief saying so.
**Escalate:** 2 consecutive BLOCKED mornings → the stub brief says
"XAVIER blocked twice: <reason>" in the first line.

**Evening half (manual habit, no automation):** drop tomorrow-morning tasks as
files in `loops/queue/overnight/`; an overnight Claude Code session (run by you
or a future scheduled runner — NOT auto-registered by this install) works the
queue and moves finished items to `loops/queue/done/` with results appended.
