#!/usr/bin/env python3
"""
Council — a provider-agnostic Mixture-of-Agents decision engine.

The pipeline: triage -> propose -> debate -> synthesize -> verify -> refine.
Multiple advisor agents answer independently through distinct lenses, debate,
an Arbiter synthesizes one decision, and an Adversary stress-tests it. You get
back one synthesized, verified answer plus a full audit trail.

Quick start (CLI, auto-detects ANTHROPIC_API_KEY or OPENAI_API_KEY):
    python council.py "Should our 5-person team adopt microservices?" --depth deep

As a library (any provider via dependency injection):
    from council import council, anthropic_call
    record = council("...question...", depth="deep", call=anthropic_call())
    print(record["decision"])

Mixed-tier models (the big quality lever — cheap proposers, strong arbiter):
    call = anthropic_call(models={
        "triage":     "claude-haiku-4-5-20251001",
        "proposer":   "claude-sonnet-4-6",
        "aggregator": "claude-opus-4-8",
        "verifier":   "claude-opus-4-8",
    })

Zero hard dependencies for the core. The built-in callers need the matching
SDK (`anthropic` or `openai`); inject your own `call` to use neither.
"""
from __future__ import annotations

import argparse
import concurrent.futures as _cf
import json
import os
import sys
from typing import Callable, Optional

# ----------------------------------------------------------------------------- #
# Roster — seven lenses. Triage seats four; the Skeptic always has a chair.
# ----------------------------------------------------------------------------- #
ROSTER = {
    "pragmatist": {"name": "The Pragmatist", "lens": "what works",
        "prompt": "what actually works in the real world — feasibility, cost, simplicity, time, and shipping something that survives contact with reality. You distrust elegance that doesn't pay rent."},
    "skeptic": {"name": "The Skeptic", "lens": "risk & failure",
        "prompt": "risk and failure — the hidden assumptions, the ways this goes wrong, the costs nobody priced in, the second-order damage. You are the red team; surface what everyone else is too optimistic to see."},
    "analyst": {"name": "The Analyst", "lens": "rigor & tradeoffs",
        "prompt": "rigor — first principles, explicit tradeoffs, and evidence. You decompose the problem, weigh options against each other, and quantify wherever quantifying is honest."},
    "visionary": {"name": "The Visionary", "lens": "ambition & horizon",
        "prompt": "ambition and the long horizon — the boldest version that's still defensible, the non-obvious angle, what this could become if it works. You refuse to think small."},
    "humanist": {"name": "The Humanist", "lens": "people & ethics",
        "prompt": "people and ethics — the human stakes, who is affected, the second-order effects on real people, fairness, and lived experience. You keep the decision honest about its impact on humans."},
    "engineer": {"name": "The Engineer", "lens": "build & correctness",
        "prompt": "technical correctness and implementation — how this is actually built, the edge cases, the failure surfaces, the systems realities, and what breaks under load. You think in mechanisms, not slogans."},
    "strategist": {"name": "The Strategist", "lens": "incentives & game",
        "prompt": "incentives and strategy — competition, game theory, leverage, positioning, and how other actors will respond. You think several moves ahead about who benefits and who pushes back."},
}
DEFAULT_COUNCIL = ["pragmatist", "skeptic", "analyst", "visionary"]

DEPTHS = {
    "quick": {"triage": False, "rebuttal": False, "verify": False},
    "deep":  {"triage": True,  "rebuttal": True,  "verify": True},
    "max":   {"triage": True,  "rebuttal": True,  "verify": True},  # + grounding
}

# ----------------------------------------------------------------------------- #
# Prompts (plain strings; braces are literal JSON shape, not format fields)
# ----------------------------------------------------------------------------- #
TRIAGE_SYSTEM = """You are the Convener of a council of advisors. Given a question, prepare the deliberation. Return ONLY a JSON object, no fences or extra text:
{"type":"<one of: technical, strategic, factual, creative, interpersonal, ethical, analytical, other>","grounding_useful":<true if a correct answer depends on current facts, data, prices, events, named real-world entities, or anything that should be checked against sources; else false>,"council":["<4 advisor ids>"],"reasoning":"<one short sentence>"}
Choose the council as the 4 most useful advisors for THIS question from exactly: pragmatist, skeptic, analyst, visionary, humanist, engineer, strategist. ALWAYS include "skeptic". Pick the other three for fit (e.g. engineer for technical builds, humanist for interpersonal/ethical, strategist for business/competition, visionary for open-ended)."""

ARBITER_SYSTEM = """You are the Arbiter. Several advisors have each answered the user's question through a distinct lens, then revised after debate. Produce the final decision.

First, think carefully (in the "reasoning" field) about: where the advisors agree — treat that as high-confidence; where they conflict — decide which side is right and why; what every one of them missed; and the implicit requirements or constraints in the question itself.

Then write the final answer. It must be strictly better than any single advisor's: decisive, complete, and shaped to fit the question — if it is a decision, lead with the call; if it is an open question, lead with the best synthesized answer. Where it matters, name the strongest counter-consideration, state your confidence honestly, and say what would change the answer. Do not hedge everything; commit, then caveat once. Use clean markdown.

Score each advisor 0-10 for how much their contribution actually advanced a good decision, with one sentence naming its strongest contribution and its main blind spot.

Return ONLY a JSON object, no fences or extra text:
{"reasoning":"<your private analysis>","evaluations":[{"agent":"<name>","score":<int>,"critique":"<one sentence>"}],"consensus":"<strong | mixed | divided>","synthesis":"<the final decision, in markdown>"}"""

VERIFY_SYSTEM = """You are the Adversary — an independent verifier with no loyalty to the Arbiter. You are given a question and the Arbiter's proposed decision. Attack it honestly.

Check: (1) does it actually and fully answer the question asked; (2) factual accuracy — if any claim is checkable and you can verify it, do; (3) logical consistency and hidden holes; (4) missed constraints, requirements, or materially better options; (5) overconfidence or unsupported claims. List ONLY material problems — ones that would change or meaningfully weaken the decision. Be specific and fair; if the decision is sound, say so.

Return ONLY a JSON object, no fences or extra text:
{"verdict":"<pass | revise>","issues":[{"severity":"<high | medium>","issue":"<specific problem>"}],"notes":"<short; any corrected facts or the single most important fix>"}
If sound, return verdict "pass" with an empty issues array."""

REFINE_SYSTEM = """You are the Arbiter. An independent verifier found material issues with your decision. Revise the decision to fix every issue while preserving its strengths and decisiveness. Do not get defensive — incorporate the corrections.
Return ONLY a JSON object, no fences or extra text:
{"synthesis":"<the revised decision, in markdown>","changes":"<one line on what you changed>"}"""


def _advisor_r1_system(a: dict) -> str:
    return (f"You are {a['name']}, one of four advisors on a council convened to reason through a hard question. "
            f"You think exclusively through one lens: {a['prompt']} "
            "Give your own best answer, reasoned through your lens and fully committed to — do not hedge, do not defer to "
            "other advisors, do not try to be balanced or cover every angle. Owning your perspective is the point; the "
            "council's other voices cover the rest. Lead with your verdict, then your sharpest reasons. A few tight "
            "paragraphs or crisp bullets. No preamble, no restating the question.")


def _rebuttal_system(a: dict) -> str:
    return (f"You are {a['name']}. You think through one lens: {a['prompt']} "
            "You gave an initial answer; now you have read the other advisors' answers. Revise YOUR answer: keep what "
            "holds up, concede anything they got right that you missed, sharpen the places you disagree and say plainly "
            "why they are wrong, and strengthen your single strongest point. Stay firmly in your lens — do not drift "
            "into bland consensus. Output only your revised answer, tightly.")


# ----------------------------------------------------------------------------- #
# Helpers
# ----------------------------------------------------------------------------- #
def _parse_json(raw: str) -> dict:
    t = raw.strip()
    if t.startswith("```"):
        t = t.split("```", 2)[1] if "```" in t[3:] else t[3:]
        if t.lower().startswith("json"):
            t = t[4:]
    a, b = t.find("{"), t.rfind("}")
    if a != -1 and b != -1:
        t = t[a:b + 1]
    return json.loads(t)


def _join(advisors: list, which: str) -> str:
    out = []
    for a in advisors:
        ans = (a.get("rebuttal") or a["r1"]) if which == "rebuttal" else a["r1"]
        out.append(f"--- {a['name']} ({a['lens']}) ---\n{ans}")
    return "\n\n".join(out)


def _parallel(fn: Callable, items: list) -> None:
    if not items:
        return
    with _cf.ThreadPoolExecutor(max_workers=min(8, len(items))) as ex:
        futs = [ex.submit(fn, it) for it in items]
        for f in _cf.as_completed(futs):
            try:
                f.result()
            except Exception as e:  # advisor-level failure is non-fatal
                print(f"[council] advisor error: {e}", file=sys.stderr)


# ----------------------------------------------------------------------------- #
# The engine
# ----------------------------------------------------------------------------- #
# A `call` is: call(role, system, user, want_json=False, grounded=False) -> str
#   role in {"triage", "proposer", "aggregator", "verifier"}
CallFn = Callable[..., str]


def council(question: str, *, call: CallFn, depth: str = "deep",
            grounded: Optional[bool] = None, council_ids: Optional[list] = None,
            on_event: Optional[Callable] = None) -> dict:
    """Run the council and return a record dict (see README for shape)."""
    if depth not in DEPTHS:
        raise ValueError(f"depth must be one of {list(DEPTHS)}")
    cfg = DEPTHS[depth]
    emit = on_event or (lambda *a, **k: None)
    rec: dict = {"question": question, "depth": depth, "advisors": [], "triage": None,
                 "decision": None, "evaluations": [], "consensus": None,
                 "arbiter_reasoning": None, "verification": None,
                 "refined": False, "refine_changes": None}

    # ---- Triage ----
    if cfg["triage"]:
        emit("triage", "start")
        try:
            tj = _parse_json(call("triage", TRIAGE_SYSTEM, question, want_json=True))
            ids = [i for i in (tj.get("council") or []) if i in ROSTER]
            if "skeptic" not in ids:
                ids = ["skeptic"] + ids
            seen, dedup = set(), []
            for i in ids:
                if i not in seen:
                    seen.add(i); dedup.append(i)
            ids = dedup[:4]
            for d in DEFAULT_COUNCIL:
                if len(ids) >= 4:
                    break
                if d not in ids:
                    ids.append(d)
            council_ids = ids
            if grounded is None and depth == "deep":
                grounded = bool(tj.get("grounding_useful"))
            rec["triage"] = tj
            emit("triage", "done", tj)
        except Exception as e:
            emit("triage", "skip", str(e))

    if council_ids is None:
        council_ids = list(DEFAULT_COUNCIL)
    if grounded is None:
        grounded = (depth == "max")
    rec["grounded"] = grounded
    rec["council"] = council_ids
    advisors = [{"id": i, **ROSTER[i], "r1": None, "rebuttal": None} for i in council_ids]
    rec["advisors"] = advisors
    emit("seated", "council", {"advisors": [{"id": a["id"], "name": a["name"], "lens": a["lens"]} for a in advisors]})

    # ---- Round 1 (parallel) ----
    emit("round1", "start")
    def _r1(a):
        a["r1"] = call("proposer", _advisor_r1_system(a), question, grounded=grounded)
        emit("advisor", "proposed", {"id": a["id"], "text": a["r1"]})
    _parallel(_r1, advisors)
    alive = [a for a in advisors if a["r1"]]
    if not alive:
        raise RuntimeError("The entire council failed to respond.")
    emit("round1", "done", {"alive": len(alive)})

    # ---- Rebuttal (parallel) ----
    if cfg["rebuttal"] and len(alive) > 1:
        emit("rebuttal", "start")
        def _reb(a):
            others = [x for x in alive if x is not a]
            ctx = (f"QUESTION:\n{question}\n\nThe other advisors said:\n\n{_join(others, 'r1')}\n\n"
                   "Now give your revised answer.")
            a["rebuttal"] = call("proposer", _rebuttal_system(a), ctx)
            emit("advisor", "revised", {"id": a["id"], "text": a["rebuttal"]})
        _parallel(_reb, alive)
        emit("rebuttal", "done")

    which = "rebuttal" if cfg["rebuttal"] else "r1"

    # ---- Synthesis ----
    emit("synthesis", "start")
    synth_in = (f"QUESTION:\n{question}\n\nADVISOR ANSWERS:\n\n{_join(alive, which)}\n\n"
                "Produce the final decision as the specified JSON.")
    raw = call("aggregator", ARBITER_SYSTEM, synth_in, want_json=True)
    try:
        synth = _parse_json(raw)
    except Exception:
        synth = {"synthesis": raw, "evaluations": [], "consensus": None, "reasoning": None}
    rec["decision"] = synth.get("synthesis", raw)
    rec["evaluations"] = synth.get("evaluations", [])
    rec["consensus"] = synth.get("consensus")
    rec["arbiter_reasoning"] = synth.get("reasoning")
    emit("synthesis", "done", {"consensus": rec["consensus"]})

    # ---- Verify + bounded refine ----
    if cfg["verify"]:
        emit("verify", "start")
        try:
            v = _parse_json(call("verifier", VERIFY_SYSTEM,
                                 f"QUESTION:\n{question}\n\nPROPOSED DECISION:\n{rec['decision']}\n\nVerify it.",
                                 want_json=True, grounded=grounded))
            rec["verification"] = v
            issues = [i for i in (v.get("issues") or []) if i.get("issue")]
            if v.get("verdict") == "revise" and issues:
                emit("verify", "issues", {"count": len(issues)})
                emit("refine", "start")
                issuetext = "\n".join(f"- [{i.get('severity')}] {i['issue']}" for i in issues)
                if v.get("notes"):
                    issuetext += f"\nVerifier note: {v['notes']}"
                rraw = call("aggregator", REFINE_SYSTEM,
                            f"QUESTION:\n{question}\n\nYOUR DECISION:\n{rec['decision']}\n\n"
                            f"VERIFIER FOUND:\n{issuetext}\n\nReturn the revised decision.",
                            want_json=True)
                try:
                    rj = _parse_json(rraw)
                    if rj.get("synthesis"):
                        rec["decision"] = rj["synthesis"]
                        rec["refined"] = True
                        rec["refine_changes"] = rj.get("changes", "Revised to address verifier issues.")
                except Exception:
                    pass
                emit("refine", "done")
            else:
                emit("verify", "pass")
        except Exception as e:
            emit("verify", "skip", str(e))

    emit("final", "done")
    return rec


def to_markdown(rec: dict) -> str:
    """Render a council record as a portable Markdown deliberation report."""
    L = ["# The Council — Deliberation Record", "",
         f"**Question:** {rec['question']}", "",
         f"**Depth:** {rec['depth']} · **Grounded:** {'yes' if rec.get('grounded') else 'no'} · "
         f"**Consensus:** {rec.get('consensus') or '—'} · "
         f"**Verification:** {(rec.get('verification') or {}).get('verdict', '—')}"
         f"{' (refined)' if rec.get('refined') else ''}", "",
         "---", "", "## The Decision", "", rec.get("decision") or "", ""]
    v = rec.get("verification")
    if v:
        L += ["", "## Verification", "", f"Verdict: **{v.get('verdict')}**"]
        for i in (v.get("issues") or []):
            L.append(f"- [{i.get('severity')}] {i.get('issue')}")
        if v.get("notes"):
            L.append(f"\nNotes: {v['notes']}")
        if rec.get("refine_changes"):
            L.append(f"\nRefinement: {rec['refine_changes']}")
    if rec.get("evaluations"):
        L += ["", "## Council Scores", ""]
        for e in rec["evaluations"]:
            L.append(f"- **{e.get('agent')}** — {e.get('score')}/10 — {e.get('critique', '')}")
    L += ["", "## Full Deliberation", ""]
    t = rec.get("triage")
    if t:
        L += ["", "### Triage",
              f"- Type: {t.get('type')}", f"- Grounding: {'on' if rec.get('grounded') else 'off'}",
              f"- Council: {', '.join(rec.get('council', []))}", f"- {t.get('reasoning', '')}"]
    for a in rec.get("advisors", []):
        if not a.get("r1"):
            continue
        L += ["", f"### {a['name']} — {a['lens']}", "", "**Round 1:**", "", a["r1"]]
        if a.get("rebuttal") and a["rebuttal"] != a["r1"]:
            L += ["", "**Rebuttal:**", "", a["rebuttal"]]
    if rec.get("arbiter_reasoning"):
        L += ["", "### Arbiter's reasoning", "", rec["arbiter_reasoning"]]
    return "\n".join(L)


# ----------------------------------------------------------------------------- #
# Built-in provider callers (optional — inject your own to use neither)
# ----------------------------------------------------------------------------- #
def anthropic_call(models: Optional[dict] = None, web_search: bool = True,
                   max_tokens: int = 2048) -> CallFn:
    """Anthropic caller. Supports live web grounding via the web_search tool.
    Requires `pip install anthropic` and ANTHROPIC_API_KEY. Model ids are
    defaults you can override per role."""
    import anthropic
    client = anthropic.Anthropic()
    m = {"triage": "claude-haiku-4-5-20251001", "proposer": "claude-sonnet-4-6",
         "aggregator": "claude-opus-4-8", "verifier": "claude-opus-4-8"}
    m.update(models or {})

    def call(role, system, user, want_json=False, grounded=False):
        kwargs = dict(model=m.get(role, m["proposer"]), max_tokens=max_tokens,
                      system=system, messages=[{"role": "user", "content": user}])
        if grounded and web_search:
            kwargs["tools"] = [{"type": "web_search_20250305", "name": "web_search", "max_uses": 3}]
        resp = client.messages.create(**kwargs)
        return "".join(getattr(b, "text", "") for b in resp.content
                       if getattr(b, "type", None) == "text").strip()
    return call


_ROLES = ("triage", "proposer", "aggregator", "verifier")


def openai_call(models: Optional[dict] = None, base_url: Optional[str] = None,
                api_key: Optional[str] = None, default_model: str = "gpt-4o-mini") -> CallFn:
    """OpenAI-compatible caller — works with OpenAI and ANY OpenAI-compatible
    endpoint (Ollama, Groq, OpenRouter, Gemini's compat layer, etc.). No web
    grounding. Pass base_url/api_key to target another provider, or use a free
    preset below. Requires `pip install openai`."""
    from openai import OpenAI
    kw = {}
    if base_url:
        kw["base_url"] = base_url
    if api_key:
        kw["api_key"] = api_key
    client = OpenAI(**kw)
    m = {r: default_model for r in _ROLES}
    m.update(models or {})
    warned = {"g": False}

    def call(role, system, user, want_json=False, grounded=False):
        if grounded and not warned["g"]:
            print("[council] web grounding is unsupported by this caller; continuing ungrounded.",
                  file=sys.stderr)
            warned["g"] = True
        model = m.get(role, m["proposer"])
        msgs = [{"role": "system", "content": system}, {"role": "user", "content": user}]

        def _do(use_json):
            kwargs = dict(model=model, messages=msgs)
            if use_json:
                kwargs["response_format"] = {"type": "json_object"}
            resp = client.chat.completions.create(**kwargs)
            return (resp.choices[0].message.content or "").strip()

        try:
            return _do(want_json)
        except Exception:
            if want_json:           # provider may not support response_format — retry plain
                return _do(False)
            raise
    return call


# --- Free / no-cost presets (all OpenAI-compatible) -------------------------
def ollama_call(model: str = "llama3.1", base_url: str = "http://localhost:11434/v1") -> CallFn:
    """LOCAL Ollama — free forever, no key, fully private. Install Ollama and
    `ollama pull llama3.1` first. Output quality depends on the model your
    hardware can run. (Ollama Cloud is a different, non-compatible API.)"""
    return openai_call(models={r: model for r in _ROLES}, base_url=base_url, api_key="ollama")


def groq_call(models: Optional[dict] = None, api_key: Optional[str] = None) -> CallFn:
    """Groq free tier — fast, no credit card. Free key: https://console.groq.com .
    Reads GROQ_API_KEY. Model ids change — verify at console.groq.com/docs/models ."""
    return openai_call(models=models or {r: "llama-3.3-70b-versatile" for r in _ROLES},
                       base_url="https://api.groq.com/openai/v1",
                       api_key=api_key or os.environ.get("GROQ_API_KEY"))


def openrouter_call(models: Optional[dict] = None, api_key: Optional[str] = None) -> CallFn:
    """OpenRouter free models — one key, many free models, no card. Free key:
    https://openrouter.ai/keys . Assign different free models per role for real
    diversity. Free slugs end in ':free' and rotate — verify at openrouter.ai/models ."""
    free = "meta-llama/llama-3.3-70b-instruct:free"
    return openai_call(models=models or {"triage": free, "proposer": free,
                                         "aggregator": "deepseek/deepseek-r1:free", "verifier": free},
                       base_url="https://openrouter.ai/api/v1",
                       api_key=api_key or os.environ.get("OPENROUTER_API_KEY"))


def gemini_call(models: Optional[dict] = None, api_key: Optional[str] = None) -> CallFn:
    """Google Gemini free tier via its OpenAI-compatible endpoint — no card. Free
    key: https://aistudio.google.com/apikey . Reads GEMINI_API_KEY/GOOGLE_API_KEY.
    Note: free-tier prompts may be used by Google to improve products."""
    return openai_call(models=models or {r: "gemini-2.5-flash" for r in _ROLES},
                       base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
                       api_key=api_key or os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"))


def _auto_call() -> CallFn:
    if os.environ.get("ANTHROPIC_API_KEY"):
        return anthropic_call()
    if os.environ.get("OPENAI_API_KEY"):
        return openai_call()
    if os.environ.get("GROQ_API_KEY"):
        return groq_call()
    if os.environ.get("OPENROUTER_API_KEY"):
        return openrouter_call()
    if os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"):
        return gemini_call()
    sys.exit("[council] No provider key found. Set ANTHROPIC_API_KEY / OPENAI_API_KEY / "
             "GROQ_API_KEY / OPENROUTER_API_KEY / GEMINI_API_KEY (free keys work), or run a "
             "local model with `--provider ollama` (no key needed).")


# ----------------------------------------------------------------------------- #
# CLI
# ----------------------------------------------------------------------------- #
def main(argv=None):
    p = argparse.ArgumentParser(description="Mixture-of-Agents council — one synthesized, verified decision.")
    p.add_argument("question", nargs="?", help="the question (or pipe it via stdin)")
    p.add_argument("--config", metavar="PATH", help="JSON config (provider, depth, model, models, grounded)")
    p.add_argument("--depth", choices=list(DEPTHS), default=None)
    p.add_argument("--grounded", dest="grounded", action="store_true", default=None,
                   help="force live web grounding (Anthropic only)")
    p.add_argument("--no-grounded", dest="grounded", action="store_false")
    p.add_argument("--provider", choices=["auto", "anthropic", "openai", "groq", "openrouter", "gemini", "ollama"],
                   default=None)
    p.add_argument("--model", help="override the model for all roles (handy for ollama/groq/etc.)")
    p.add_argument("--json", action="store_true", help="print the full record as JSON")
    p.add_argument("--save", metavar="PATH", help="write the Markdown deliberation record to PATH")
    p.add_argument("--quiet", action="store_true", help="suppress stage progress")
    args = p.parse_args(argv)

    question = args.question or (sys.stdin.read().strip() if not sys.stdin.isatty() else None)
    if not question:
        p.error("provide a question argument or pipe one via stdin")

    cfg = {}
    if args.config:
        with open(args.config) as f:
            cfg = json.load(f)
    provider = args.provider or cfg.get("provider") or "auto"
    depth = args.depth or cfg.get("depth") or "deep"
    model = args.model or cfg.get("model")
    grounded = args.grounded if args.grounded is not None else cfg.get("grounded")
    role_models = cfg.get("models") or ({r: model for r in _ROLES} if model else None)

    if provider == "auto":
        call = _auto_call()
    elif provider == "ollama":
        call = ollama_call(model=model or (cfg.get("models") or {}).get("proposer") or "llama3.1")
    else:
        builders = {"anthropic": anthropic_call, "openai": openai_call, "groq": groq_call,
                    "openrouter": openrouter_call, "gemini": gemini_call}
        if provider not in builders:
            p.error(f"unknown provider: {provider}")
        call = builders[provider](models=role_models)

    def on_event(stage, status, data=None):
        if not args.quiet:
            tail = f" {data}" if data else ""
            print(f"  · {stage}: {status}{tail}", file=sys.stderr)

    rec = council(question, call=call, depth=depth, grounded=grounded, on_event=on_event)

    if args.save:
        with open(args.save, "w") as f:
            f.write(to_markdown(rec))
        print(f"[council] record written to {args.save}", file=sys.stderr)

    if args.json:
        print(json.dumps(rec, indent=2))
    else:
        print(rec["decision"])
        v = rec.get("verification")
        if v and not args.quiet:
            badge = "verified — no material issues" if v.get("verdict") == "pass" \
                else f"refined — {len(v.get('issues', []))} issue(s) fixed" if rec.get("refined") \
                else f"{len(v.get('issues', []))} issue(s) flagged"
            print(f"\n[{badge}]", file=sys.stderr)


if __name__ == "__main__":
    main()
