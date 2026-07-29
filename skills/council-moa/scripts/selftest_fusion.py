#!/usr/bin/env python3
"""Self-test for the fusion crew. No API keys, no network.

It proves the assignment (Sonnet 5 researches and plans, Opus 5 builds, the
partner builds and synthesizes, Fable 5 verifies), that every model runs at high
effort, that an unavailable model is covered by the next SMARTEST and never a
cheaper one, that the Verifier's rulings become standards the whole crew reads
next time, and that nothing anywhere degrades quietly.

    python3 selftest_fusion.py        # exit 0 = all green
"""
from __future__ import annotations

import contextlib
import io
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import council as C  # noqa: E402

FAILS = []
ALL_KEYS = ("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY",
            "HF_TOKEN", "HUGGINGFACE_API_KEY")


def check(name, cond, detail=""):
    print(f"{'PASS' if cond else 'FAIL'}  {name}{'  — ' + str(detail) if detail else ''}")
    if not cond:
        FAILS.append(name)


def keys(*names):
    for v in ALL_KEYS:
        os.environ.pop(v, None)
    for n in names:
        os.environ[n] = "k"


def stderr_of(fn):
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
        try:
            fn()
        except Exception:
            pass
    return buf.getvalue()


# --- 1. the keyfile ----------------------------------------------------------
def t_keyfile():
    keys()
    with tempfile.NamedTemporaryFile("w", suffix=".env", delete=False) as f:
        f.write("# comment\n\nOPENAI_API_KEY=sk-from-file\nGEMINI_API_KEY=\"quoted-value\"\n")
        path = f.name
    os.environ["ANTHROPIC_API_KEY"] = "already-set"
    C.load_keyfile(path)
    check("keyfile fills missing keys", os.environ.get("OPENAI_API_KEY") == "sk-from-file")
    check("keyfile strips quotes", os.environ.get("GEMINI_API_KEY") == "quoted-value")
    check("keyfile never overrides a live env var", os.environ["ANTHROPIC_API_KEY"] == "already-set")
    C.load_keyfile("/nonexistent/path/fusion.env")
    check("missing keyfile does not crash", True)
    out = stderr_of(lambda: C.load_keyfile(path))
    check("a key the file could not set is reported", "IGNORED" in out, out.strip()[:90])
    os.unlink(path)


# --- 2. the crew assignment --------------------------------------------------
def t_crew():
    keys("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GEMINI_API_KEY")
    p = C.fusion_plan(C.detect_brains())
    check("Sonnet 5 does the research and writes the plan",
          p["triage"][1] == "claude-sonnet-5", p["triage"])
    check("Fable 5 is the Verifier", p["verifier"][1] == "claude-fable-5", p["verifier"])
    check("the partner synthesizes", p["aggregator"][1] == "gpt-5.6-sol", p["aggregator"])
    builders = {s: pair[1] for s, pair in p["seats"].items()}
    check("Opus 5 builds", "claude-opus-5" in builders.values(), json.dumps(builders))
    check("the partner builds too", "gpt-5.6-sol" in builders.values(), json.dumps(builders))
    check("the two builders alternate seat by seat",
          len(set(builders.values())) == 2, json.dumps(builders))
    check("the Synthesist is one of the builders — so the Verifier is the only "
          "independent check", p["aggregator"][1] in builders.values())
    check("the plan is deterministic", C.fusion_plan(C.detect_brains()) == p)

    keys("ANTHROPIC_API_KEY", "GEMINI_API_KEY")
    p2 = C.fusion_plan(C.detect_brains())
    check("with no OpenAI key the partner becomes Gemini",
          p2["aggregator"][1] == "gemini-3.6-flash", p2["aggregator"])
    check("Sonnet still plans and Fable still verifies without OpenAI",
          p2["triage"][1] == "claude-sonnet-5" and p2["verifier"][1] == "claude-fable-5")


# --- 3. only the smartest models --------------------------------------------
def t_models():
    # Suffix-matched on purpose: "gemini" contains "mini", which is not a tier.
    BUDGET = ("-haiku", "-luna", "-mini", "-nano", "-lite", "-flash-8b", "-small")
    for b, spec in C.BRAINS.items():
        for m in spec["ladder"]:
            check(f"{b} ladder carries no budget-tier model: {m}",
                  not any(x in m.lower() for x in BUDGET), m)
    for job, chain in C.CREW.items():
        check(f"the {job} job never falls back to a budget tier",
              not any(x in m.lower() for m in chain for x in BUDGET), str(chain))
        check(f"every model named for {job} is a real model on some company's ladder",
              all(m in C.MODEL_BRAIN for m in chain), str(chain))
    check("every model runs at high effort", C.EFFORT == "high")
    check("high effort means a real thinking budget", C.EFFORT_BUDGET["high"] >= 8000,
          C.EFFORT_BUDGET["high"])


# --- 4. cover: next SMARTEST, never cheaper ----------------------------------
def t_cover():
    keys("ANTHROPIC_API_KEY", "OPENAI_API_KEY")
    check("a retired model is not mistaken for a rate limit",
          C._is_gone(ValueError("404 model_not_found")) and
          not C._is_transient(ValueError("404 model_not_found")))
    check("a rate limit is not mistaken for a retired model",
          C._is_transient(RuntimeError("429 rate limit")) and
          not C._is_gone(RuntimeError("429 rate limit")))

    tried = []

    def fake(brand, model, dead=(), limited=()):
        def call(role, system, user, want_json=False, grounded=False):
            tried.append(model)
            if model in dead:
                raise ValueError(f"404 model_not_found: {model}")
            if model in limited:
                raise RuntimeError("429 rate limit exceeded")
            return f"ok:{model}"
        return call

    real = C._brain_caller
    try:
        C._brain_caller = lambda b, m=None: fake(b, m, dead=("claude-fable-5",))
        out = C.fusion_call()("verifier", "s", "u")
        check("a retired Verifier is covered by the next smartest, not a cheaper one",
              out == "ok:claude-opus-5", out)

        tried.clear()
        C._brain_caller = lambda b, m=None: fake(b, m, limited=("claude-opus-5",))
        out = C.fusion_call()("proposer", "s", "u", seat="skeptic")
        check("a rate-limited builder is covered by the next model in its chain",
              out == "ok:gpt-5.6-sol", out)
        check("it tried the owner first", tried[0] == "claude-opus-5", str(tried))

        tried.clear()
        C._brain_caller = lambda b, m=None: fake(b, m, dead=tuple(C.MODEL_BRAIN))
        try:
            C.fusion_call()("aggregator", "s", "u")
            check("every model dead raises rather than returning nothing", False)
        except Exception:
            check("every model dead raises rather than returning nothing", True)

        tried.clear()
        C._brain_caller = lambda b, m=None: (lambda *a, **k: (_ for _ in ()).throw(
            ValueError("401 invalid api key")))
        try:
            C.fusion_call()("aggregator", "s", "u")
            check("a real error is never swallowed", False, "no exception")
        except ValueError:
            check("a real error is never swallowed", True)
    finally:
        C._brain_caller = real


# --- 5. learning from the Verifier -------------------------------------------
def t_learning():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "lessons.md")
        check("no lessons file yet means no prefix", C.lessons_prefix(p) == "")

        n = C.record_lessons({"verdict": "revise",
                              "issues": [{"severity": "high", "issue": "cite the source"},
                                         {"severity": "low", "issue": "state the assumption"}],
                              "notes": "always name what you did not check"},
                             "Should we ship?", p)
        check("the Verifier's rulings are recorded", n == 3, n)   # 2 issues + the note

        pre = C.lessons_prefix(p)
        check("the notebook reaches every worker's prompt", "CREW NOTEBOOK" in pre)
        check("each ruling is carried verbatim",
              "cite the source" in pre and "state the assumption" in pre)
        check("the Verifier's note becomes a standard too",
              "always name what you did not check" in pre)
        check("rulings are framed as binding, not advisory", "binding" in pre)

        # sideways: every model learns what the others brought, attributed BY MODEL
        n2 = C.record_lessons(
            {"issues": []}, "Peer run", p,
            evaluations=[{"agent": "skeptic", "score": 9,
                          "critique": "strongest: named the failure mode nobody priced in; "
                                      "blind spot: no cost estimate"},
                         {"agent": "engineer", "score": 6,
                          "critique": "strongest: concrete mechanism; blind spot: ignored the "
                                      "rollout risk"}],
            seat_models={"skeptic": "claude-opus-5", "engineer": "gpt-5.6-sol"})
        check("what each model brought is recorded", n2 == 2, n2)
        pre_p = C.lessons_prefix(p)
        check("crewmate notes are attributed to the MODEL, not just the lens",
              "claude-opus-5 as The Skeptic" in pre_p and "gpt-5.6-sol as The Engineer" in pre_p,
              [l for l in pre_p.splitlines() if "as The" in l][:1])
        check("scores are carried so the crew can tell what worked",
              "scored 9/10" in pre_p and "scored 6/10" in pre_p)
        check("both what worked and the blind spot survive",
              "named the failure mode" in pre_p and "ignored the rollout risk" in pre_p)
        check("the notebook tells them to copy what scored and watch the blind spots",
              "copy the moves that scored" in pre_p and "blind spots" in pre_p)
        check("peer notes alone are enough to record — no Verifier issue needed", n2 > 0)

        C.record_lessons({"issues": [{"severity": "high", "issue": "second run ruling"}]},
                         "Another question", p)
        pre2 = C.lessons_prefix(p)
        check("standards accumulate across runs",
              "cite the source" in pre2 and "second run ruling" in pre2)

        big = os.path.join(d, "big.md")
        open(big, "w").write("\n".join(f"- [note] filler ruling {i}" for i in range(2000)))
        pre3 = C.lessons_prefix(big)
        check("an overgrown lessons file is trimmed, newest kept",
              len(pre3) < C.LESSONS_MAX + 600 and "filler ruling 1999" in pre3, len(pre3))

        check("nothing to record is not recorded", C.record_lessons({"issues": []}, "q", p) == 0)

    # the crew actually carries them: every call gets the standards prepended
    keys("ANTHROPIC_API_KEY")
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "lessons.md")
        C.record_lessons({"issues": [{"severity": "high", "issue": "SENTINEL-STANDARD"}]}, "q", p)
        seen = {}

        def fake(brand, model):
            def call(role, system, user, want_json=False, grounded=False):
                seen[role] = system
                return "ok"
            return call

        real = C._brain_caller
        try:
            C._brain_caller = fake
            call = C.fusion_call(lessons_path=p)
            call("proposer", "BUILD THIS", "u", seat="skeptic")
            call("aggregator", "SYNTHESIZE", "u")
            call("verifier", "VERIFY", "u")
            call("triage", "PLAN", "u")
        finally:
            C._brain_caller = real
        check("the builder is held to the Verifier's standards",
              "SENTINEL-STANDARD" in seen["proposer"] and "BUILD THIS" in seen["proposer"])
        check("the Synthesist is held to them too", "SENTINEL-STANDARD" in seen["aggregator"])
        check("the Verifier reads the notebook as well — it learns from the crew too",
              "SENTINEL-STANDARD" in seen["verifier"])
        check("so does the researcher who writes the plan",
              "SENTINEL-STANDARD" in seen["triage"])


# --- 6. the full pipeline ----------------------------------------------------
def t_pipeline():
    keys("ANTHROPIC_API_KEY", "OPENAI_API_KEY", "GEMINI_API_KEY")
    used = []

    def fake(brand, model):
        def call(role, system, user, want_json=False, grounded=False):
            used.append((role, model))
            if role == "triage":
                return json.dumps({"type": "technical", "grounding_useful": False,
                                   "council": ["skeptic", "engineer", "analyst", "pragmatist"],
                                   "reasoning": "test"})
            if role == "aggregator":
                return json.dumps({"synthesis": f"built-and-synthesized-by-{model}",
                                   "reasoning": "r", "consensus": "strong",
                                   "evaluations": [{"agent": "skeptic", "score": 8,
                                                    "critique": "strongest: found the edge case"},
                                                   {"agent": "engineer", "score": 5,
                                                    "critique": "blind spot: no rollout plan"}]})
            if role == "verifier":
                return json.dumps({"verdict": "pass", "issues":
                                   [{"severity": "low", "issue": "tighten the claim"}],
                                   "notes": "show the measurement"})
            return f"build-by-{model}"
        return call

    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "lessons.md")
        real = C._brain_caller
        try:
            C._brain_caller = fake
            router = C.fusion_call(lessons_path=p)
            rec = C.council("Test question?", call=router, depth="deep")
        finally:
            C._brain_caller = real

        by_role = {}
        for role, model in used:
            by_role.setdefault(role, set()).add(model)
        check("research + plan ran on Sonnet 5", by_role["triage"] == {"claude-sonnet-5"},
              str(by_role.get("triage")))
        check("the build ran on Opus 5 AND the partner",
              by_role["proposer"] == {"claude-opus-5", "gpt-5.6-sol"}, str(by_role["proposer"]))
        check("the synthesis ran on the partner", by_role["aggregator"] == {"gpt-5.6-sol"},
              str(by_role["aggregator"]))
        check("the verification ran on Fable 5", by_role["verifier"] == {"claude-fable-5"},
              str(by_role["verifier"]))
        check("a decision came out", rec["decision"] == "built-and-synthesized-by-gpt-5.6-sol",
              rec["decision"])
        check("the run wrote both the ruling and the peer notes to the notebook",
              rec.get("lessons_recorded") == 4, rec.get("lessons_recorded"))
        nb = C.lessons_prefix(p)
        check("the Verifier's ruling is on disk for the next run",
              "tighten the claim" in nb and "show the measurement" in nb)
        check("and so is what each model brought, by model name",
              "claude-opus-5 as The Skeptic" in nb and "found the edge case" in nb, 
              [l for l in nb.splitlines() if "as The Skeptic" in l][:1])
        check("builder seats were re-assigned to the council that was actually seated",
              set(router.plan["seats"]) == set(rec["council"]), str(sorted(router.plan["seats"])))


# --- 7. nothing degrades quietly ---------------------------------------------
def t_loud():
    keys("ANTHROPIC_API_KEY")
    real = C._brain_caller
    try:
        C._brain_caller = lambda b, m=None: (lambda *a, **k: "x")
        out = stderr_of(lambda: C.fusion_call())
        check("no partner company is called out, not hidden",
              "NO PARTNER MODEL REACHABLE" in out, out.strip().splitlines()[0:1])
        for brand, envvar in (("GPT / Codex (OpenAI)", "OPENAI_API_KEY"),
                              ("Gemini (Google AI Studio)", "GEMINI_API_KEY"),
                              ("Hugging Face (open models)", "HF_TOKEN")):
            check(f"an unusable model is named: {brand}",
                  f"{brand} — NOT USED: no key found" in out and envvar in out,
                  next((l.strip() for l in out.splitlines() if brand in l), "not mentioned"))
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

    def dead_builder(role, system, user, want_json=False, grounded=False, seat=None):
        if role == "proposer" and seat == "skeptic":
            raise RuntimeError("builder exploded")
        if role == "triage":
            return json.dumps({"type": "other", "grounding_useful": False,
                               "council": ["skeptic", "analyst", "pragmatist", "visionary"],
                               "reasoning": "t"})
        if role == "aggregator":
            return json.dumps({"synthesis": "d", "evaluations": [], "consensus": "weak"})
        if role == "verifier":
            return json.dumps({"verdict": "pass", "issues": []})
        return "x"
    out = stderr_of(lambda: C.council("Q?", call=dead_builder, depth="deep"))
    check("a builder that never answered is named", "never answered" in out and "Skeptic" in out)

    with tempfile.TemporaryDirectory() as d:
        out = stderr_of(lambda: C.record_lessons(
            {"issues": [{"severity": "high", "issue": "x"}]}, "q",
            os.path.join(d, "sub", "lessons.md")))
        check("recording the notebook says so out loud",
              "crew notebook updated" in out and "1 binding ruling" in out, out.strip())


# --- 8. old single-model callers still work ----------------------------------
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
    check("a caller that never heard of the crew still runs", rec["decision"] == "ok")
    check("legacy caller saw the build calls", "proposer" in calls)


for t in (t_keyfile, t_crew, t_models, t_cover, t_learning, t_pipeline, t_loud, t_backcompat):
    print(f"\n--- {t.__name__} ---")
    t()

print("\n" + ("ALL GREEN" if not FAILS else f"{len(FAILS)} FAILED: {FAILS}"))
sys.exit(1 if FAILS else 0)
