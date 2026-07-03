# Rules

Markdown files here are concatenated (sorted by filename) into your **global**
`~/.claude/CLAUDE.md` on every session start. That file is loaded as
instructions in **every** project you open — so these are your always-on rules.

| File | Purpose |
|---|---|
| `02-harnesses.md` | The six ultimate harnesses and when each applies. |
| `03-apex.md` | Apex gates: the control-plane quality bar and how it's enforced. |
| `04-response-mode.md` | LEARNING MODE (my-coding-journey only, teaching rules live in that repo's CLAUDE.md) vs APEX MODE (dense, deliverable-first) everywhere else. |
| `05-github-workflow.md` | Autonomous git/GitHub flow — branch, commit, PR; ask only before merging to master. |
| `06-silent-execution.md` | No narration before/during/after tool runs; deliver outcomes only. |
| `07-progress-file.md` | Read/maintain PROGRESS.md as the session handoff in any repo. |
| `08-deliverable-only.md` | Reply shape is prompt → deliverable; no process talk, no mechanics. |
| `idp-control-plane.md` | Lean IDP lifecycle — understand → prototype gate (new builds) → build → validate (correctness/security/perf/simplicity/loop-safety) → document. |

Learning-mode teaching rules (explain-like-I'm-five, step-by-step, 🎓 recaps)
moved into `C:\Dev\my-coding-journey\CLAUDE.md` — they load only there.

## How to use
- **Add a rule set:** drop a new `NN-name.md` file here. Use a numeric prefix to
  control ordering (e.g. `00-base.md`, `10-style.md`). It goes global on the
  next session, or run `/sync-skills` to apply now.
- **Edit a rule:** change the file and re-sync. The whole `~/.claude/CLAUDE.md`
  is rebuilt from this folder each time, so there are no stale leftovers.

> Keep rules lean. Everything here is prepended to every conversation in every
> project, so it costs context on each turn.
