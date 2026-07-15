#!/bin/bash
# loose-ends-guard.sh — Stop guardrail.
# Blocks a reply that hands Kariim work or a check to run himself (his #1 rule:
# never make him the runner or checker). Self-contained (embeds its own python)
# so the *.sh-only session-start sync carries it whole. Blocks at most once per
# turn (stop_hook_active) and fails open, so it can never lock a session.
#
# Exit 0 = allow. Exit 2 = block (Claude rewrites, then finishes).
input="$(cat)"

case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

GUARD_PY=""
for cand in \
  "$LOCALAPPDATA/Python/pythoncore-3.14-64/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python313/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python312/python.exe"; do
  [ -x "$cand" ] && GUARD_PY="$cand" && break
done
if [ -z "$GUARD_PY" ]; then
  if command -v python >/dev/null 2>&1; then GUARD_PY=python
  elif command -v python3 >/dev/null 2>&1; then GUARD_PY=python3
  else exit 0
  fi
fi

"$GUARD_PY" - "$input" <<'PY'
import json, sys, re

PATTERNS = [
    r"\byou(?:'ll| will)? (?:need|have) to\b",
    r"\byou should (?:test|run|check|verify|grade|open|click|press|try|confirm|make sure|do|paste|copy)\b",
    r"\bplease (?:run|test|check|verify|confirm|paste|copy|open|try|grade)\b",
    r"\brun (?:this|it yourself|the following|these)\b",
    r"\b(?:paste|copy) (?:this|the following|these)\b",
    r"\bmake sure you\b",
    r"\bdon'?t forget to\b",
    r"\bbe sure to\b",
    r"\bremember to\b",
    r"\bwhen you get a chance\b",
    r"\byou might want to\b",
    r"\byou may want to\b",
    r"\bfeel free to\b",
    r"\byour (?:check|checks|job) (?:is|are)\b",
    r"\bgo ahead and (?:run|test|check|open|paste|verify)\b",
    r"\bcan you (?:run|check|test|verify|confirm|paste|open)\b",
]

def last_assistant_text(tp):
    text = ""
    try:
        with open(tp, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    ev = json.loads(line)
                except Exception:
                    continue
                if ev.get("type") == "assistant":
                    parts = ev.get("message", {}).get("content", [])
                    buf = [p.get("text", "") for p in parts
                           if isinstance(p, dict) and p.get("type") == "text"]
                    if buf:
                        text = "\n".join(buf)
    except Exception:
        return ""
    return text

try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)
tp = data.get("transcript_path")
if not tp:
    sys.exit(0)
text = last_assistant_text(tp)
if not text.strip():
    sys.exit(0)

for pat in PATTERNS:
    if re.search(pat, text, re.I):
        msg = ("GUARDRAIL BLOCKED (No legwork): your last reply hands Kariim "
               "work or a check to run - his #1 rule forbids making him the "
               "runner or the checker. Do it yourself through your tools. If it "
               "is a TRUE wall (a password, his physical mic or eyes, or an "
               "outside-world action only he can take), say that in ONE line and "
               "nothing else. Rewrite before finishing.")
        sys.stderr.write(msg + "\n")
        sys.stdout.write(msg + "\n")
        sys.exit(2)
sys.exit(0)
PY
