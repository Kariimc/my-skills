# Progress files (PROGRESS.md)

At the start of work in any repository, if `./PROGRESS.md` exists, read it before
anything else. It is the handoff from the last session: current focus, the next
action, gotchas, and key decisions. If it conflicts with the code, the code wins —
fix the file in the same session.

Maintain it with the `project-context-loader` skill: update at session end and
before any handoff, not on every change. Keep it at the repo root, committed to
git, separate from CLAUDE.md (CLAUDE.md = durable rules, PROGRESS.md = live state).
