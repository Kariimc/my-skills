#!/bin/bash
# guard-junk-files.sh — PreToolUse guardrail
# Blocks creation of clutter files (_backup, _v2, _old, copy-of, .bak, ...)
# that force manual cleanup later. Same cheap-pre-filter style as
# guard-destructive.sh: pure-bash checks first, one python spawn only when
# the payload could actually match.
#
# Exit 0 = allow. Exit 2 = block (Claude sees the message and adjusts).

input="$(cat)"

# Pre-filter 1: only Write tool calls are guarded.
case "$input" in
  *'"tool_name":"Write"'*|*'"tool_name": "Write"'*) ;;
  *) exit 0 ;;
esac

# Pre-filter 2: none of the junk markers present -> allow instantly.
case "$input" in
  *_backup*|*_old*|*_copy*|*copy?of*|*_v2*|*_v3*|*_final*|*_new.*|*_fixed*|*_updated*|*_temp*|*.bak*|*.orig*|*.tmp*|*untitled*|*new?file*) ;;
  *) exit 0 ;;
esac

# Resolve the fastest available python once (same ladder as guard-destructive).
GUARD_PY=""
for cand in \
  "$LOCALAPPDATA/Python/pythoncore-3.14-64/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python313/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python312/python.exe"; do
  [ -x "$cand" ] && GUARD_PY="$cand" && break
done
if [ -z "$GUARD_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then GUARD_PY=python3
  elif command -v python >/dev/null 2>&1; then GUARD_PY=python
  else exit 0  # fail open: no interpreter, cannot inspect safely
  fi
fi

"$GUARD_PY" - "$input" <<'PY'
import json, re, sys

try:
    data = json.loads(sys.argv[1].lstrip(chr(0xfeff)))
except (ValueError, IndexError):
    sys.exit(0)

if data.get("tool_name") != "Write":
    sys.exit(0)

path = data.get("tool_input", {}).get("file_path", "") or ""
name = path.replace("\\", "/").split("/")[-1].lower()

JUNK = [
    r"\.bak$", r"\.old$", r"\.orig$", r"\.tmp$",
    r"_backup\.", r"_old\.", r"_copy\.", r"copy[ _-]of[ _-]",
    r"_v\d+\.", r"[ -]v\d+\.", r"_final\.", r"_final_",
    r"_new\.", r"_fixed\.", r"_updated\.", r"_temp\.",
    r"^untitled", r"^new[ _-]?file", r"\(\d+\)\.",
]

for pat in JUNK:
    if re.search(pat, name):
        msg = (f"GUARDRAIL BLOCKED: '{name}' is a junk/clutter filename. Edit the "
               f"original file in place (versioning is git's job) or use a proper "
               f"canonical name. Never create files the user must clean up later.")
        print(msg, file=sys.stderr)
        print(msg)
        sys.exit(2)

sys.exit(0)
PY
