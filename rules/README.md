# Rules

Markdown files here are concatenated (sorted by filename) into your **global**
`~/.claude/CLAUDE.md` on every session start. That file is loaded as
instructions in **every** project you open — so these are your always-on rules.

| File | Purpose |
|---|---|
| `00-communication-style.md` | Always-on style: explain all jargon in plain 5-year-old terms, and give numbered step-by-step instructions for anything the user must do. |
| `idp-control-plane.md` | The "Internal Developer Platform" operating ruleset — identity, the master execution loop, connector discovery, prototype gates, quality gates, and output format. |

## How to use
- **Add a rule set:** drop a new `NN-name.md` file here. Use a numeric prefix to
  control ordering (e.g. `00-base.md`, `10-style.md`). It goes global on the
  next session, or run `/sync-skills` to apply now.
- **Edit a rule:** change the file and re-sync. The whole `~/.claude/CLAUDE.md`
  is rebuilt from this folder each time, so there are no stale leftovers.

> Keep rules lean. Everything here is prepended to every conversation in every
> project, so it costs context on each turn.
