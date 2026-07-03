#!/bin/bash
# apply-hook-tuning.sh — one-shot latency fix for global hook wiring.
#
# WHY: the 2026-07 audit measured hook cost on this machine:
#   - continuous-learning-v2 observe.sh: ~19s per run, wired PreToolUse AND
#     PostToolUse with matcher "*"  → up to ~38s added to EVERY tool call.
#   - guard-destructive.sh: ran on every tool (no matcher) → ~3s per call;
#     it only guards Bash, so scoping it to Bash makes other tools free.
#
# WHAT IT DOES (to ~/.claude/settings.json, after backing it up):
#   1. Adds "matcher": "Bash" to the guard-destructive PreToolUse entry.
#   2. Removes the continuous-learning-v2 observe.sh Pre/PostToolUse entries.
#      (The skill itself stays installed; re-add the entries to re-enable.)
#
# Claude Code's permission model treats settings.json as user-owned, so this
# script is run BY YOU, not by the agent:   bash bin/apply-hook-tuning.sh

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
BACKUP="$HOME/.claude/backups/settings-$(date +%Y%m%d-%H%M%S).json"

PY=""
for cand in \
  "$LOCALAPPDATA/Python/pythoncore-3.14-64/python.exe" \
  "$(command -v python3 || true)" \
  "$(command -v python || true)"; do
  [ -n "$cand" ] && [ -x "$cand" ] && PY="$cand" && break
done
[ -z "$PY" ] && { echo "no python found"; exit 1; }

mkdir -p "$HOME/.claude/backups"
cp "$SETTINGS" "$BACKUP"
echo "backup: $BACKUP"

SETTINGS_FILE="$SETTINGS" "$PY" - <<'PY'
import json, os

path = os.environ["SETTINGS_FILE"]
with open(path) as f:
    s = json.load(f)
h = s.get("hooks", {})

# 1. Scope guard-destructive to Bash tool calls only.
for grp in h.get("PreToolUse", []):
    if any("guard-destructive" in hk.get("command", "")
           for hk in grp.get("hooks", [])):
        grp["matcher"] = "Bash"

# 2. Drop the observe.sh entries (per-tool-call latency tax).
removed = 0
for evt in ("PreToolUse", "PostToolUse"):
    before = len(h.get(evt, []))
    h[evt] = [g for g in h.get(evt, [])
              if not any("continuous-learning-v2" in hk.get("command", "")
                         for hk in g.get("hooks", []))]
    removed += before - len(h[evt])
    if not h[evt]:
        del h[evt]

tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(s, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print(f"guard scoped to Bash; observer entries removed: {removed}")
print("Restart the Claude Code session for hook changes to take effect.")
PY
