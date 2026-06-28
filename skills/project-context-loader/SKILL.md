---
name: project-context-loader
description: Read and maintain a project's PROGRESS.md handoff file so any new session knows exactly where work left off without a manual handoff. Use at the START of work in any repo (read PROGRESS.md first if it exists), when WRAPPING UP a session, and whenever the user says "where did we leave off", "update progress", "hand this off", or "save where we are". Also use right after shipping a meaningful change or making an architecture decision worth recording.
---

# project-context-loader

Maintains one living handoff file, `PROGRESS.md`, at the repo root. It carries what git can't: current focus, the next action, gotchas, and why the code is built the way it is. Git already records what changed in each file — this file records intent and state, so a cold session starts knowing where it is.

## At the start of work in a repo
1. If `./PROGRESS.md` exists, read it before doing anything else. Treat **Do next** as the default starting point and **Don't forget** as live constraints.
2. If it conflicts with the actual code, the code wins. Note the drift and fix the file as part of this session.
3. If it's missing and this is a real project (not a throwaway), stamp out the template below.

## When wrapping up (or asked to update progress / hand off)
Update these, and nothing else — do not rewrite history:
- **Updated** date + **Last verified** — what you actually ran and saw work, stated plainly (e.g. "tests pass", "boots to court screen", or "not verified this session"). This is the staleness signal; never claim verification you didn't do.
- **Where we are** — what works end-to-end now, what's half-done.
- **Do next** — the single most useful next action, concrete enough to start cold.
- **Don't forget** — add any new gotcha found this session.
- **Why it's built this way** — append ONE dated line per real decision. Append-only; never delete past lines.

## Cadence — the rule that keeps this honest
Update at session end and before any handoff — NOT on every small change. Continuous edits are what make these files rot and start lying. One accurate update per session beats ten partial ones.

## Template (stamp this out for a new file)
Use a fenced markdown code block containing:
# <Project> — Progress
**Updated:** <YYYY-MM-DD> · **Last verified:** <what actually ran and worked, or "not verified">
## Where we are
<2-3 lines: what works right now, what's half-done>
## Do next
<the one concrete next action>
## Don't forget
<gotchas that break things if unknown; "none yet" is fine>
## Why it's built this way
- <YYYY-MM-DD> - chose X over Y because Z

## Rules
- One file per repo, at the root, committed to git so it travels with the code across machines and sessions.
- Keep it short. Empty section → write "none yet", don't pad.
- This is the handoff, not a changelog. Don't duplicate per-file history git already has.
- Lives alongside CLAUDE.md, never inside it: CLAUDE.md holds durable rules; PROGRESS.md holds churning state.
