# my-skills

My personal control repo for Claude Code. It's the **single source of truth**
for the skills, rules, and slash commands that Claude uses across **every**
project — not just this one.

Maintained by Kariim (Plainfield, NJ). 🧑‍💻

---

## How it works (the 10-year-old version)

Think of this repo as a **toy box**, and `~/.claude/` as the **shelf in your
room** where Claude always looks for its toys. Every time Claude wakes up
(starts a session), a little helper script runs and **copies everything from
the toy box onto the shelf**. So no matter which project you open, the same
skills, rules, and commands are right there waiting.

```
   THIS REPO (source of truth)                 ~/.claude/ (read by EVERY project)
   ────────────────────────────                ──────────────────────────────────
   skills/      ──┐                             ~/.claude/skills/      (auto-loaded)
   rules/       ──┤  SessionStart hook copies   ~/.claude/CLAUDE.md    (global rules)
   commands/    ──┘  on every session start →   ~/.claude/commands/    (slash cmds)
```

The hook that does this lives at `.claude/hooks/session-start.sh` and is wired
up in `.claude/settings.json`.

---

## Make it global (one-time setup per computer)

Out of the box the hook only runs when you open **this** repo. To make all
skills load in **every** project on your machine, run the installer once. It
registers a global SessionStart hook in `~/.claude/settings.json` pointing at
your local clone, and does an immediate sync.

1. Clone this repo somewhere on your computer (e.g. `git clone https://github.com/kariimc/my-skills.git`).
2. Open a terminal (on Windows use **Git Bash**) and `cd` into the folder.
3. Run: `bash install-global.sh`
4. Restart Claude Code. Your skills now load in every project, every session.

Re-running the installer is safe — it replaces the old hook instead of stacking
duplicates. Works on macOS, Linux, and Windows (Git Bash). Requires `bash` on
your PATH (Git for Windows provides it with the default install options).

---

## Repo layout

| Folder | Synced to | What it holds |
|---|---|---|
| [`skills/`](./skills/) | `~/.claude/skills/` | 383 skills, one folder each (`skills/<name>/SKILL.md`). See [the catalog](./skills/README.md). |
| [`agents/`](./agents/) | `~/.claude/agents/` | 67 specialist subagents, one `.md` each (reviewers, build-resolvers, planners). |
| [`rules/`](./rules/) | `~/.claude/CLAUDE.md` | Always-on global instructions (concatenated). |
| [`commands/`](./commands/) | `~/.claude/commands/` | Slash commands (`/new-skill`, `/sync-skills`, `/skill-audit`). |
| `.claude/` | — | This repo's own config: the sync hook + settings. Not synced out. |
| `global-skills-guide.pdf` | — | Plain-English guide to the imported ECC + ponytail batch. |

---

## How skills get used

There are **two** ways a skill runs:

1. **Automatically.** Claude reads the `description:` line in every skill's
   frontmatter and invokes the matching one when your request fits — e.g. "audit
   this login flow for vulnerabilities" auto-triggers `cybersecurity`. This is
   why the description's *"Use when the user wants to…"* clause matters most:
   it's the trigger.
2. **Manually.** Type `/<skill-name>` (e.g. `/debugger`) to force a skill.

### Step-by-step: use a skill in another project
1. Open any repo with Claude Code.
2. The SessionStart hook has already synced this repo into `~/.claude/`, so all
   52 skills are live.
3. Just describe your task — the right skill auto-fires — or type `/<name>`.

### Step-by-step: add or change a skill
1. `/new-skill my-thing` (or hand-create `skills/my-thing/SKILL.md`).
2. Make sure frontmatter `name:` **exactly equals** the folder name, and the
   `description` ends with a sharp *"Use when…"* trigger.
3. Commit & push.
4. Run `/sync-skills` to go live immediately, or just start a new session.

---

## Anatomy of a skill

```markdown
---
name: cybersecurity                      # MUST match the folder name
description: Senior AppSec expert… Use when the user wants a security review,
             vulnerability assessment, or secure-coding fixes.   # ← the trigger
---

# Body: the persona, method, and instructions Claude follows when invoked.
```

---

## Maintenance

- **Catalog:** [`skills/README.md`](./skills/README.md) — all 383 skills by category.
- **Overlap report:** [`skills/OVERLAP-REPORT.md`](./skills/OVERLAP-REPORT.md) — colliding triggers + recommended merges.
- **Audit anytime:** `/skill-audit`.

> Note: the GitHub repo was renamed to **my-skills**. If a git remote still
> points at the old `hello-world` URL, GitHub redirects it automatically.
