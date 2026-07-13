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

Portable by design: same behaviour on chat (fetch index), local/cloud Claude
Code (local index or `~/.claude`), and Cowork — like the relay (rule 08).

Trivial tasks skip this — do not over-process. Full protocol and the honest
limits live in the `finding-skills` skill.
