# PROGRESS.md — SESSION HANDOFF

If `./PROGRESS.md` exists, read it before anything else; the code beats the
file — fix drift the same session. Update it at session end and before any
handoff (`project-context-loader` or the `scribe` agent), not on every change.
CLAUDE.md = durable rules; PROGRESS.md = live state. Environment facts Kariim
should never repeat (what's installed, what a surface can/can't reach) land in
PROGRESS.md + the relay the SAME session they're learned — `env-scout` probes
them fresh each session start. (Approved rule, 2026-07-22.)

> ENFORCED-BY `hooks/guard-handoff.sh` (Stop) + `hooks/env-scout.sh` +
> `scribe` agent — see `docs/RULES-ENFORCEMENT-MAP.md`.
