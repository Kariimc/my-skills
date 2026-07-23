# Loop: file-butler (daily, laptop only)

**Outcome:** Downloads and Desktop stay permanently sorted with zero hand-tidying —
every run reversible, nothing ever deleted, nothing invisible.
**Trigger:** daily on the LAPTOP (scheduled task or a local Claude Code session);
never from cloud — no cloud session can reach the laptop's filesystem
(`rules/14-surface-router.md`; env facts).
**Scope:** approved zones only — starts at `~/Downloads` + `~/Desktop`; a new
zone enters the rotation only after one shown dry-run and one explicit yes from
Kariim. The engine's own exclusions (git repos, dirs, hidden, in-flight, <1h
old) are hard limits, not preferences.
**Act (per cycle):** run
`python3 ~/.claude/skills/file-butler/tool/organize.py --apply`; append the
run's summary (files moved per category, skips, manifest path + undo command)
to `~/.file-butler/run-log.md`, newest on top.
**Verify:** the manifest line-count equals the reported move count; spot-check
one moved file exists at its new path. A run that moved nothing logs "already
tidy" — that is a clean no-op, not a failure.
**Stop:** success = moves applied + log line written · clean no-op = "already
tidy" logged · blocked = a zone missing or engine error → log it, touch
nothing, surface to Kariim next session; NEVER improvise moves without the
engine.
**Escalate:** an anomalous plan (order-of-magnitude more moves than usual, or
project-looking files in a zone) is NOT applied — it's parked as a dry-run
report for Kariim. Repeated engine failures go to the my-skills failure ledger.
**Authorization note:** automatic operation on the default zones was explicitly
requested by Kariim, 2026-07-23 ("completely and automatically so I don't have
to do it by hand"). Registering the schedule on the laptop is covered by that
instruction; widening zones is not.
