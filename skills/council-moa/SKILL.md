---
name: council-moa
description: Run a mixture-of-agents council to produce one synthesized, verified decision instead of a single off-the-cuff answer. Use this whenever a decision, recommendation, architecture or design choice, plan, tradeoff, strategy, or open-ended question is high-stakes, ambiguous, contested, or hard to reverse — and whenever the user asks for "the best possible answer", a second opinion, multiple perspectives, a panel/council/debate, or to "stress-test", "pressure-test", or "red-team" an idea. Multiple advisor agents propose independently through distinct lenses, debate, an Arbiter synthesizes the strongest answer, and an adversary verifies it. Do NOT use for routine, low-stakes, factual-lookup, formatting, or trivially-answerable requests where the extra model calls aren't worth the cost and latency.
---

# Council — Mixture-of-Agents decision engine

Turns one question into a deliberated, verified decision. A council of advisors —
each committed to a single lens — answers independently, debates, an **Arbiter**
synthesizes one answer better than any of them, and an **Adversary** stress-tests
it; material holes trigger one revision. You get back a decision that has already
survived its own jury, plus a full audit trail.

Pipeline: **triage → propose → debate → synthesize → verify → refine.**

## When to use
- High-stakes, ambiguous, contested, or irreversible decisions and recommendations.
- Architecture / design / strategy calls; "which approach", "should we", "is X worth it".
- The user explicitly wants the best answer, a second opinion, multiple perspectives, a debate, or to stress-test / red-team a plan.

## When NOT to use
- Routine or low-stakes questions, simple lookups, formatting, or anything with one obvious answer.
- Latency- or cost-sensitive paths (a full run is many model calls). Default to `quick` when embedding; `deep`/`max` for deliberate decisions.

## How to run it (preferred): the bundled engine

Run from this skill's directory. It auto-detects `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`.

```bash
python scripts/council.py "QUESTION HERE" --depth deep
```

- `--depth quick|deep|max` — quick = 4 advisors + synthesis; deep = adaptive council + debate + verify + refine; max = adds live web grounding.
- `--save report.md` — write the full deliberation as Markdown. `--json` — emit the whole record. `--grounded/--no-grounded` — force grounding (Anthropic).

As a library (Python or TypeScript) or in app code, see **`references/integration.md`** — it covers importing the engine, mixed-tier models (cheap proposers + strong arbiter), and wiring into request handlers / CI. Read it whenever the task is to embed the council in a project rather than run it once.

## Running it inline (fallback — when you cannot execute the script)

If code execution isn't available, perform a lightweight council yourself in-context:

1. **Seat 4 advisors** for the question (always include the Skeptic). Lenses:
   Pragmatist (what works), Skeptic (risk & failure), Analyst (rigor & tradeoffs),
   Visionary (ambition), Humanist (people & ethics), Engineer (build & correctness),
   Strategist (incentives & game).
2. **Propose** — answer the question once per advisor, each fully committed to its lens, no hedging or converging.
3. **Debate** — let each advisor revise after seeing the others: concede what they missed, sharpen real disagreements.
4. **Synthesize** — as the Arbiter, reason about where they agree (high confidence), where they conflict and who's right, and what they all missed; then write one decisive answer that beats them all. State confidence and what would change it.
5. **Verify** — as an independent Adversary, attack the decision: does it answer the question, is it factually sound, what's missing or overconfident? List only material problems.
6. **Refine once** — if material problems exist, revise the decision to fix them.

Show the user the final decision; offer the reasoning/audit if useful. The bundled engine does all of this with parallel calls and is preferred when you can run it.

## Output
The decision (markdown) is the deliverable. The full record also carries: the seated
council and why, each advisor's draft and rebuttal, per-advisor scores, the consensus
level, the verification verdict and any issues, and what refinement changed.
