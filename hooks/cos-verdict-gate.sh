#!/bin/bash
# cos-verdict-gate.sh — Stop hook: fail-closed Chief-of-Staff enforcement (rule 15).
#
# Inert unless ~/.claude/cos/ENFORCE exists (only Kariim orders that file into
# being — the path is guard-locked). When armed: a session that did build-work
# (Edit/Write/NotebookEdit anywhere in its transcript) may not finish until a
# CoS verdict is recorded at ~/.claude/cos/verdicts/<session_id>. Sessions with
# no file mutations are trivial and pass untouched (rule 15's exemption).
# Loop-safe: when stop_hook_active is set the hook allows, so it forces at most
# one verdict round per stop. Fails open only when it cannot see the transcript
# — it never blocks blind.

input="$(cat)"

[ -f "$HOME/.claude/cos/ENFORCE" ] || exit 0
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

# Same fast-interpreter resolution as guard-destructive.sh.
GATE_PY=""
for cand in \
  "$LOCALAPPDATA/Python/pythoncore-3.14-64/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python313/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python312/python.exe"; do
  [ -x "$cand" ] && GATE_PY="$cand" && break
done
if [ -z "$GATE_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then GATE_PY=python3
  elif command -v python >/dev/null 2>&1; then GATE_PY=python
  else exit 0
  fi
fi

"$GATE_PY" - "$input" <<'PY'
import json, os, re, sys

try:
    data = json.loads(sys.argv[1])
except (ValueError, IndexError):
    sys.exit(0)

tp = data.get("transcript_path") or ""
sid = data.get("session_id") or ""
if not tp or not os.path.isfile(tp):
    sys.exit(0)  # cannot inspect -> never block blind

try:
    with open(tp, encoding="utf-8", errors="replace") as f:
        text = f.read()
except OSError:
    sys.exit(0)

# Build-work = any file-mutating tool call in the session transcript.
if not re.search(r'"name"\s*:\s*"(Edit|Write|NotebookEdit)"', text):
    sys.exit(0)  # trivial session — exempt

home = os.path.expanduser("~")
if sid and os.path.isfile(os.path.join(home, ".claude", "cos", "verdicts", sid)):
    sys.exit(0)  # verdict recorded — ship

msg = ("COS ENFORCEMENT (rule 15): this session did build-work but no Chief of "
       "Staff verdict is recorded. Dispatch the chief-of-staff agent to judge "
       "the deliverable; after its PASS, write the verdict card to "
       "~/.claude/cos/verdicts/<session_id> and finish. Trivial sessions are "
       "exempt automatically.")
print(msg, file=sys.stderr)
print(msg)
sys.exit(2)
PY
