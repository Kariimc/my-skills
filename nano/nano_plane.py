#!/usr/bin/env python3
"""nano-plane — your whole control plane in one readable file.

The real system (C:/Dev/my-skills) is 411 skills, 6 gates, and a sync engine.
This file is the SAME three load-bearing ideas in ~150 lines you can read top
to bottom. If you understand this file, you understand your system.
(Karpathy rule: what I cannot create, I do not understand.)

  1. ROUTE  — hooks/harness-router.sh in miniature: ordered regex table,
              first match wins, silence when nothing matches.
  2. GATE   — bin/apex-gates.sh in miniature: mechanical checks that either
              pass or block; a mistake becomes a new check, permanently.
  3. LOOP   — rules/00-core.md as executable structure:
              understand -> smallest change -> prove it -> distill.

Try it:
  python nano_plane.py route "build me a todo app"
  python nano_plane.py route "thanks!"
  python nano_plane.py gate  some_file.py
  python nano_plane.py loop  "add an /export endpoint"
"""

import re
import sys
from pathlib import Path

# ── 1. ROUTE ─────────────────────────────────────────────────────────────────
# The real router is just this: an ORDERED list of (name, [patterns]).
# Order is load-bearing — "audit for dead code" must hit audit before refactor.
# First match wins; no match means stay silent (the model just works normally).

ROUTES = [
    ("harness-autonomous", [r"\bevery (day|hour|week)\b", r"\bmonitor\b", r"\bkeep (checking|running)\b", r"\bschedule\b"]),
    ("harness-audit",      [r"\baudit\b", r"\bassess\b", r"\bwhat'?s (broken|missing|redundant)\b", r"\bcheck .* for (bugs|issues|problems|security)\b"]),
    ("harness-research",   [r"\bresearch\b", r"\binvestigate\b", r"\bcompare\b", r"\bwhat'?s the best\b"]),
    ("harness-quality",    [r"\bproduction[- ]?(quality|grade)\b", r"\bno slop\b", r"\bmust be polished?\b", r"\bbeautiful\b"]),
    ("harness-refactor",   [r"\brefactor\b", r"\bsimplif", r"\bdedup", r"\bremove dead code\b", r"\bclean up (the |this )?code\b"]),
    ("harness-build",      [r"\bbuild (me |a |an |the )", r"\bimplement\b", r"\bship (a|an|the)\b", r"\bcreate (a|an) (app|api|tool|site|feature)\b"]),
]

def route(prompt: str) -> str | None:
    """Return the first matching harness, or None (= handle it directly)."""
    p = prompt.lower()
    for name, patterns in ROUTES:
        if any(re.search(pat, p) for pat in patterns):
            return name
    return None  # silence is a feature: most prompts need no orchestration

# ── 2. GATE ──────────────────────────────────────────────────────────────────
# A gate is a function file -> list of problems. Empty list = pass.
# The apex idea in one sentence: every mistake that ever burned you becomes a
# gate, so it can happen AT MOST ONCE. (See apex/MISTAKE-LEDGER.md — entry #9
# is a real one: a bare 40-hex token slipped past a prefixed-only pattern.)

def gate_no_bare_hex_token(text: str) -> list[str]:
    hits = re.findall(r"(?<![0-9a-fA-Fx])[0-9a-fA-F]{40}(?![0-9a-fA-F])", text)
    # a 40-hex run next to the word "commit"/"sha" is a git SHA, not a secret
    return [f"possible bare token: {h[:8]}..." for h in hits
            if not re.search(r"\b(sha|commit|rev)\b", text, re.I)]

def gate_no_prefixed_secret(text: str) -> list[str]:
    # NOTE: pattern passed with re.search, so no grep '-----looks-like-a-flag'
    # trap here — but that exact trap silently disabled the real bash gate
    # for months. Lesson: TEST the gate catches a planted secret, not just
    # that it passes clean. (ledger #9)
    pat = r"gh[pousr]_[0-9A-Za-z]{36,}|sk-[A-Za-z0-9]{32,}|AKIA[0-9A-Z]{16}"
    return [f"prefixed secret: {m[:8]}..." for m in re.findall(pat, text)]

def gate_has_loop_bound(text: str) -> list[str]:
    # loop-safety gate from rules/00-core: while True without a break is a bug
    problems = []
    for i, line in enumerate(text.splitlines(), 1):
        if re.search(r"while\s+(True|1)\b", line) and "break" not in text:
            problems.append(f"line {i}: unbounded loop with no break anywhere")
    return problems

GATES = [gate_no_bare_hex_token, gate_no_prefixed_secret, gate_has_loop_bound]

def gate(path: str) -> list[str]:
    text = Path(path).read_text(encoding="utf-8", errors="replace")
    return [p for g in GATES for p in g(text)]

# ── 3. LOOP ──────────────────────────────────────────────────────────────────
# The core loop is a CHECKLIST the work must pass through, in order. In the
# real system the model does each step; here the structure itself is the point.

LOOP = [
    ("UNDERSTAND", "Read what's there. Never modify what you haven't read."),
    ("SMALLEST CHANGE", "Prefer deleting to adding. No new dep when 50 plain lines do."),
    ("PROVE IT", "Run it. 'Works' = the command's real output, plus: no secrets in the diff, loops terminate."),
    # ASCII only in printed strings: Windows consoles default to cp1252 and
    # crash on unicode arrows — the exact bug that once broke the real router.
    ("DISTILL", "Hard problem solved? Write symptom->cause->fix where the next session will find it."),
]

def loop(task: str) -> None:
    print(f"task: {task}")
    suggested = route(task)
    print(f"route: {suggested or 'none - do it directly (default simple)'}")
    for step, rule in LOOP:
        print(f"  [{step:>15}] {rule}")
    print("gate: run `nano_plane.py gate <changed-file>` before you call it done.")

# ── CLI ──────────────────────────────────────────────────────────────────────
def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    cmd, arg = sys.argv[1], " ".join(sys.argv[2:])
    if cmd == "route":
        print(route(arg) or "none")
        return 0
    if cmd == "gate":
        problems = gate(arg)
        for p in problems:
            print(f"BLOCKED: {p}")
        print("PASS" if not problems else f"{len(problems)} problem(s)")
        return 1 if problems else 0
    if cmd == "loop":
        loop(arg)
        return 0
    print(f"unknown command: {cmd}")
    return 2

if __name__ == "__main__":
    sys.exit(main())
