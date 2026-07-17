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

# Cheap pre-filter 1: route by tool. Bash -> destructive-command checks.
# Anything else -> only worth inspecting if the payload names a generated path.
GUARD_MODE=""
case "$input" in
  *'"tool_name":"Bash"'*|*'"tool_name": "Bash"'*) GUARD_MODE=bash ;;
  *CLAUDE.md*|*.claude*) GUARD_MODE=write ;;
  *) exit 0 ;;
esac

# Cheap pre-filter 2 (bash only): no guarded keywords -> allow instantly.
if [ "$GUARD_MODE" = bash ]; then
  case "$input" in
    *rm\ *|*'git push'*|*'git reset'*|*'git clean'*|*'git checkout'*|*'git restore'*|*DROP\ *|*drop\ *|*TRUNCATE*|*truncate*|*Set-Content*|*Out-File*|*'bash -c'*|*'bash.exe -c'*|*'python -c'*|*'python3 -c'*|*'node -e'*) ;;
    *) exit 0 ;;
  esac
fi

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

tool = data.get("tool_name", "")
ti = data.get("tool_input", {}) or {}

# ── Generated-path guard (any write-ish tool, incl. MCP file writers) ────────
# ~/.claude is BUILD OUTPUT. session-start.sh regenerates CLAUDE.md from
# my-skills/rules/*.md, copies FAILURES.md from the repo, and mirrors
# skills/commands/agents/hooks over it on EVERY session start. A direct write
# there is silently erased at next launch, and worse, it reads back fine right
# after — so it gets reported as "done". (Ledger F-40, F-41, F-46.)
if tool != "Bash":
    path = ti.get("file_path") or ti.get("path") or ti.get("notebook_path") or ""
    norm = str(path).replace("\\", "/")
    GENERATED = [
        (r'/\.claude/CLAUDE\.md$',
         "~/.claude/CLAUDE.md is GENERATED from my-skills/rules/*.md on every "
         "session start. Your edit would be erased at next launch. "
         "Edit the source: my-skills/rules/<nn>-<name>.md"),
        (r'/\.claude/FAILURES\.md$',
         "~/.claude/FAILURES.md is GENERATED from my-skills/FAILURES.md on every "
         "session start. Your edit would be erased at next launch, and it is not "
         "versioned there. Edit the source: my-skills/FAILURES.md"),
        (r'/\.claude/skills/',
         "~/.claude/skills/ is a MIRROR of my-skills/skills/. Files here are "
         "deleted if absent from the repo. Edit my-skills/skills/<name>/ instead."),
        (r'/\.claude/commands/',
         "~/.claude/commands/ is synced from my-skills/commands/. "
         "Edit my-skills/commands/<name>.md instead."),
        (r'/\.claude/agents/',
         "~/.claude/agents/ is synced from my-skills/agents/. "
         "Edit my-skills/agents/<name>.md instead."),
        (r'/\.claude/hooks/',
         "~/.claude/hooks/ is synced from my-skills/hooks/. "
         "Edit my-skills/hooks/<name>.sh instead."),
    ]
    for pattern, msg in GENERATED:
        if re.search(pattern, norm, re.IGNORECASE):
            print(f"GUARDRAIL BLOCKED: {msg}", file=sys.stderr)
            print(f"GUARDRAIL BLOCKED: {msg}")
            sys.exit(2)
    sys.exit(0)

cmd = ti.get("command", "")

HARD = [
    # rm -rf of filesystem root or home
    (r'rm\s+.*-[a-zA-Z]*r[a-zA-Z]*.*\s+(/|~|\$(?:HOME|\{HOME\}))\s*$',
     "rm -rf of / or ~ is irreversible — not allowed."),
    # force push (--force or -f but NOT --force-with-lease which is safer)
    (r'git\s+push\b(?!.*--force-with-lease).*\s(--force|-f)(\s|$)',
     "Force push blocked. Use --force-with-lease, or ask the user before forcing."),
    # commands that throw away uncommitted work irreversibly. The leading
    # (?:^|[;&|]) anchor requires the git command to sit at a real statement
    # boundary (start, or after ; & | && ||), so the same words quoted inside a
    # commit message or echo do NOT trip the guard.
    (r'(?:^|[;&|])\s*git\s+reset\s+--hard',
     "git reset --hard discards all uncommitted changes - blocked. Commit or stash first, or run it yourself if you truly mean to."),
    (r'(?:^|[;&|])\s*git\s+clean\s+-[a-zA-Z]*f',
     "git clean -f deletes untracked files irreversibly - blocked. Preview with 'git clean -n' first."),
    (r'(?:^|[;&|])\s*git\s+checkout\s+(--\s+)?\.(\s|$)',
     "git checkout . discards all uncommitted changes - blocked. Stash first if you might want them back."),
    (r'(?:^|[;&|])\s*git\s+restore\s+(--\s+)?\.(\s|$)',
     "git restore . discards all uncommitted changes - blocked. Stash first if you might want them back."),

    # ── F-05 / F-30: PowerShell 5.1 writes a UTF-8 BOM ──────────────────────
    # Set-Content / Out-File prepend an invisible BOM that breaks any strict
    # parser. This is what corrupts claude_desktop_config.json ("Unexpected
    # token '<BOM>'"). Structured files must be written BOM-free.
    (r'(?:Set-Content|Out-File)\b(?=[^|;&]*\.(?:json|ya?ml|toml|xml|md|sh|py|js|ts|jsx|tsx|env)\b)',
     "Set-Content / Out-File write a UTF-8 BOM under PowerShell 5.1 and corrupt "
     "structured files (ledger F-05, F-30). Use: "
     "[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))"),

    # ── F-35 / F-49: multi-statement scripts through layered shells ─────────
    # Proven dead 4x. Quoting gets mangled crossing PowerShell -> bash/python;
    # commands silently no-op or half-run. A single statement is fine; two or
    # more separated by ; or && is the failure mode. Write the script to a file
    # and execute the FILE as two plain tokens.
    (r'''(?:bash(?:\.exe)?|python3?|node)\s+-(?:c|e)\s+(?P<q>['"]).*?[;&]{1,2}.*?(?P=q)''',
     "Multi-statement script passed as a quoted argument through a layered shell "
     "- proven dead 4x (ledger F-35, F-49). Quoting gets mangled and the command "
     "silently half-runs. Write the script to a file, then run it as two plain "
     "tokens: bash /c/path/to/script.sh"),
]

WARN = [
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
