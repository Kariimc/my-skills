---
name: skill-launcher
description: A visual launcher for the whole skill library — see every skill sorted into goal groups, get task-based suggestions, and one-click copy the exact thing to paste into Claude so you never have to remember commands. Use when the user asks "what skills do I have", "which skill for X", "show me my skills", "what can I do", "skill launcher", "skill menu", "I forget the commands", or wants to browse/search skills or run several in a recipe. Builds a self-contained web GUI (Artifact or localhost) from the live skills library.
license: Apache 2.0
version: 1.0.0
---

# Skill Launcher

A GUI so the user never has to remember commands. It scans the whole skills library and
builds a self-contained web app: a **task box** ("what do you want to do?") that ranks the
best-matching skills, **goal groups** to browse (Build · Design · Fix & Debug · Research ·
Write · Automate & Loop · Manage repo & config), **favorites**, and **recipes** that copy a
multi-skill sequence in one click. Every button copies the exact text to paste into Claude.

## The honest constraint (state it if the user expects true 1-click execution)

A web page cannot inject a prompt into the Claude Code / desktop app — there's no API for
that. So **"run" = copy-to-paste**: click a skill and it copies `/skill-name` or a filled-in
starter prompt; the user pastes it (one paste, nothing to remember). The copy has a
clipboard-API path plus an `execCommand` fallback plus a manual-prompt last resort, so it
works even inside a sandboxed Artifact iframe.

## Build / open it

- **Regenerate from the live library** (do this so it reflects the current skills):
  `python3 tools/build_launcher.py` → writes `skill-launcher.html` (self-contained) and
  `skills.json`. It reads every `skills/<name>/SKILL.md` frontmatter for the name +
  description and classifies each skill into a goal from its own words.
- **As an always-available Artifact** (best for the desktop app): publish
  `skill-launcher.html` as an Artifact. It's self-contained (data embedded inline, no
  external requests), so it works under the Artifact CSP.
- **As a localhost app:** just open `skill-launcher.html` in a browser — no server needed
  (all data is inline).

## Keep it fresh

The skill list changes as skills are added. Re-run `build_launcher.py` after adding skills
(or on a schedule) and republish the Artifact to the **same URL** (pass the artifact `url`)
so the launcher's link stays stable.

## Extending it

- **Recipes** live in the `RECIPES` array in `tools/build_launcher.py` — add the user's
  common multi-skill flows there (name, chain, the prompt it copies).
- **Goal classification** is keyword-scored in `GOAL_KEYWORDS`; adjust the keywords to
  re-balance the groups.
- **Agents** (the 73 subagents) can be added as a second data source the same way skills are
  — a natural v2.
