# PROGRESS.md — SESSION HANDOFF

If `./PROGRESS.md` exists, read it before anything else: current focus, next
action, gotchas, key decisions. The code beats the file — when they disagree,
fix the file in the same session.

Update it at session end and before any handoff (the `project-context-loader`
skill maintains it), not on every change. Lives at the repo root, committed.
CLAUDE.md = durable rules; PROGRESS.md = live state.

Cross-session environment facts Kariim should never have to repeat — what's
installed, what a surface can and cannot reach (e.g. a cloud session CANNOT execute
or install on the laptop; the screen bridge is vision-IN only), verified
hosts/versions/paths — get written into PROGRESS.md (and the relay for other
surfaces) the SAME session they're learned, so the next surface reads them cold
instead of re-litigating them with him. Approved rule, 2026-07-22.
