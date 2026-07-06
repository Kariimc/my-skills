---
name: relay
description: Read and write the Kariimc/relay cross-surface handoff system — HANDOFF.md global state, per-surface inboxes, and the append-only log. Use when a Claude surface (chat, Claude Code local/cloud, Cowork, Steam Deck) needs to load shared state at session start, message another surface, or record what changed before ending a session.
---

# Relay — cross-surface communication and shared state

The Relay is a small **public** GitHub repo, `Kariimc/relay`, that every Claude
surface Riimos uses can reach. GitHub is the only store all surfaces share:
chat reads it over the public API, every Claude Code machine has git, and
Cowork has the local clone. The Relay sits **above** per-repo `PROGRESS.md`
files: `PROGRESS.md` = one project's state; the Relay = everything, across
projects and across surfaces.

**It is public. Never put secrets in it.**

## Repo layout

```
relay/
  HANDOFF.md          ← THE single source of truth: current global state
  inbox/
    chat.md           ← messages TO claude.ai chat
    code-local.md     ← messages TO local Claude Code (Windows)
    code-cloud.md     ← messages TO cloud Claude Code
    cowork.md         ← messages TO Desktop/Cowork
    steamdeck.md      ← messages TO Steam Deck Claude Code
  log.md              ← append-only event log, one line each, newest on top
  README.md           ← plain-language explanation of the system
```

## Protocol

1. **Session start:** read `HANDOFF.md`, then your own inbox file. Prefer a
   local `git pull` + read if the repo is cloned; otherwise fetch the raw URLs
   (`https://raw.githubusercontent.com/Kariimc/relay/main/...`). Act on
   messages, then clear the handled entries (leave the `# Inbox: <surface>`
   header and the `---` line).
2. **Message another surface:** append a dated entry to its inbox file, e.g.
   `2026-07-06 (from code-cloud): <message>`.
3. **Before ending a session where state changed:** update `HANDOFF.md` and add
   one line to the top of `log.md`.
4. **Commit messages:** `relay: <surface> — <one-line summary>`.
5. **Chat can't push.** When chat needs to write, it hands Riimos one
   paste-block that any Claude Code session runs — the accepted bridge.

## Exact HANDOFF.md format (write it identically every time)

```markdown
# HANDOFF — global state (read me first)
Updated: <date> by <surface>

## Who Riimos is / how to work with him
Solo dev. Voice-to-text (silently fix speech artifacts). Plain language, zero
jargon. Lead with the answer. Act by default. One-paste deliverables only.
Never claim done unless 100% working.

## Active projects & where they live
| Project | Location | State | Next step |
|---|---|---|---|
| ... | ... | ... | ... |

## Infrastructure that already exists (do not rebuild)
- my-skills repo → ~/.claude/ via SessionStart hook; rules 00, 07 (progress), 08 (relay)
- PROGRESS.md per-repo handoff (rule 07)
- Relay (this repo)
- claude-eyes, second-brain (C:\Dev\brain), cloud-setup-prompt.md

## In flight right now
- <bullets>

## Open decisions / blockers needing Riimos
- <bullets>

## Standing constraints
- HoopClone lives outside OneDrive (path corruption history). Relay is PUBLIC — no secrets ever.
```

Keep entries terse and current — the Relay is only useful if every surface can
trust `HANDOFF.md` to be the truth.
