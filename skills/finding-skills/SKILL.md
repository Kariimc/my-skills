---
name: finding-skills
description: Retrieve the existing skills that fit a task before building from scratch or saying something can't be done. Use when the user wants to start any non-trivial task, when you're about to answer from scratch, or the moment you're tempted to say you "can't" / "have no way to" — run tool/find-skills.py first, load the top matches, and act. Only a genuinely empty result licenses "can't", and it must name the exact missing access (token / connector / surface).
---

# Finding skills — consult before you build or refuse

`skill-doctor.sh` guarantees every skill is *findable* (good triggers, no
overlap, ≤1024 chars). This skill is the missing other half: it makes the model
*look*. It is the forcing function rule `09-consult-skills` points at.

Composes with the rest of the control plane, does not duplicate it:
- **skill-doctor** = description *quality*. **This** = description *consultation*.
- **harness-router** forces selection for the 6 harnesses. **This** covers the
  other ~412 long-tail skills, which had no forcing function.
- **relay** carries global *state* across surfaces. **This** rides the same
  rails (local clone → public raw URL) so consultation works identically on
  chat, local/cloud Claude Code, and Cowork.

## Use it
```
python3 tool/find-skills.py "<the task in a few words>"      # top 5
python3 tool/find-skills.py -k 8 --json "<task>"             # machine-readable
python3 tool/find-skills.py --remote "<task>"                # force public API
```

## Source order (relay-style, portable)
1. Local `index.json` (this dir), or `--index PATH`, or `./index.json` — used
   whenever a clone / `~/.claude` sync is present.
2. Else fetch the committed index over the public API:
   `raw.githubusercontent.com/Kariimc/my-skills/master/skills/finding-skills/index.json`
   — one request, not 418. Regenerate with `tool/build-index.py skills index.json`.

## Output contract
Ranked `[score] name  path` lines, or the explicit line
`NO SKILL MATCH …` — which is the **only** state in which "can't" is allowed,
and even then you name the exact missing access, never a vague refusal.

## Honest limitation (and the upgrade path)
Ranking is lexical (term overlap + light stemming + bigram bonus). It is strong
on literal-owner tasks (angular→`angular-developer`, pdf→`pdf`, docx→`docx`) and
returns *adjacent* candidates on pure-intent tasks ("do 3 things at once" won't
surface `dispatching-parallel-agents`). Backstop: in Claude Code all 418
descriptions are already in context. **Upgrade path:** swap the ranker body for
an embedding index — the CLI and `index.json` contract stay identical.

## Guardrail
Trivial tasks skip the consult (don't over-process). `eval/eval.sh` gates
recall@5 ≥ 0.85 over `eval/cases.jsonl` so this can't silently rot.
