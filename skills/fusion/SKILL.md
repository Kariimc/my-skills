---
name: fusion
description: Put Claude, GPT/Codex, and Gemini (Google AI Studio) on the SAME question at once — each answers independently, they read each other and revise, one brand synthesizes the final answer and a RIVAL brand tries to tear it down. Falls back to open models on Hugging Face when a brain is rate-limited. Use when the user says "fusion", "use all the brains", "two brains", "three brains", "ask Claude and GPT and Gemini", "cross-check this with another model", "get a second opinion from a different model", or wants the strongest possible answer on a hard, expensive, or hard-to-reverse decision. Do NOT use for quick lookups or routine work — it costs several model calls.
metadata:
  engine: skills/council-moa/scripts/council.py
---

# Fusion — several companies' models on one question

Same council pipeline as `council-moa`, but every seat runs on a **different
company's model**. That is the whole point: a model checking its own answer
shares its own blind spots. A rival's model does not.

    triage → each advisor answers → they read each other and revise
          → one brand synthesizes → a DIFFERENT brand attacks it → fix → answer

## Run it

    python3 skills/council-moa/scripts/council.py "<the question>" --provider fusion --depth deep

See who is live and who sits where, without spending anything:

    python3 skills/council-moa/scripts/council.py --brains

Depths: `quick` (no debate, no verify — cheap), `deep` (default, full loop),
`max` (deep + live web grounding on the brains that support it).
Add `--save record.md` for the full deliberation, `--json` for the raw record.

## Keys — one file, once

Put whatever you have in `~/.claude/fusion.env`, plain lines, no quotes needed:

    ANTHROPIC_API_KEY=...     # Claude          console.anthropic.com
    OPENAI_API_KEY=...        # GPT / Codex     platform.openai.com/api-keys
    GEMINI_API_KEY=...        # Google AI Studio  aistudio.google.com/apikey
    HF_TOKEN=...              # reserve brain   huggingface.co/settings/tokens

That file is outside every repo, so it can never be committed. A real
environment variable always wins over it, and the run says so out loud when it
does.

One key works — it just isn't fusion, and the run says that too. Two is the
point. Three is better.

## Who sits where

| Seat | Brain | Why |
|---|---|---|
| Convener | the last brain in the order | cheap job, picks which four lenses to seat |
| Advisors | dealt round-robin across every brain | four different lenses on four different models |
| Arbiter | the strongest brain available | writes the final answer |
| Adversary | **never the Arbiter's brand** | a rival tries to break the answer |
| Reserve | Hugging Face open models | only used when a brain is rate-limited |

Strength order defaults to Claude → GPT → Gemini → Hugging Face. Change it with
`"brain_order"` in a config file passed to `--config`. Advisor seats are
re-dealt after the Convener picks the council, so no brain sits idle.

## When a brain is rate-limited

The seat is handed to the next brain, then to the next, and finally to the
smartest open model the Hugging Face router will serve right now — the model is
looked up live, never hard-coded, so a renamed or retired model can't strand a
run. Every handover prints which brain dropped out and who took over.

A real error — bad key, malformed request — is never treated as a rate limit and
never retried around. It stops the run with the real message.

## A model that can't be used is always reported

Every brain that is **not** taking part is named, with the reason and the exact
key it looked for — never just missing from the roster:

    [fusion] Gemini (Google AI Studio) — NOT USED: no key found (looked for GEMINI_API_KEY or GOOGLE_API_KEY)

The same goes for everything else that could quietly lower quality: a brain
handing over its seat mid-run, a keyfile entry the environment overrode, an
advisor that never answered, a verification that did not run (the answer is then
labelled UNVERIFIED), a refinement that failed to fix what the Adversary found, a
model that rejected JSON mode, a single-brain run pretending to be fusion.
All of it goes to stderr. If the output is clean, nothing was skipped.

## Pick the agents first

Same standing rule as `council-moa`: before dispatching, ask which models to use
— one question for the advisors, one for the Arbiter/Adversary pair. Recommended
first pick is the default seating above.

## Cost

A `deep` run is roughly 12–16 model calls. Use `quick` (about 6) when the answer
does not need to survive an attack. Not for lookups.

## Proof

`python3 skills/council-moa/scripts/selftest_fusion.py` — 45 checks covering
seating, the re-deal, cross-brand verification, rate-limit failover, the Hugging
Face ladder, the loud-failure guarantees, and backward compatibility with
single-model callers. No keys or network needed.
