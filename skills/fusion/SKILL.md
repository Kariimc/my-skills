---
name: fusion
description: Run a question through a crew of the smartest models, each on the job it is best at — Sonnet 5 researches and writes the plan, Opus 5 builds, a partner model (GPT-5.6 Sol or Gemini) builds and synthesizes, and Fable 5 verifies and sets the standard the others are held to next time. All at high reasoning effort, with automatic cover when a model is rate-limited or retired. Use when the user says "fusion", "use all the brains", "two brains", "three brains", "use Claude and GPT and Gemini", "cross-check this with another model", "get a second opinion from a different model", or wants the strongest possible answer on a hard, expensive, or hard-to-reverse question. Do NOT use for quick lookups or routine work — it costs many model calls.
metadata:
  engine: skills/council-moa/scripts/council.py
---

# Fusion — a crew of the smartest models, each on its own job

One question, four jobs, four models. Nobody marks their own homework except
where no other model is reachable, and the run says so when that happens.

| Job | Model | What it does |
|---|---|---|
| Research + plan | **Sonnet 5** | digs into the question and writes the plan the builders follow |
| Build | **Opus 5** | builds the answer |
| Build + synthesize | **the partner** — GPT-5.6 Sol, else Gemini 3.6 Flash | builds its own answer, then merges every builder's work into one |
| Verify | **Fable 5** | attacks the result; its rulings become the standard everyone starts from next time |

Every model runs at **high** reasoning effort. There are no budget tiers
anywhere — no Haiku, no Luna, no mini or nano. When a model is unavailable its
job goes to the next *smartest* model, never a cheaper one.

## Run it

    python3 skills/council-moa/scripts/council.py "<the question>" --provider fusion --depth deep

See the crew and who covers whom, without spending anything:

    python3 skills/council-moa/scripts/council.py --brains

Depths: `quick` (no debate, no verify), `deep` (default, full loop), `max` (deep
plus live web grounding where the model supports it). `--save record.md` writes
the full working; `--json` gives the raw record.

## Keys — one file, once

`~/.claude/fusion.env`, plain lines:

    ANTHROPIC_API_KEY=...     # Sonnet 5 + Opus 5 + Fable 5   console.anthropic.com
    OPENAI_API_KEY=...        # the partner, GPT-5.6 Sol      platform.openai.com/api-keys
    GEMINI_API_KEY=...        # partner fallback              aistudio.google.com/apikey
    HF_TOKEN=...              # last-resort cover             huggingface.co/settings/tokens

Outside every repo, so it can never be committed. A real environment variable
beats the file, and the run says so when that happens.

The Anthropic key alone gives you three of the four jobs. Add OpenAI or Google
and the crew is complete — with only Claude reachable, the partner falls back to
Opus 5 and the run prints **NO PARTNER MODEL REACHABLE** rather than quietly
pretending.

## The crew notebook — they all learn from each other

One file, `~/.claude/fusion-lessons.md`, written after every run and read by
**every model** — including Fable 5 — before it writes a word on the next one.
It has two halves:

- **Rulings** — what Fable 5 caught. Binding. "Do not repeat these."
- **Crewmate notes** — what each model actually brought, attributed by model
  name and score: *"claude-opus-5 as The Skeptic (scored 9/10): strongest — named
  the failure mode nobody priced in; blind spot — no cost estimate."* Every model
  reads its colleagues' track record, and its own.

So the learning runs in both directions: down from the Verifier, and sideways
between the models. Within a single run they already read each other's answers
before revising; the notebook is what makes that survive to the next run. Notes
accumulate, and the oldest are trimmed when the file outgrows its budget.

**Being straight about what this is.** It is carried context, not training. The
models' weights never change and Sonnet does not become Fable. What changes is
the instruction every model works under — the mistakes already caught, and the
moves that already scored, arrive with the question. That raises the floor of the
work run after run. It does not raise the ceiling of any single model.

## When a model can't be used

Two different problems, two different moves, both printed:

- **The model is gone** — renamed, retired, not on your account → its job passes
  to the next model in that job's chain. Retrying the same one would never help.
- **The model is rate-limited** → same thing, next model in the chain, ending at
  the open-model reserve on Hugging Face (chosen live from the router's own
  catalogue, so a renamed open model can't strand a run either).

A real error — bad key, malformed request — is neither, and stops the run with
its actual message instead of being retried around.

## Nothing degrades quietly

Every model that is **not** taking part is named, with the reason and the exact
key that was looked for:

    [fusion] Gemini (Google AI Studio) — NOT USED: no key found (looked for GEMINI_API_KEY or GOOGLE_API_KEY)

The same for everything else that would lower quality without telling you: a job
handed to a cover model, a model that would not run at high effort (its answers
are then flagged as below the effort you asked for), no partner reachable, a
keyfile entry the environment overrode, a builder that never answered, a
verification that did not run (the answer is then labelled UNVERIFIED), a
refinement that failed to fix what Fable 5 found, a crew notebook that could not
be written. All on stderr. Clean output means nothing was skipped.

## Changing the crew

`--config` takes a JSON file. `"crew"` replaces any job's model chain (owner
first, then who covers it); `"brain_order"` changes which company is preferred.
See `skills/council-moa/scripts/council.config.json` for a worked example.

## Cost

A `deep` run is roughly 12–16 calls, all on flagship models at high effort. This
is the expensive setting on purpose. Use `quick` (about 6) when the answer does
not need to survive an attack, and don't use fusion for lookups.

## Proof

`python3 skills/council-moa/scripts/selftest_fusion.py` — 76 checks, no keys and
no network: the crew assignment, no budget tiers anywhere, cover-by-next-smartest
rather than by-cheaper, the notebook reaching every worker's prompt (Verifier and
researcher included) with peer notes attributed by model, the full pipeline
landing each job on the right model, the loud-failure guarantees, and backward
compatibility with single-model callers.

Bite-tested: taking Fable 5 off verification turns 3 checks red, collapsing the
two builders onto one model turns 4 red, and cutting the notebook out of the
prompts turns 4 red.

**Not proven:** no live run has happened. This cloud box holds no API keys, so
every model id is verified from vendor documentation, not from a response.
