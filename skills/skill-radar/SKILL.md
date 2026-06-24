---
name: skill-radar
description: >-
  Discover the best NEW Claude skills and GitHub repos worth adopting — scan
  what's trending in the last 30 days, vet each candidate against the skills you
  already have, then ship the winners. Pairs the `last30days` trend radar with
  `skill-scout` and `skill-ship`. Use when the user wants to find new
  skills/plugins/repos to add, scout a domain for trending tools, or decide
  what's worth adopting before building a skill from scratch.
metadata:
  origin: authored
  family: skill-discovery-kit
tools: Read, Write, Bash, Grep, Glob, Task, WebSearch, WebFetch, AskUserQuestion
user-invocable: true
---

# Skill Radar — discover, vet, and adopt new skills

A discovery kit that wires three skills into one loop:

- **`last30days`** finds what's *new and trending* (GitHub, Hacker News, Reddit,
  X, YouTube, the web) in the last 30 days.
- **`skill-scout`** *vets* each candidate against what you already have and flags
  anything unsafe or duplicate.
- **`skill-ship`** *adopts* the winners into this repo with no drift.

The discipline: **never adopt on hype.** Every candidate is deduped against your
installed skills and security-reviewed before it lands.

## When to use
- "What new skills / repos should I add?" or "find me trending Claude skills."
- Scouting a domain (e.g. "AI video tools", "agent frameworks") for fresh tooling.
- Before building a skill from scratch — check whether a better one already shipped.

## The loop

```
TOPIC → [last30days] trend scan → [skill-scout] vet & dedupe → DECIDE → [skill-ship] adopt
            (what's hot)             (is it new? safe?)         (you)        (land it)
```

### 1. Radar — what's new (`last30days`)
Run `last30days` on the topic to surface recent, high-engagement candidates and
rank them by real signals (stars, upvotes, discussion) inside the window. Favor
GitHub repos and Claude skills/plugins with genuine traction.

```
last30days <topic>        # e.g. "claude code skills", "AI agent frameworks"
```

Coverage widens with optional API keys (see the `last30days` frontmatter
`optionalEnv`); it still runs keyless via web search, just with fewer sources.
Output: a ranked candidate list with links and why-it's-trending notes.

### 2. Scout — vet & dedupe (`skill-scout`)
For each candidate, run `skill-scout`'s workflow: search your **local +
marketplace** skills first to catch duplicates among the skills you already have,
then read the external `SKILL.md`, confirm the license and that the repo looks
maintained, and scan for risky shell, network, or credential behavior. Drop
duplicates and anything unsafe.

### 3. Decide (you)
Present a short ranked table and let the user choose — never auto-adopt:

```markdown
| # | Candidate | Source | Why it's worth it | Overlap w/ existing | Risk |
| - | --------- | ------ | ----------------- | ------------------- | ---- |
```

Options per row: **adopt** / **fork & adapt** / **skip**.

### 4. Adopt — land it (`skill-ship`)
For each approved winner, hand off to `skill-ship`: vendor into `skills/`,
validate frontmatter, de-collide triggers, reconcile README counts, sync to
`~/.claude`, verify it's live, then commit. `skill-ship` is the only blessed way
to land a skill in this control plane.

## Guardrails
- Hype ≠ quality. A trending repo still has to pass scout's vetting + dedupe.
- Never adopt an external skill without reading its `SKILL.md` and checking the
  license. Prefer copying into a branch and reviewing the diff over editing
  marketplace originals in place.
- Respect the apex gates — land only through `skill-ship`, never by hand.

## Related
- `last30days` — the trend radar (Reddit / X / YouTube / HN / GitHub / web).
- `skill-scout` — search + vet local / marketplace / GitHub / web skill sources.
- `skill-ship` — add or change a skill correctly, with no drift left behind.
- `skill-stocktake` — audit installed skills for health, duplicates, and gaps.
