#!/bin/bash
# ledger-sentinel.sh — UserPromptSubmit hook.
# Puts matching FAILURES.md (banned roads) and PLAYBOOK.md (proven methods)
# entries IN FRONT of the agent at plan time, so a dead road cannot be
# "forgotten" (ledger F-49: a banned method reused twice while already in the
# ledger). Enforcement plan item #2 (docs/RULE-ENFORCEMENT-STREAMLINE-PLAN.md).
#
# Output contract: for UserPromptSubmit, stdout (exit 0) is added to context.
# Prints at most one short block with up to 3 matches per ledger, or nothing.
# Fail-open by design: no python, no ledgers, weird payload → silent exit 0.
# Never blocks; it only informs.
input="$(cat)"

PY=""
if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else exit 0
fi

export SENTINEL_INPUT="$input"
"$PY" - <<'PY' 2>/dev/null
import json, os, re, sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

try:
    data = json.loads(os.environ.get("SENTINEL_INPUT") or "{}")
except Exception:
    raise SystemExit(0)

prompt = (data.get("prompt") or "").lower()
if len(prompt) < 20:          # trivial prompts: stay silent, zero overhead
    raise SystemExit(0)

# Locate the ledgers: prefer the project copy, fall back to ~/.claude.
roots = [data.get("cwd") or "", os.path.expanduser("~/.claude"),
         os.path.expanduser("~/my-skills")]
STOP = {"the","a","an","and","for","with","that","this","from","into","when",
        "make","build","need","want","please","then","them","they","have","will",
        "your","just","like","what","how","can","you","our","are","was","not"}
words = {w for w in re.findall(r"[a-z][a-z0-9-]{3,}", prompt)} - STOP
if not words:
    raise SystemExit(0)

def scan(fname, pat):
    for root in roots:
        p = os.path.join(root, fname)
        if os.path.isfile(p):
            try:
                with open(p, encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except Exception:
                return []
            hits = []
            for line in text.splitlines():
                if re.match(pat, line):
                    lw = set(re.findall(r"[a-z][a-z0-9-]{3,}", line.lower())) - STOP
                    score = len(lw & words)
                    if score >= 2:
                        hits.append((score, line.lstrip("# ").strip()))
            hits.sort(key=lambda t: -t[0])
            return [h[1] for h in hits[:3]]
    return []

dead  = scan("FAILURES.md", r"^## F-\d+")
alive = scan("PLAYBOOK.md", r"^## P-\d+")
if not dead and not alive:
    raise SystemExit(0)

print("[ledger-sentinel] This task matches ledger entries — read them BEFORE planning:")
for h in dead:
    print(f"  BANNED ROAD  · {h}")
for h in alive:
    print(f"  PROVEN METHOD· {h}")
print("  (Full entries in FAILURES.md / PLAYBOOK.md. Repeating a banned road is a rule violation, not a judgment call.)")
PY
exit 0
