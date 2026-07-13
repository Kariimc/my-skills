# Implementing the Council in all your projects

One engine, four ways to consume it. The logic lives in `scripts/council.py`
(Python) and `scripts/council.ts` (TypeScript) — identical pipeline, identical
prompts. Pick the surface that fits each project; you don't need all four.

```
                      ┌─────────────────────────────┐
   any question  ───▶ │  triage → propose → debate  │ ───▶  one verified
                      │  → synthesize → verify       │       decision + audit
                      │  → refine                    │
                      └─────────────────────────────┘
        consumed as:  Skill · Python · TypeScript · CLI
```

The engine takes a **`call` function** as its only required dependency — `call(role, system, user, {wantJson, grounded})`. That seam is why it drops into any project and any provider: inject the Anthropic caller, the OpenAI caller, or your own.

---

## Surface A — as an agent skill (Claude Code / agentic workflows)

This is the "available in every project" answer. Drop the folder into your skills repo:

```bash
git clone https://github.com/Kariimc/my-skills.git
cp -r council my-skills/council
cd my-skills && git add council && git commit -m "Add council MoA skill" && git push
```

Now in any project where Claude Code / your agent loads these skills, asking for a hard decision ("should we…", "what's the best approach to…", "stress-test this plan") triggers the council automatically. The skill runs `scripts/council.py` when it can execute code, and falls back to an inline protocol when it can't (see `SKILL.md`).

---

## Surface B — Python library

```python
from council import council, anthropic_call   # scripts/council.py on your path

rec = council(
    "Should we migrate the monolith to microservices this quarter?",
    call=anthropic_call(),     # reads ANTHROPIC_API_KEY
    depth="deep",              # "quick" | "deep" | "max"
)
print(rec["decision"])         # the synthesized, verified answer (markdown)
print(rec["verification"])     # {"verdict": "pass"|"revise", "issues": [...]}
```

Wire progress into your own logging with `on_event`:

```python
council(q, call=anthropic_call(), on_event=lambda stage, status, data=None: log.info(f"{stage}:{status}"))
```

Use your own provider (no SDK assumptions) by passing any `call` with the signature
`call(role, system, user, want_json=False, grounded=False) -> str`.

---

## Surface C — TypeScript / Node (zero dependencies)

The TS engine uses global `fetch`, so it needs no packages (Node 18+, Bun, or Deno).

```ts
import { council, anthropicCall } from "./council";   // scripts/council.ts

const rec = await council("Per-seat or usage-based pricing for our SaaS?", {
  call: anthropicCall(),       // reads process.env.ANTHROPIC_API_KEY
  depth: "deep",
});
console.log(rec.decision);
```

In a request handler:

```ts
app.post("/decide", async (req, res) => {
  const rec = await council(req.body.question, { call: anthropicCall(), depth: "quick" });
  res.json({ decision: rec.decision, verification: rec.verification });
});
```

---

## Surface D — CLI (any project, any language, CI, Makefiles)

```bash
python scripts/council.py "Should we sunset the v1 API?" --depth deep
```

```bash
# pipe a question in, save the full record, machine-read the result
echo "Is Postgres or DynamoDB the right primary store for this workload?" \
  | python scripts/council.py --depth max --json > decision.json

python scripts/council.py "Approve this RFC?" --save rfc-review.md   # Markdown report
```

Node CLI equivalent: `npx tsx scripts/council.ts "your question" --depth deep`.

---

## Running it for free — no paid API key

Three zero-cost paths. The first needs no key and no setup at all.

**1. Inside Claude itself (free, no key, nothing to install).** When the council runs as a skill in claude.ai or Claude Code, *Claude is the model* — the `SKILL.md` inline protocol has Claude play the advisors, Arbiter, and Adversary in one conversation. No external API, no key, just your normal Claude usage (Claude Free works, within its message limits). Best quality of the free options, because the model is Claude. Tradeoff: it's one model running the council in a single context (a strong "self-MoA"), not N independent models — you give up true independence and parallelism but keep the structured multi-perspective reasoning and the adversarial check. For most use, this is the free version to reach for.

**2. Local model with Ollama (free forever, no key, fully private).** Runs open models on your own machine. The engine is OpenAI-compatible, so it's one preset:

```bash
# one-time: install Ollama from ollama.com, then
ollama pull llama3.1
python scripts/council.py "your question" --provider ollama --model llama3.1
```

```python
from council import council, ollama_call
rec = council("your question", call=ollama_call("llama3.1"))
```

Needs a capable machine (small 7–8B models run on modest hardware; larger models need a real GPU), and open-model output trails Claude — but it's genuinely free and offline.

**3. A free cloud key (no credit card — but still a key, and rate-limited).** Free tiers from Groq, Google Gemini, and OpenRouter expose OpenAI-compatible endpoints at no charge. Get a key, set the env var, pick the provider:

```bash
export GROQ_API_KEY=...        # console.groq.com — fast Llama/Qwen/DeepSeek
python scripts/council.py "..." --provider groq

export GEMINI_API_KEY=...      # aistudio.google.com/apikey — Gemini Flash, 1M context
python scripts/council.py "..." --provider gemini

export OPENROUTER_API_KEY=...  # openrouter.ai/keys — many ':free' models, one key
python scripts/council.py "..." --provider openrouter
```

In code: `from council import council, groq_call` then `council(q, call=groq_call())`. TS equivalents: `groqCall()`, `geminiCall()`, `openrouterCall()`, `ollamaCall()`.

**OpenRouter is the best fit for a *real* free MoA**, because one key exposes many different free models — so each role can run a *different* model and you get genuine diversity instead of one model wearing four hats:

```python
from council import council, openrouter_call
call = openrouter_call(models={
    "triage":     "meta-llama/llama-3.3-70b-instruct:free",
    "proposer":   "qwen/qwen3-coder-480b:free",
    "aggregator": "deepseek/deepseek-r1:free",
    "verifier":   "google/gemma-3-27b-it:free",
})
```

### The honest catches with free cloud tiers
- **Rate limits will bite.** A council fires ~6–12 calls per question; free tiers cap requests *and* tokens per minute/day (e.g. Groq ~30 RPM and ~1,000 requests/day on 70B; Gemini Flash ~15 RPM / ~1,500/day). Fine for a handful of councils, not for volume — run questions one at a time.
- **Most free tiers train on your prompts** (Google, Mistral, and others). Don't send anything sensitive. The no-training options are local Ollama and providers that state no-training (Groq, OpenRouter, Cerebras).
- **No SLA, and ids drift.** Quotas and model availability change without notice; the model ids above will go stale — verify on the provider.
- **Only Claude-inline and local Ollama need *no key at all*.** Free cloud APIs still require a (free, no-card) signup key.

Quick map: want it now with nothing to set up → **Claude inline**. Want the real multi-call pipeline, private and offline → **Ollama**. Want more horsepower or genuinely different models per advisor without buying hardware → a **free cloud key (OpenRouter)**.

**Switch providers in one line** with `scripts/council.config.json` — set `provider` (and optional per-role `models`), then run `python scripts/council.py "..." --config scripts/council.config.json`, or simply `./run.sh "..."` (macOS/Linux) or `.\run.ps1 "..."` (Windows), which also load keys from a `.env`. The config file ships with two ready examples: Anthropic mixed-tier and OpenRouter per-advisor diversity.

### Visual dashboard (run it locally)

For the same experience as the original web app, but pointed at your local/free models, run the bundled dashboard:

```bash
python scripts/dashboard_server.py     # opens http://localhost:8787
```

A small standard-library server (`dashboard_server.py`) serves the UI (`dashboard.html`) and **proxies every LLM call server-side**, so the browser only ever talks to `localhost` — no CORS to configure, your API key never enters the browser, and it works fully offline with Ollama. Pick the provider, depth, and (optionally) model/key right in the page; watch the advisors deliberate live; copy or export the decision. Keys can come from the page or from your environment variables.

---

## The quality lever: mixed-tier models

The single biggest quality/cost win is using a **cheap, fast model for the many
proposer calls and the strongest model for the Arbiter and Adversary**, where the
reasoning actually concentrates. Configure per role:

```python
call = anthropic_call(models={
    "triage":     "claude-haiku-4-5-20251001",   # cheap
    "proposer":   "claude-sonnet-5",            # fast, ×4–8 calls
    "aggregator": "claude-opus-4-8",              # strongest — synthesis + refine
    "verifier":   "claude-opus-4-8",              # strongest — the adversary
})
```

```ts
const call = anthropicCall({ models: {
  triage: "claude-haiku-4-5-20251001", proposer: "claude-sonnet-5",
  aggregator: "claude-opus-4-8", verifier: "claude-opus-4-8",
}});
```

Model ids above are defaults — swap them for whatever's current on your account.

---

## When NOT to wrap something in a council

A council is 1 + N×rounds + verify + refine model calls. That's the right spend on
a hard, ambiguous, or irreversible decision — and waste everywhere else. Skip it for:

- routine or low-stakes calls, simple lookups, formatting, or anything with one obvious answer;
- latency-critical hot paths (a `deep` run is many sequential round-trips);
- high-volume per-request use where cost matters — reserve it for the decisions that earn it.

Rule of thumb: use the council when the cost of being wrong clearly exceeds the cost of the extra calls. Default `depth` to `quick` for embedded/product use and `deep`/`max` for deliberate, human-in-the-loop decisions.

---

## Cost & latency (rough)

| depth | calls | grounding | feel |
|-------|-------|-----------|------|
| quick | ~5 (4 proposers + synthesis) | off | fastest |
| deep  | ~10 (triage + 8 proposer + synthesis + verify [+ refine]) | auto if factual | balanced |
| max   | deep + web search on proposers & verifier | on | slowest, most accurate on facts |

Proposer rounds run in parallel (threads in Python, `Promise.all` in TS), so wall-clock is roughly the slowest proposer per round plus the sequential triage/synthesis/verify/refine steps.

---

## Environment

- `ANTHROPIC_API_KEY` — built-in Anthropic caller (supports web grounding).
- `OPENAI_API_KEY` — built-in OpenAI caller (no grounding).
- Or inject your own `call` and set nothing.

## Record shape (returned by `council()`)

`{ question, depth, grounded, council:[ids], triage, advisors:[{id,name,lens,r1,rebuttal}], decision, evaluations:[{agent,score,critique}], consensus, arbiter_reasoning, verification:{verdict,issues,notes}, refined, refine_changes }`

`to_markdown(record)` / `toMarkdown(record)` renders the full deliberation as a portable report.
