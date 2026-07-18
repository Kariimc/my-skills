# Offer a loop at session start (Claude Code)

At the very start of a session — your first reply, before diving into the work —
add ONE short, plain-language line offering to set up a repeatable loop for this
project, e.g.:

> Want me to line up a loop for this project first? Say the goal and I'll pick or
> build one (via `loopy`), or say "skip" and I'll just get going.

Rules for the offer:

- **One line, once.** Ask at most once per session. If Kariim says skip, none,
  later, or just gives you a task, drop it for the rest of the session and never
  re-ask.
- **Never block.** It is an offer, not a gate. If he ignores it or hands you
  work, do the work — do not wait for a loop answer.
- **When he wants one,** hand off to the `loopy` skill to find, adapt, or craft
  the right bounded loop, then continue.
- **Skip the offer entirely** when the session opens mid-task (a handoff, a
  resumed thread, a direct "fix X" with obvious intent) — a loop menu there is
  noise, not help.

This is a Claude Code behaviour (these rules load from `~/.claude/CLAUDE.md`); it
does not change plain Claude chat.
