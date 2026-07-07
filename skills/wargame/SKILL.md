---
name: wargame
description: Stress-tests a plan on paper before it's trusted — read-only recon, then a battle plan where every move has an expected observation, every failure has a named counter-move, every fork has an explicit trigger, and every unresolved assumption is flagged RECON NEEDED. Ends with abort conditions, a verification checklist, and a red-team pass. Use before scaffolding a brand-new app/feature/skill/harness (the prototype-gate moment), before handing a plan-gate or writing-plans plan to a subagent or cheaper model to execute, or any time a plan can't afford to be wrong on the first try.
---

# Wargame

A wargame is not a plan to execute — it's a plan to hand off. Write it once,
with your best judgment, so a weaker/cheaper model (or your own less-careful
future self) can run it end to end without asking a single question.

## Where this fits

This is not a replacement for `plan-gate` or `writing-plans` — it's the harder
pass you run *on top of* one of their plans when the stakes are high enough
that a wrong guess is expensive:

- **Before the prototype gate** (`00-core.md`: new app/tool/game shows a cheap
  preview before production code) — wargame the build first, so the preview
  you show is already stress-tested, not a first draft.
- **Before shipping a new skill or harness** (`skill-ship`, `new-skill`) — a
  bad skill misfires quietly for weeks; wargame it before it goes live.
- **Before delegating a `writing-plans` plan to a subagent** — the subagent
  has zero context and can't ask; a wargamed plan is what makes that safe.
- **Before a `harness-build` fan-out** — wargame the riskiest branch of the
  plan before spawning agents against it.

If the task is small enough that `plan-gate`'s 5 lines already cover it,
don't wargame it — this is for the plans that can't afford to be wrong.

## Steps

1. **Recon, read-only.** Understand the real target — the repo, the site, the
   process — before writing a single move. Never wargame from assumption.
2. **Write the battle plan**, one move at a time. Every move carries:
   - its **expected observation** — exactly what you should see if it worked
   - its **most likely failure**, the cause that failure signals, and the
     **counter-move**
   - if it forks: the **trigger** ("if you observe X, take route B") — never
     leave a judgment call to the executor
3. **Flag what recon couldn't settle.** Anything you're guessing at gets
   `RECON NEEDED: <the exact check that settles it>` — never a silent
   assumption.
4. **Add abort conditions** — the moments to stop and flag rather than
   improvise.
5. **Spell out verification** — which runs the executor performs, when, and
   what "pass" looks like for each one.
6. **Red-team it.** Attack your own plan once — find the move that breaks it
   — then patch and record both the attack and the patch in the doc. A
   wargame that hasn't survived an attack isn't done.
7. **Self-grade against the 8 points below.** Any point unmet → patch →
   re-grade. Don't hand off a plan that fails its own standard.
8. **Log the run** — mission, where the plan landed, the self-grade, and
   every patch — so the next wargame doesn't repeat a mistake this one
   already found.

## The 8-point standard (a wargame passes only if all hold)

1. Every move states its expected observation.
2. Every move carries its likely failure, cause, and counter-move.
3. Every fork has a trigger — no judgment calls left to the executor.
4. Every unresolved assumption is marked `RECON NEEDED` with the exact check.
5. Abort conditions exist.
6. Verification is spelled out — what runs, when, what pass looks like.
7. It survived a red-team pass — the attack and the patch are both on record.
8. It's executable blind — a mid-tier model could run it end to end without
   asking a question.

## Where it lands

Save the plan as `wargames/<slug>.md` (create the folder if missing) and
append one line to `wargames/LEDGER.md`: mission, draft location, self-grade,
patches made. If the project has no natural home for this, ask once where to
put it — don't scatter it.

## Handoff

Once a wargame passes all 8 points, the mission brief inside it is what goes
to the executor — not your reasoning, not this document's internal notes.
Dispatch it as: a subagent on a cheaper model (`Agent` with `model: "sonnet"`
or `"haiku"`), a fresh Claude Code session, or handed to the user to run
themselves. The executor should need nothing but the brief and the plan.

## Worked examples (this machine's real recurring missions)

> **Scaffolding a new skill** — mission: "add a skill for X."
> - Move: draft `SKILL.md`, run it against 3 representative requests.
>   - Expected observation: the description alone routes all 3 correctly.
>   - Likely failure: description overlaps an existing skill → cause: trigger
>     language too generic → counter-move: narrow the "Use when…" clause,
>     re-check against `skill-audit`.
>   - Fork: if `skill-doctor.sh` flags a HARD failure, abort and fix frontmatter
>     before continuing — don't patch around a gate.
> - Verification: `bin/skill-doctor.sh` clean, `/skill-audit` shows no new
>   collision, skill fires live in `~/.claude/skills/` after sync.

> **neon-forge-ui deploy/preview change** — mission: "ship a UI change."
> - Move: local preview via `bun run build` + `wrangler dev --port 8787`.
>   - Expected observation: HTTP 200, page renders.
>   - Likely failure: 500 → cause: `vite dev`/`bun run dev` breaks SSR on this
>     project (known gotcha) → counter-move: confirm you used `wrangler dev`,
>     not the dev server, before assuming the change is broken.
>   - RECON NEEDED: whether the Higgsfield deploy step auto-triggers on push,
>     or still needs the manual "Ask Supercomputer to deploy" step.
> - Abort condition: if the HF token is the burned/leaked one, stop and
>   surface it — don't push with a credential known to be compromised.

## Failure smell this prevents

Handing a cheaper model (or a future session) a vague brief and finding out
mid-run that it hit a fork you never resolved — burning its budget, or your
own time, on a question only careful up-front thinking could have answered.
