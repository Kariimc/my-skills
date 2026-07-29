#!/usr/bin/env python3
"""
Council — a provider-agnostic Mixture-of-Agents decision engine.

The pipeline: triage -> propose -> debate -> synthesize -> verify -> refine.
Multiple advisor agents answer independently through distinct lenses, debate,
an Arbiter synthesizes one decision, and an Adversary stress-tests it. You get
back one synthesized, verified answer plus a full audit trail.

Quick start (CLI, auto-detects every key it can find):
    python council.py "Should our 5-person team adopt microservices?" --depth deep

Fusion — a crew of named models, each on the job it is best at, all at HIGH
reasoning effort. Sonnet 5 researches and plans, Opus 5 builds, the partner (the
smartest model we can call reliably all the time) builds too and synthesizes, and
Fable 5 verifies — its rulings become the house standards every model reads
before it answers next time. Keys live in ~/.claude/fusion.env:
    python council.py --brains                      # the crew, and who covers whom
    python council.py "...question..." --provider fusion --depth deep

As a library (any provider via dependency injection):
    from council import council, anthropic_call
    record = council("...question...", depth="deep", call=anthropic_call())
    print(record["decision"])

Pin models per role yourself if you want a different crew:
    call = anthropic_call(models={
        "triage":     "claude-sonnet-5",    # research + plan
        "proposer":   "claude-opus-5",      # build
        "aggregator": "claude-opus-5",      # synthesize
        "verifier":   "claude-fable-5",     # verify, and set the standard
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
# Key file — one place to keep the brains' keys, outside any repo.
# Plain KEY=VALUE lines in ~/.claude/fusion.env. Never overrides a real env var.
# ----------------------------------------------------------------------------- #
KEYFILE = os.path.join(os.path.expanduser("~"), ".claude", "fusion.env")

# Where the Verifier's standards accumulate. Every worker reads this before it
# writes anything, so the bar the Verifier set last time is the bar they start
# from this time. See `lessons_prefix` for what this is and — importantly — is not.
LESSONS = os.path.join(os.path.expanduser("~"), ".claude", "fusion-lessons.md")
LESSONS_MAX = 6000          # characters carried into each prompt


def lessons_prefix(path: Optional[str] = None) -> str:
    """The house standards block prepended to every worker's system prompt.

    This is CARRIED CONTEXT, not training: the models' weights never change, and
    nothing here makes Sonnet permanently smarter. What it does do is real — the
    Verifier's past rulings become explicit standards every other model must meet
    before it answers, so the crew converges on the Verifier's bar instead of
    rediscovering it every run."""
    p = path or LESSONS
    try:
        text = open(p, encoding="utf-8").read().strip()
    except OSError:
        return ""
    if not text:
        return ""
    if len(text) > LESSONS_MAX:                 # keep the newest standards
        text = text[-LESSONS_MAX:]
        text = text[text.find("\n") + 1:]
    return ("CREW NOTEBOOK — what this crew has already learned, on earlier runs.\n"
            "RULINGS are binding: the Verifier has already caught these, do not repeat them.\n"
            "CREWMATE NOTES are your colleagues' track record: copy the moves that scored, and "
            "watch for the blind spots named against a model — including your own.\n\n"
            + text + "\n\n--- end crew notebook ---\n\n")


def record_lessons(verification: dict, question: str = "", path: Optional[str] = None,
                   evaluations: Optional[list] = None,
                   seat_models: Optional[dict] = None) -> int:
    """Write down what this run taught the crew — in BOTH directions.

    Downward: the Verifier's rulings become binding standards for everyone.
    Sideways: what each model actually brought, and where it was blind, so the
    next run's models learn from each other and not only from the Verifier.
    Returns how many notes were recorded."""
    issues = [i for i in (verification or {}).get("issues") or [] if i.get("issue")]
    notes = (verification or {}).get("notes")
    peers = [e for e in (evaluations or []) if e.get("agent")]
    if not issues and not notes and not peers:
        return 0
    p = path or LESSONS
    n = 0
    try:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "a", encoding="utf-8") as f:
            f.write(f"\n## From a run on: {question[:120].strip() or '(unrecorded question)'}\n")
            if issues or notes:
                f.write("### RULINGS (binding — the Verifier caught these)\n")
                for i in issues:
                    f.write(f"- [{i.get('severity', 'note')}] {i['issue'].strip()}\n")
                    n += 1
                if notes:
                    f.write(f"- [standard] {notes.strip()}\n")
                    n += 1
            if peers:
                f.write("### CREWMATE NOTES (learn from each other)\n")
                for e in peers:
                    who = (seat_models or {}).get(e["agent"]) or e["agent"]
                    label = f"{who} as {ROSTER.get(e['agent'], {}).get('name', e['agent'])}"
                    score = e.get("score")
                    f.write(f"- {label}"
                            + (f" (scored {score}/10)" if score is not None else "")
                            + f": {str(e.get('critique', '')).strip()}\n")
                    n += 1
    except OSError as e:
        print(f"[fusion] could not write the crew notebook at {p} ({e}) — this run taught "
              "the crew NOTHING that survives; the next run starts from the old bar.",
              file=sys.stderr)
        return 0
    print(f"[fusion] crew notebook updated at {p}: {len(issues) + (1 if notes else 0)} binding "
          f"ruling(s) from the Verifier, {len(peers)} note(s) on what each model brought. "
          "Every model reads this before it answers next time.", file=sys.stderr)
    return n


def load_keyfile(path: str = KEYFILE) -> None:
    try:
        with open(path) as f:
            lines = f.readlines()
    except OSError:
        return
    loaded, shadowed = [], []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        k, v = k.strip(), v.strip().strip('"').strip("'")
        if not k or not v:
            continue
        if os.environ.get(k):
            shadowed.append(k)
        else:
            os.environ[k] = v
            loaded.append(k)
    if loaded:
        print(f"[fusion] keys loaded from {path}: {', '.join(loaded)}", file=sys.stderr)
    if shadowed:
        print(f"[fusion] {path} IGNORED for {', '.join(shadowed)} — the environment already "
              "sets those and wins.", file=sys.stderr)


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


def _invoke(call: CallFn, role: str, system: str, user: str, *, seat: Optional[str] = None, **kw) -> str:
    """Call a caller, handing it the seat id when it knows what to do with one.
    Callers written before seats existed keep working untouched."""
    if seat is not None:
        try:
            return call(role, system, user, seat=seat, **kw)
        except TypeError as e:
            if "seat" not in str(e):
                raise
            if not _invoke.warned:
                _invoke.warned = True
                print("[council] this caller does not understand seats — every advisor will "
                      "run on the SAME model. That is not fusion.", file=sys.stderr)
    return call(role, system, user, **kw)


_invoke.warned = False


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
            print(f"[council] triage failed ({e}) — falling back to the default council "
                  f"({', '.join(DEFAULT_COUNCIL)}) instead of one picked for this question.",
                  file=sys.stderr)
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
    # A multi-brand caller re-deals its seats now that it knows who is actually
    # sitting — otherwise a whole brand can end up with no advisor to run.
    if hasattr(call, "seat_council"):
        try:
            call.seat_council(council_ids)
        except Exception as e:
            print(f"[council] seat re-deal skipped: {e}", file=sys.stderr)

    # ---- Round 1 (parallel) ----
    emit("round1", "start")
    def _r1(a):
        a["r1"] = _invoke(call, "proposer", _advisor_r1_system(a), question,
                          seat=a["id"], grounded=grounded)
        emit("advisor", "proposed", {"id": a["id"], "text": a["r1"]})
    _parallel(_r1, advisors)
    alive = [a for a in advisors if a["r1"]]
    if not alive:
        raise RuntimeError("The entire council failed to respond.")
    if len(alive) < len(advisors):
        dead = ", ".join(a["name"] for a in advisors if not a.get("r1"))
        print(f"[council] {len(advisors) - len(alive)} advisor(s) never answered ({dead}) — "
              "the decision below was made without them.", file=sys.stderr)
    emit("round1", "done", {"alive": len(alive)})

    # ---- Rebuttal (parallel) ----
    if cfg["rebuttal"] and len(alive) > 1:
        emit("rebuttal", "start")
        def _reb(a):
            others = [x for x in alive if x is not a]
            ctx = (f"QUESTION:\n{question}\n\nThe other advisors said:\n\n{_join(others, 'r1')}\n\n"
                   "Now give your revised answer.")
            a["rebuttal"] = _invoke(call, "proposer", _rebuttal_system(a), ctx, seat=a["id"])
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
    except Exception as e:
        print(f"[council] the Arbiter did not return usable JSON ({e}); using its raw text as "
              "the decision — scores and consensus are unavailable for this run.", file=sys.stderr)
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
            # The Verifier's ruling becomes the standard the whole crew starts from
            # next run. This is carried context, not training — see lessons_prefix.
            if hasattr(call, "learn"):
                try:
                    rec["lessons_recorded"] = call.learn(v, question, rec.get("evaluations"))
                except Exception as e:
                    print(f"[fusion] the Verifier's standards were NOT recorded ({e}) — "
                          "the next run starts from the old bar.", file=sys.stderr)
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
                    else:
                        print("[council] the refinement returned no revised decision — the "
                              f"verifier's {len(issues)} issue(s) stand UNFIXED.", file=sys.stderr)
                except Exception as e:
                    print(f"[council] refinement unusable ({e}) — the verifier's {len(issues)} "
                          "issue(s) stand UNFIXED in the decision above.", file=sys.stderr)
                emit("refine", "done")
            else:
                emit("verify", "pass")
        except Exception as e:
            print(f"[council] VERIFICATION DID NOT RUN ({e}) — the decision above is "
                  "UNVERIFIED. Treat it as one model's opinion, not a checked answer.",
                  file=sys.stderr)
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
EFFORT_BUDGET = {"low": 1024, "medium": 4000, "high": 12000}


def anthropic_call(models: Optional[dict] = None, web_search: bool = True,
                   max_tokens: int = 16000, effort: Optional[str] = None) -> CallFn:
    """Anthropic caller. Supports live web grounding via the web_search tool.
    Requires `pip install anthropic` and ANTHROPIC_API_KEY. Runs at HIGH reasoning
    effort by default — extended thinking with a large budget."""
    import anthropic
    client = anthropic.Anthropic()
    eff = effort or EFFORT
    m = {"triage": "claude-sonnet-5", "proposer": "claude-opus-5",
         "aggregator": "claude-opus-5", "verifier": "claude-fable-5"}
    m.update(models or {})
    warned = {"t": False}

    def call(role, system, user, want_json=False, grounded=False):
        model = m.get(role, m["proposer"])
        kwargs = dict(model=model, max_tokens=max_tokens,
                      system=system, messages=[{"role": "user", "content": user}])
        if grounded and web_search:
            kwargs["tools"] = [{"type": "web_search_20250305", "name": "web_search", "max_uses": 3}]
        budget = EFFORT_BUDGET.get(eff)

        def _do(think):
            kw = dict(kwargs)
            if think and budget:
                kw["thinking"] = {"type": "enabled", "budget_tokens": budget}
            resp = client.messages.create(**kw)
            return "".join(getattr(b, "text", "") for b in resp.content
                           if getattr(b, "type", None) == "text").strip()

        try:
            return _do(True)
        except Exception as e:
            if budget and not _is_gone(e):
                if not warned["t"]:
                    warned["t"] = True
                    print(f"[council] {model} would not run at {eff} effort "
                          f"({type(e).__name__}: {e}); continuing WITHOUT extended thinking. "
                          "Answers from it are not at the effort you asked for.",
                          file=sys.stderr)
                return _do(False)
            raise
    return call


_ROLES = ("triage", "proposer", "aggregator", "verifier")


def openai_call(models: Optional[dict] = None, base_url: Optional[str] = None,
                api_key: Optional[str] = None, default_model: str = "gpt-5.6-sol",
                effort: Optional[str] = None) -> CallFn:
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
    warned = {"g": False, "e": False}

    def call(role, system, user, want_json=False, grounded=False):
        if grounded and not warned["g"]:
            print("[council] web grounding is unsupported by this caller; continuing ungrounded.",
                  file=sys.stderr)
            warned["g"] = True
        model = m.get(role, m["proposer"])
        msgs = [{"role": "system", "content": system}, {"role": "user", "content": user}]

        def _do(use_json, use_effort):
            kwargs = dict(model=model, messages=msgs)
            if use_json:
                kwargs["response_format"] = {"type": "json_object"}
            if use_effort:
                kwargs["reasoning_effort"] = effort or EFFORT
            resp = client.chat.completions.create(**kwargs)
            return (resp.choices[0].message.content or "").strip()

        try:
            return _do(want_json, True)
        except Exception as e:
            if _is_gone(e):
                raise
            if not warned["e"]:     # endpoint may not accept reasoning_effort
                warned["e"] = True
                print(f"[council] {model} would not run at {effort or EFFORT} effort "
                      f"({type(e).__name__}: {e}); continuing at the endpoint's default. "
                      "Answers from it are not at the effort you asked for.", file=sys.stderr)
            try:
                return _do(want_json, False)
            except Exception as e2:
                if want_json:       # provider may not support response_format — retry plain
                    print(f"[council] {model} rejected JSON mode ({type(e2).__name__}: {e2}); "
                          "retrying as plain text.", file=sys.stderr)
                    return _do(False, False)
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


# --- Fusion: a crew of named models, each on the job it is best at ------------ #
#
# The crew (Kariim's assignment, 2026-07-29):
#   Researcher/Planner  Sonnet 5     — does the deep research and writes the plan
#   Builder             Opus 5       — builds
#   Builder+Synthesist  the partner  — the smartest model we can call reliably all
#                                      the time; builds too, then synthesizes
#   Verifier            Fable 5      — checks the result, and sets the standard
#                                      everyone else is held to
# Every model runs at HIGH reasoning effort. No budget tiers anywhere.
BRAINS = {
    "claude": {"env": ("ANTHROPIC_API_KEY",), "label": "Claude (Anthropic)",
               "ladder": ["claude-opus-5", "claude-fable-5", "claude-sonnet-5"]},
    "gpt":    {"env": ("OPENAI_API_KEY",), "label": "GPT / Codex (OpenAI)",
               "ladder": ["gpt-5.6-sol", "gpt-5.6-terra"]},
    "gemini": {"env": ("GEMINI_API_KEY", "GOOGLE_API_KEY"), "label": "Gemini (Google AI Studio)",
               "ladder": ["gemini-3.6-flash", "gemini-3.5-flash"]},
    # Reserve brain: open-weight models through the Hugging Face router. Its ladder
    # is discovered live from the router's own catalogue, so it stays empty here.
    "hf":     {"env": ("HF_TOKEN", "HUGGINGFACE_API_KEY"), "label": "Hugging Face (open models)",
               "ladder": []},
}
BRAIN_ORDER = ["claude", "gpt", "gemini", "hf"]

MODEL_BRAIN = {m: b for b, spec in BRAINS.items() for m in spec["ladder"]}

# The named crew. First entry is the job's owner; the rest are who covers it, in
# order, if the owner is unavailable. Never a budget tier — a cover is the next
# smartest model, not a cheaper one.
CREW = {
    "researcher":  ["claude-sonnet-5", "claude-opus-5", "gpt-5.6-sol", "gemini-3.6-flash"],
    "builder":     ["claude-opus-5", "gpt-5.6-sol", "gemini-3.6-flash", "claude-fable-5"],
    "partner":     ["gpt-5.6-sol", "gemini-3.6-flash", "claude-opus-5", "claude-sonnet-5"],
    "verifier":    ["claude-fable-5", "claude-opus-5", "gpt-5.6-sol", "gemini-3.6-flash"],
}
# Which crew job each pipeline role belongs to.
ROLE_JOB = {"triage": "researcher", "aggregator": "partner", "verifier": "verifier"}
# Builders alternate: the owner first, the partner second, then back again.
BUILDERS = ["builder", "partner"]

EFFORT = "high"          # every model, every seat. Kariim's standing instruction.


def detect_brains(order: Optional[list] = None) -> list:
    """Which brains this machine can actually reach, strongest first."""
    load_keyfile()
    return [b for b in (order or BRAIN_ORDER)
            if b in BRAINS and any(os.environ.get(e) for e in BRAINS[b]["env"])]


def job_for(role: str, seat: Optional[str] = None) -> str:
    if role == "proposer":
        i = sorted(ROSTER).index(seat) if seat else 0
        return BUILDERS[i % len(BUILDERS)]
    return ROLE_JOB.get(role, "builder")


def crew_chain(role: str, seat: Optional[str] = None, live: Optional[list] = None,
               crew: Optional[dict] = None) -> list:
    """(brain, model) candidates for a job, owner first then its cover, filtered to
    the brains this machine can actually reach."""
    live = live if live is not None else detect_brains()
    order = (crew or CREW)[job_for(role, seat)]
    seen, out = set(), []
    for m in order:
        b = MODEL_BRAIN.get(m)
        if b in live and m not in seen:
            seen.add(m)
            out.append((b, m))
    # Last resorts: anything else reachable, smartest first, then the open reserve.
    for b in live:
        for m in (BRAINS[b]["ladder"] or [None]):
            if m not in seen:
                seen.add(m)
                out.append((b, m))
    return out


def _brain_caller(brain: str, model: Optional[str] = None) -> CallFn:
    """A caller pinned to ONE model, so the crew assignment decides the model."""
    models = {r: model for r in _ROLES} if model else None
    if brain == "claude":
        return anthropic_call(models=models)
    if brain == "gpt":
        return openai_call(models=models)
    if brain == "gemini":
        return gemini_call(models=models)
    if brain == "hf":
        return huggingface_call(models=models)
    raise ValueError(f"unknown brain: {brain}")


def fusion_plan(live: list, seats: Optional[list] = None, crew: Optional[dict] = None) -> dict:
    """Who holds each job, and on which model."""
    seats = sorted(seats or list(ROSTER))

    def owner(role, seat=None):
        ch = crew_chain(role, seat, live, crew)
        return ch[0] if ch else (live[0], None)

    return {"brains": list(live),
            "triage": owner("triage"), "aggregator": owner("aggregator"),
            "verifier": owner("verifier"),
            "seats": {s: owner("proposer", s) for s in seats},
            "jobs": {s: job_for("proposer", s) for s in seats}}


def fusion_call(brains: Optional[list] = None, crew: Optional[dict] = None,
                order: Optional[list] = None, on_plan: Optional[Callable] = None,
                lessons_path: Optional[str] = None) -> CallFn:
    """The crew, on one question. Auto-detects whichever keys are present (see
    fusion.env), runs on however many it finds, and says so rather than pretending."""
    live = brains or detect_brains(order)
    if not live:
        sys.exit("[fusion] No brains reachable. Put keys in ~/.claude/fusion.env "
                 "(ANTHROPIC_API_KEY / OPENAI_API_KEY / GEMINI_API_KEY) — Claude alone works, "
                 "a second company is what makes the check independent.")
    callers: dict = {}
    plan = fusion_plan(live, crew=crew)
    plan["reserve"] = [b for b in (order or BRAIN_ORDER)
                       if b not in live and any(os.environ.get(e) for e in BRAINS[b]["env"])]
    plan["lessons_path"] = lessons_path if lessons_path is not None else LESSONS
    if plan["aggregator"][1] == plan["seats"].get(sorted(ROSTER)[0], (None, None))[1]:
        print(f"[fusion] NO PARTNER MODEL REACHABLE — the second builder and the "
              f"Synthesist have fallen back to {plan['aggregator'][1]}, the same model as the "
              "first builder. Add an OpenAI or Google AI Studio key and the crew is complete.",
              file=sys.stderr)
    if plan["verifier"][0] == plan["aggregator"][0]:
        print(f"[fusion] The Verifier and the Synthesist are both on "
              f"{BRAINS[plan['verifier'][0]]['label']} — different models, same company. "
              "Add another company's key to make the check fully independent.", file=sys.stderr)
    for m in missing_brains(plan):
        print(f"[fusion] {m}", file=sys.stderr)
    if on_plan:
        on_plan(plan)

    def _caller(brain, model):
        if (brain, model) not in callers:
            callers[(brain, model)] = _brain_caller(brain, model)
        return callers[(brain, model)]

    def call(role, system, user, want_json=False, grounded=False, seat=None):
        chain = crew_chain(role, seat, live, crew) + \
                [(b, None) for b in plan.get("reserve", [])]
        where = f"{job_for(role, seat)}/{role}" + (f"/{seat}" if seat else "")
        system = lessons_prefix(plan.get("lessons_path")) + system
        for i, (brain, model) in enumerate(chain):
            try:
                return _caller(brain, model)(role, system, user,
                                             want_json=want_json, grounded=grounded)
            except Exception as e:
                if i == len(chain) - 1 or not (_is_gone(e) or _is_transient(e)):
                    raise
                nb, nm = chain[i + 1]
                why = "is not available" if _is_gone(e) else "is rate-limited"
                print(f"[fusion] {model or BRAINS[brain]['label']} {why} for {where} "
                      f"({type(e).__name__}); covering with {nm or BRAINS[nb]['label']}.",
                      file=sys.stderr)
        raise RuntimeError(f"[fusion] every model was exhausted for {where}")

    def seat_council(ids):
        """Re-assign builder seats once the real council is known."""
        p = fusion_plan(live, ids, crew)
        plan["seats"], plan["jobs"] = p["seats"], p["jobs"]

    call.plan = plan
    call.seat_council = seat_council
    call.learn = lambda v, q="", evals=None: record_lessons(
        v, q, plan.get("lessons_path"), evals,
        {s: pair[1] for s, pair in plan["seats"].items()})
    return call


def missing_brains(plan: dict) -> list:
    """Every brain NOT taking part, and the reason. A model that cannot be used is
    reported by name — never just absent from the roster."""
    in_play = set(plan["brains"]) | set(plan.get("reserve") or [])
    return [f"{BRAINS[b]['label']} — NOT USED: no key found "
            f"(looked for {' or '.join(BRAINS[b]['env'])})"
            for b in BRAIN_ORDER if b not in in_play]


def describe_fusion(plan: dict) -> str:
    def row(label, job, pair, note=""):
        brain, model = pair
        return (f"  {label:<24} {job:<11} {model or 'chosen live from the router catalogue':<20}"
                f" {BRAINS[brain]['label']}" + (f"  {note}" if note else ""))

    lines = [f"Brains live: {', '.join(BRAINS[b]['label'] for b in plan['brains'])}"
             f"   ·  effort: {EFFORT} on every model",
             f"  {'JOB':<24} {'CREW':<11} {'MODEL':<20} COMPANY",
             row("Research + plan", "researcher", plan["triage"]),
             row("Synthesize", "partner", plan["aggregator"]),
             row("Verify", "verifier", plan["verifier"],
                 note="(same company as the Synthesist)"
                 if plan["verifier"][0] == plan["aggregator"][0] else "(independent company)")]
    for s, pair in sorted(plan["seats"].items()):
        lines.append(row(f"Build — {ROSTER[s]['name']}", plan["jobs"][s], pair))
    if plan.get("reserve"):
        lines.append(f"  {'Cover':<24} {'reserve':<11} "
                     f"{', '.join(BRAINS[b]['label'] for b in plan['reserve'])}"
                     "  (only if a model is unavailable)")
    lines.append("  (builder seats are re-assigned once the plan picks the council;")
    lines.append("   an unavailable model is covered by the next smartest, never a cheaper one)")
    return "\n".join(lines)


def hf_models(api_key: Optional[str] = None, timeout: int = 10) -> list:
    """Model ids the Hugging Face router will actually serve right now.
    Asked live, never hard-coded, so a renamed or retired model can't strand us."""
    import urllib.request
    key = api_key or os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_API_KEY")
    req = urllib.request.Request("https://router.huggingface.co/v1/models",
                                 headers={"Authorization": f"Bearer {key}"} if key else {})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        data = json.loads(r.read().decode())
    return [m.get("id", "") for m in (data.get("data") or []) if m.get("id")]


# Open-weight ladder, smartest first. Substrings, not exact ids — matched against
# whatever the router is serving, so this survives version bumps.
HF_LADDER = ["deepseek-v4", "kimi-k2.7", "kimi-k2", "glm-5", "qwen3-coder-480b",
             "minimax-m3", "deepseek-r1", "qwen3", "llama-3.3-70b"]
HF_FALLBACK = "meta-llama/Llama-3.3-70B-Instruct"


def hf_best_model(ladder: Optional[list] = None, api_key: Optional[str] = None) -> str:
    """The next-smartest open model the router can serve. Falls back to a known
    id (and says so) if the catalogue can't be reached."""
    try:
        available = hf_models(api_key)
    except Exception as e:
        print(f"[fusion] HF catalogue unreachable ({e}); using {HF_FALLBACK} unverified.",
              file=sys.stderr)
        return HF_FALLBACK
    for want in (ladder or HF_LADDER):
        for mid in available:
            if want in mid.lower():
                return mid
    if available:
        print(f"[fusion] no ladder match; using {available[0]}.", file=sys.stderr)
        return available[0]
    return HF_FALLBACK


def huggingface_call(models: Optional[dict] = None, api_key: Optional[str] = None) -> CallFn:
    """Hugging Face Inference Providers via its OpenAI-compatible router. Reads
    HF_TOKEN / HUGGINGFACE_API_KEY. Model is discovered live unless you pass one."""
    key = api_key or os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_API_KEY")
    if not models:
        best = hf_best_model(api_key=key)
        models = {r: best for r in _ROLES}
    return openai_call(models=models, base_url="https://router.huggingface.co/v1", api_key=key)


# --- Failover: a rate-limited brain hands the seat to the next one ------------ #
_TRANSIENT = ("429", "rate limit", "rate_limit", "quota", "insufficient_quota", "overloaded",
              "capacity", "too many requests", "503", "502", "504", "timeout", "unavailable")


_GONE = ("not_found", "not found", "does not exist", "model_not_found", "unknown model",
         "invalid model", "unsupported model", "no such model", "deprecated", "404")


def _is_transient(err: Exception) -> bool:
    s = str(err).lower()
    return any(t in s for t in _TRANSIENT) and not any(g in s for g in _GONE)


def _is_gone(err: Exception) -> bool:
    """The model itself is unavailable — renamed, retired, or not on this account.
    Different from a rate limit: retrying the SAME model will never help."""
    return any(g in str(err).lower() for g in _GONE)


def _auto_call() -> CallFn:
    load_keyfile()
    live = detect_brains()
    if len(live) > 1:                   # more than one brand reachable — use them all
        print(f"[council] {len(live)} brains reachable — running FUSION, not single-model.",
              file=sys.stderr)
        return fusion_call(brains=live)
    if live:
        print(f"[council] only {BRAINS[live[0]]['label']} is reachable — this is a "
              "single-brain run, NOT fusion. Add another key for cross-brand checking.",
              file=sys.stderr)
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
    p.add_argument("--provider", choices=["auto", "fusion", "anthropic", "openai", "groq",
                                          "openrouter", "gemini", "ollama"], default=None)
    p.add_argument("--brains", action="store_true",
                   help="show which brains are reachable and who would sit where, then exit")
    p.add_argument("--model", help="override the model for all roles (handy for ollama/groq/etc.)")
    p.add_argument("--json", action="store_true", help="print the full record as JSON")
    p.add_argument("--save", metavar="PATH", help="write the Markdown deliberation record to PATH")
    p.add_argument("--quiet", action="store_true", help="suppress stage progress")
    args = p.parse_args(argv)

    if args.brains:
        live = detect_brains()
        if not live:
            print("No brains reachable. Add keys to " + KEYFILE +
                  "\n  ANTHROPIC_API_KEY=...   (Claude)"
                  "\n  OPENAI_API_KEY=...      (GPT / Codex)"
                  "\n  GEMINI_API_KEY=...      (Google AI Studio)")
            return 1
        plan = fusion_plan(live)
        plan["reserve"] = []
        print(describe_fusion(plan))
        for m in missing_brains(plan):
            print(f"  {m}")
        return 0

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
        if getattr(call, "plan", None) and not args.quiet:
            print(describe_fusion(call.plan), file=sys.stderr)
    elif provider == "fusion":
        call = fusion_call(crew=cfg.get("crew"), order=cfg.get("brain_order"))
        if not args.quiet:
            print(describe_fusion(call.plan), file=sys.stderr)
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
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
