#!/bin/bash
# guard-destructive.sh — PreToolUse guardrail
# Blocks catastrophic bash commands before they run. Registered globally by
# session-start.sh so it fires in every project, not just this one.
#
# Exit 0 = allow. Exit 2 = block (Claude sees the message and adjusts).

input="$(cat)"

# Only guard Bash tool calls.
tool="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null)"
[ "$tool" = "Bash" ] || exit 0

python3 - "$input" <<'PY'
import json, sys, re

cmd = json.loads(sys.argv[1]).get("tool_input", {}).get("command", "")

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
