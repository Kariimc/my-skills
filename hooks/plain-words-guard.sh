#!/bin/bash
# plain-words-guard.sh — Stop guardrail.
# Blocks a reply to Kariim that breaks his "plain words" rule: commit codes,
# file names/paths, dev jargon, or a wall of text. Self-contained (embeds its
# own python) so the *.sh-only sync in session-start.sh carries it whole, with
# no sidecar file that could silently drop out. Blocks at most once per turn
# (stop_hook_active) and fails open, so it can never lock a session.
#
# Exit 0 = allow. Exit 2 = block (Claude rewrites, then finishes).
input="$(cat)"

case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

# Resolve a real python (skip the Windows Store stub); fail open if none.
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

tells = []
for m in re.findall(r'\b[0-9a-fA-F]{7,40}\b', text):
    ml = m.lower()
    if any(c.isdigit() for c in ml) and any(c in 'abcdef' for c in ml):
        tells.append("commit codes")
        break
if (re.search(r'\b[\w./\\-]+\.(tsx?|jsx?|mjs|py|css|ps1|vbs|json|md|html)\b', text)
        or re.search(r'\b(neural-ui|dashboard|scripts|\.claude)[/\\]', text)
        or re.search(r'[A-Za-z]:\\Users', text)):
    tells.append("file names")
jargon = (r'\b(tsc|npm|vite|node|byte-?identical|byte-?identity|headless|curl|'
          r'endpoint|regex|schema|py_compile|commit(?:ted|s)?|git\s+push|'
          r'pushed to|dist|useVoice|speakGen|STOP_RE|/api/|sim-?voice|'
          r'ChipGlyph|BUILD-PLAN|PROGRESS|HANDOFF|repo|screenshot|localhost|'
          r'127\.0\.0\.1)\b')
if re.search(jargon, text, re.I):
    tells.append("dev jargon")
lines = [l for l in text.splitlines() if l.strip()]
if len(lines) > 16 or len(text) > 1400:
    tells.append("a wall of text")

if tells:
    msg = ("GUARDRAIL BLOCKED (Plain words): your last reply to Kariim has ["
           + ", ".join(sorted(set(tells)))
           + "] in it - things his rules say to NEVER put in chat. Rewrite it "
             "before finishing: the result first in one or two plain lines, "
             "everyday words, no commit codes, no file names or paths, no tool "
             "or dev jargon, no wall of text. Put what he actually needs right "
             "in front of him, then finish.")
    sys.stderr.write(msg + "\n")
    sys.stdout.write(msg + "\n")
    sys.exit(2)
sys.exit(0)
PY
