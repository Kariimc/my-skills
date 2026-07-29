#!/usr/bin/env python3
"""Self-test for multi-brain fusion. No API keys, no network — it proves the
routing: who sits where, that the Adversary is a different brand from the
Arbiter, that a missing brain degrades honestly, and that the whole pipeline
runs end to end with every seat landing on the brand it was assigned.

    python3 selftest_fusion.py        # exit 0 = all green
"""
from __future__ import annotations

import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import council as C  # noqa: E402

FAILS = []


def check(name, cond, detail=""):
    print(f"{'PASS' if cond else 'FAIL'}  {name}{'  — ' + detail if detail else ''}")
    if not cond:
        FAILS.append(name)


# --- 1. key detection reads the keyfile and never clobbers a real env var ----
def t_keyfile():
    for v in ("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY"):
        os.environ.pop(v, None)
    with tempfile.NamedTemporaryFile("w", suffix=".env", delete=False) as f:
        f.write("# comment\n\nOPENAI_API_KEY=sk-from-file\n"
                'GEMINI_API_KEY="quoted-value"\n')
        path = f.name
    os.environ["ANTHROPIC_API_KEY"] = "already-set"
    C.load_keyfile(path)
    check("keyfile fills missing keys", os.environ.get("OPENAI_API_KEY") == "sk-from-file")
    check("keyfile strips quotes", os.environ.get("GEMINI_API_KEY") == "quoted-value")
    check("keyfile never overrides a live env var", os.environ["ANTHROPIC_API_KEY"] == "already-set")
    C.load_keyfile("/nonexistent/path/fusion.env")   # must not raise
    check("missing keyfile is silent", True)
    os.unlink(path)


# --- 2. detection + seating ---------------------------------------------------
def t_seating():
    for v in ("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY"):
        os.environ.pop(v, None)
    C.load_keyfile("/nonexistent")
    check("no keys -> no brains", C.detect_brains() == [])

    os.environ["GEMINI_API_KEY"] = "k"
    check("AI Studio key alone is seen", C.detect_brains() == ["gemini"])
    os.environ["OPENAI_API_KEY"] = "k"
    os.environ["ANTHROPIC_API_KEY"] = "k"
    check("all three seen, strongest first", C.detect_brains() == ["claude", "gpt", "gemini"])

    three = C.fusion_seating(["claude", "gpt", "gemini"])
    check("Arbiter is the strongest brain", three["aggregator"] == "claude")
    check("Adversary is a DIFFERENT brand", three["verifier"] != three["aggregator"],
          f"{three['aggregator']} judged by {three['verifier']}")
    seat_brands = set(three["seats"].values())
    check("advisors spread across all 3 brands", seat_brands == {"claude", "gpt", "gemini"},
          json.dumps(three["seats"]))
    check("seating is deterministic", C.fusion_seating(["claude", "gpt", "gemini"]) == three)

    two = C.fusion_seating(["claude", "gemini"])
    check("2 brains still cross-check", two["verifier"] == "gemini" and two["aggregator"] == "claude")

    one = C.fusion_seating(["gemini"])
    check("1 brain degrades instead of crashing", one["verifier"] == one["aggregator"] == "gemini")
    check("1-brain roster says so out loud",
          "only one brain is reachable" in C.describe_fusion(one))


# --- 3. full pipeline on stand-in brains --------------------------------------
def t_pipeline():
    seen = []                      # (brand, role, seat)

    def fake(brand):
        def call(role, system, user, want_json=False, grounded=False):
            seen.append((brand, role))
            if role == "triage":
                return json.dumps({"type": "technical", "grounding_useful": False,
                                   "council": ["skeptic", "engineer", "analyst", "pragmatist"],
                                   "reasoning": "test"})
            if role == "aggregator":
                return json.dumps({"synthesis": f"decision-by-{brand}", "reasoning": "r",
                                   "consensus": "strong", "evaluations": []})
            if role == "verifier":
                return json.dumps({"verdict": "pass", "issues": [], "notes": ""})
            return f"answer-from-{brand}"
        return call

    real = C._brain_caller
    try:
        C._brain_caller = lambda b, m=None: fake(b)
        router = C.fusion_call(brains=["claude", "gpt", "gemini"])
        plan = router.plan
        rec = C.council("Test question?", call=router, depth="deep")
    finally:
        C._brain_caller = real
    check("pipeline produced a decision", bool(rec["decision"]), rec["decision"])
    check("decision came from the Arbiter's brand",
          rec["decision"] == f"decision-by-{plan['aggregator']}")
    check("verification ran", (rec.get("verification") or {}).get("verdict") == "pass")

    roles_by_brand = {}
    for brand, role in [x for x in seen if x[0] in plan["brains"]]:
        roles_by_brand.setdefault(brand, set()).add(role)
    check("every brain actually did work", set(roles_by_brand) == set(plan["brains"]),
          json.dumps({k: sorted(v) for k, v in roles_by_brand.items()}))
    check("verifier work landed on the rival brand",
          "verifier" in roles_by_brand.get(plan["verifier"], set())
          and "verifier" not in roles_by_brand.get(plan["aggregator"], set()))

    check("seats were re-dealt to the council that was actually seated",
          set(plan["seats"]) == set(rec["council"]) and set(plan["seats"].values()) == set(plan["brains"]),
          json.dumps(plan["seats"]))
    check("every seated advisor's brain produced an answer",
          all(a["r1"] == f"answer-from-{plan['seats'][a['id']]}" for a in rec["advisors"]))


# --- 3b. the re-deal: every brain gets an advisor once the council is known ---
def t_redeal():
    for brains in (["claude", "gpt", "gemini"], ["claude", "gpt"], ["claude", "gpt", "gemini", "hf"]):
        for ids in (["skeptic", "engineer", "analyst", "pragmatist"],
                    ["skeptic", "humanist", "visionary", "strategist"]):
            seats = C.fusion_seating(brains, ids)["seats"]
            check(f"{len(brains)} brains all seated for {ids[1]}-style council",
                  set(seats.values()) == set(brains) and set(seats) == set(ids),
                  json.dumps(seats))


# --- 3c. failover: a rate-limited brain hands the seat over -------------------
def t_failover():
    os.environ.update({"ANTHROPIC_API_KEY": "k", "OPENAI_API_KEY": "k", "GEMINI_API_KEY": "k"})
    os.environ.pop("HF_TOKEN", None)
    os.environ["HUGGINGFACE_API_KEY"] = "k"          # reserve brain available
    log = []

    def fake(brand, fail=False, hard=False):
        def call(role, system, user, want_json=False, grounded=False):
            log.append((brand, role))
            if hard:
                raise ValueError("401 invalid api key")
            if fail:
                raise RuntimeError("429 Too Many Requests: rate limit exceeded")
            return f"ok-{brand}"
        return call

    real = C._brain_caller
    try:
        C._brain_caller = lambda b, m=None: fake(b, fail=(b == "claude"))
        call = C.fusion_call(brains=["claude", "gpt", "gemini"])
        check("reserve detected from HF key", call.plan["reserve"] == ["hf"], str(call.plan["reserve"]))
        out = call("aggregator", "s", "u")
        check("rate-limited Arbiter is covered by another brain", out == "ok-gpt", out)
        check("the limited brain was tried first", log[0] == ("claude", "aggregator"))

        log.clear()
        C._brain_caller = lambda b, m=None: fake(b, fail=(b in ("claude", "gpt", "gemini")))
        call = C.fusion_call(brains=["claude", "gpt", "gemini"])
        out = call("proposer", "s", "u", seat="skeptic")
        check("all three limited -> open-model reserve answers", out == "ok-hf", out)

        log.clear()
        C._brain_caller = lambda b, m=None: fake(b, hard=True)
        call = C.fusion_call(brains=["claude", "gpt"])
        try:
            call("verifier", "s", "u")
            check("a real error is never swallowed", False, "no exception raised")
        except ValueError:
            check("a real error is never swallowed", True)
            check("a real error does not burn the other brains", len(log) == 1, str(log))
    finally:
        C._brain_caller = real


# --- 3d. Hugging Face ladder picks the smartest servable model ----------------
def t_hf_ladder():
    real = C.hf_models
    try:
        C.hf_models = lambda *a, **k: ["meta-llama/Llama-3.3-70B-Instruct",
                                       "moonshotai/Kimi-K2.7-Code", "Qwen/Qwen3-32B"]
        check("ladder picks the smarter of what is served",
              C.hf_best_model() == "moonshotai/Kimi-K2.7-Code", C.hf_best_model())

        C.hf_models = lambda *a, **k: ["some/unknown-model-v1"]
        check("no ladder match still returns something servable",
              C.hf_best_model() == "some/unknown-model-v1")

        def boom(*a, **k):
            raise OSError("network down")
        C.hf_models = boom
        check("unreachable catalogue falls back and says so",
              C.hf_best_model() == C.HF_FALLBACK)
    finally:
        C.hf_models = real


# --- 4. old single-brand callers still work untouched -------------------------
def t_backcompat():
    calls = []

    def legacy(role, system, user, want_json=False, grounded=False):   # no seat kwarg
        calls.append(role)
        if role == "aggregator":
            return json.dumps({"synthesis": "ok", "evaluations": [], "consensus": "weak"})
        if role == "verifier":
            return json.dumps({"verdict": "pass", "issues": []})
        return "x"

    rec = C.council("Q?", call=legacy, depth="quick")
    check("a caller that never heard of seats still runs", rec["decision"] == "ok")
    check("legacy caller saw proposer calls", "proposer" in calls)


# --- 5. nothing degrades quietly ---------------------------------------------
def t_loud():
    import contextlib, io

    def stderr_of(fn):
        buf = io.StringIO()
        with contextlib.redirect_stderr(buf):
            try:
                fn()
            except Exception:
                pass
        return buf.getvalue()

    real = C._brain_caller
    try:
        C._brain_caller = lambda b, m=None: (lambda *a, **k: "x")
        out = stderr_of(lambda: C.fusion_call(brains=["claude"]))
        check("one brain shouts that it is NOT fusion", "ONLY ONE BRAIN REACHABLE" in out, out.strip())
    finally:
        C._brain_caller = real

    for v in ("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY",
              "HF_TOKEN", "HUGGINGFACE_API_KEY"):
        os.environ.pop(v, None)
    os.environ["ANTHROPIC_API_KEY"] = "k"
    real = C._brain_caller
    try:
        C._brain_caller = lambda b, m=None: (lambda *a, **k: "x")
        out = stderr_of(lambda: C.fusion_call())
        for brand, envvar in (("GPT / Codex (OpenAI)", "OPENAI_API_KEY"),
                              ("Gemini (Google AI Studio)", "GEMINI_API_KEY"),
                              ("Hugging Face (open models)", "HF_TOKEN")):
            check(f"an unusable model is named: {brand}",
                  f"{brand} — NOT USED: no key found" in out and envvar in out,
                  next((l.strip() for l in out.splitlines() if brand in l), "not mentioned at all"))
    finally:
        C._brain_caller = real

    def dead_verifier(role, system, user, want_json=False, grounded=False):
        if role == "verifier":
            raise RuntimeError("verifier exploded")
        if role == "aggregator":
            return json.dumps({"synthesis": "d", "evaluations": [], "consensus": "weak"})
        return "x"
    out = stderr_of(lambda: C.council("Q?", call=dead_verifier, depth="deep"))
    check("a skipped verification says the answer is UNVERIFIED", "UNVERIFIED" in out)

    def dead_advisor(role, system, user, want_json=False, grounded=False, seat=None):
        if role == "proposer" and seat == "skeptic":
            raise RuntimeError("advisor exploded")
        if role == "triage":
            return json.dumps({"type": "other", "grounding_useful": False,
                               "council": ["skeptic", "analyst", "pragmatist", "visionary"],
                               "reasoning": "t"})
        if role == "aggregator":
            return json.dumps({"synthesis": "d", "evaluations": [], "consensus": "weak"})
        if role == "verifier":
            return json.dumps({"verdict": "pass", "issues": []})
        return "x"
    out = stderr_of(lambda: C.council("Q?", call=dead_advisor, depth="deep"))
    check("a missing advisor is named, not hidden", "never answered" in out and "Skeptic" in out,
          out.strip().splitlines()[-1] if out else "")

    with tempfile.NamedTemporaryFile("w", suffix=".env", delete=False) as f:
        f.write("ANTHROPIC_API_KEY=from-file\n")
        p = f.name
    os.environ["ANTHROPIC_API_KEY"] = "from-env"
    out = stderr_of(lambda: C.load_keyfile(p))
    check("a key the file could not set is reported, not swallowed", "IGNORED" in out, out.strip())
    os.unlink(p)


for t in (t_keyfile, t_seating, t_pipeline, t_redeal, t_failover, t_hf_ladder, t_backcompat, t_loud):
    print(f"\n--- {t.__name__} ---")
    t()

print("\n" + ("ALL GREEN" if not FAILS else f"{len(FAILS)} FAILED: {FAILS}"))
sys.exit(1 if FAILS else 0)
