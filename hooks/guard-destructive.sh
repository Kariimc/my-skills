#!/bin/bash
# guard-destructive.sh — PreToolUse guardrail
# Blocks catastrophic bash commands before they run. Registered globally by
# session-start.sh so it fires in every project, not just this one.
#
# Exit 0 = allow. Exit 2 = block (Claude sees the message and adjusts).
#
# Performance: hooks run on the tool-call hot path, so this script must stay
# cheap. It pre-filters with pure-bash string checks and only spawns a python
# interpreter (a single one) when the payload could actually match a guarded
# pattern. Windows process spawns cost ~0.5-1.2s each, so every avoided spawn
# is real latency saved on every single tool call.

input="$(cat)"

# Cheap pre-filter 1: only Bash tool calls are guarded. The JSON field check is
# a substring test — no interpreter needed for the overwhelmingly common case.
case "$input" in
  *'"tool_name":"Bash"'*|*'"tool_name": "Bash"'*) ;;
  *) exit 0 ;;
esac

# Cheap pre-filter 2: none of the guarded keywords present -> allow instantly.
case "$input" in
  *rm\ *|*'git push'*|*'git reset'*|*DROP\ *|*drop\ *|*TRUNCATE*|*truncate*) ;;
  *) exit 0 ;;
esac

# Resolve the fastest available python once. The Windows Store alias shim
# (WindowsApps\python3) adds ~1s per spawn and can be a non-functional App
# Installer stub; prefer a real interpreter when one exists.
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

# Single interpreter pass: parse, match, decide. Input goes via argv because
# the heredoc already occupies stdin.
"$GUARD_PY" - "$input" <<'PY'
import json, sys, re

try:
    data = json.loads(sys.argv[1])
except (ValueError, IndexError):
    sys.exit(0)

if data.get("tool_name") != "Bash":
    sys.exit(0)

cmd = data.get("tool_input", {}).get("command", "")

HARD = [
    # rm -rf of filesystem root or home
    (r'rm\s+.*-[a-zA-Z]*r[a-zA-Z]*.*\s+(/|~|\$(?:HOME|\{HOME\}))\s*$',
     "rm -rf of / or ~ is irreversible — not allowed."),
    # force push (--force or -f but NOT --force-with-lease which is safer)
    (r'git\s+push\b(?!.*--force-with-lease).*\s(--force|-f)(\s|$)',
     "Force push blocked. Use --force-with-lease, or ask the user before forcing."),
]

WARN = [
    (r'git\s+reset\s+--hard',
     "git reset --hard discards all uncommitted changes. Confirm this is intentional."),
    (r'\b(DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE\s+TABLE)\b',
     "Destructive SQL detected — confirm data loss is intentional and a backup exists."),
]

for pattern, msg in HARD:
    if re.search(pattern, cmd, re.IGNORECASE | re.MULTILINE):
        print(f"GUARDRAIL BLOCKED: {msg}", file=sys.stderr)
        print(f"GUARDRAIL BLOCKED: {msg}")
        sys.exit(2)

for pattern, msg in WARN:
    if re.search(pattern, cmd, re.IGNORECASE | re.MULTILINE):
        print(f"GUARDRAIL WARNING: {msg}")

sys.exit(0)
PY
