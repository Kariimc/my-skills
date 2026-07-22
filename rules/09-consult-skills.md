# Consult skills before building or refusing (fires on every non-trivial task)

`skill-doctor` proves the 418 skills are findable; it does not make you look.
This rule makes you look — and it is what stops the "acts helpless / says can't"
failure when a skill already exists.

Before you build a non-trivial task from scratch, and **always** before you say
"can't" / "not possible" / "no way to":

- **Consult the library.** Prefer local: if `~/.claude/skills` or a `my-skills`
  clone is present, run
  `python3 skills/finding-skills/tool/find-skills.py "<task>"`. Otherwise fetch
  the committed index over the public API (relay-style) and rank —
  `find-skills.py --remote "<task>"` does both.
- **Load the top 1–3 matches and use them.** A named owner (e.g. pdf, docx,
  angular-developer) means you do not hand-roll it.
- **Only an empty result (`NO SKILL MATCH`) licenses "can't"** — and then name
  the exact missing access (which token, connector, or surface), never a vague
  refusal. "I can't reach the skill library from this surface" is itself a
  precise, correct gap, not helplessness.

## Exhaust every channel you hold — not just the skills library

Skills are one channel. Before you offload a fetch/install to the user, or say
"can't reach it," **enumerate and TEST every channel you actually hold this
session** — MCP connectors (`ListConnectors`), the session browser
(Chromium/Playwright), `WebFetch`/`WebSearch`, GitHub raw, `pip`/`npm`. Asking
the user to do a thing you have the tools for is a last resort, not a first move.
A 403/blocked on *one* path is not "impossible" — it's one path; probe the
others. (Cost of skipping this: a whole session of the user repeating "you have
a browser," "use huggingface," "you can download it yourself." Approved rule,
2026-07-22.)

Portable by design: same behaviour on chat (fetch index), local/cloud Claude
Code (local index or `~/.claude`), and Cowork — like the relay (rule 08).

Trivial tasks skip this — do not over-process. Full protocol and the honest
limits live in the `finding-skills` skill.
