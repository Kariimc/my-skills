# Rules

Markdown files here are concatenated (sorted by filename) into your **global**
`~/.claude/CLAUDE.md` on every session start. That file is loaded as
instructions in **every** project you open — so these are your always-on rules.

The set is deliberately Karpathy-shaped: one core loop (understand → smallest
change → verify → distill), a short leash with diff-level transparency, and
orchestration only where a simple loop genuinely can't do the job.

| File | Purpose |
|---|---|
| `00-core.md` | The core loop: understand first, smallest change, prove it, distill. Short leash; autonomy scales with verification. Preview gate for brand-new builds. |
| `02-harnesses.md` | Orchestration inverted: default simple; six harness skills only when a task exceeds one context. Complexity must pay rent. |
| `03-apex.md` | Gates are law: never bypass, fix the gate instead; ratchet each escaped mistake into a permanent check. |
| `04-response-mode.md` | Output style: learning mode in my-coding-journey only; everywhere else write like a good commit message — outcome first, show the diff, evidence over vibes. |
| `05-github-workflow.md` | Autonomous git/GitHub; small single-purpose commits; the one gate is merging to master. |
| `07-progress-file.md` | Read/maintain PROGRESS.md as the session handoff in any repo. |
| `08-relay.md` | Read/write the Kariimc/relay cross-surface handoff system every session: global HANDOFF.md state, per-surface inboxes, append-only log. |

Learning-mode teaching rules (explain-like-I'm-five, step-by-step, 🎓 recaps)
live in `C:\Dev\my-coding-journey\CLAUDE.md` — they load only there.

## How to use
- **Add a rule set:** drop a new `NN-name.md` file here. Use a numeric prefix to
  control ordering (e.g. `00-base.md`, `10-style.md`). It goes global on the
  next session, or run `/sync-skills` to apply now.
- **Edit a rule:** change the file and re-sync. The whole `~/.claude/CLAUDE.md`
  is rebuilt from this folder each time, so there are no stale leftovers.

> Keep rules lean. Everything here is prepended to every conversation in every
> project, so it costs context on each turn.
