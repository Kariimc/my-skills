#!/bin/bash
# cant-guard.sh — Stop guardrail.
# Blocks a reply that pleads helplessness ("I can't / I don't have access /
# there's no way to") when the transcript shows the agent never searched what
# it actually holds: the 400+ skill library (find-skills.py), connectors
# (ListConnectors), deferred tools (ToolSearch), or the probed env fact sheet.
# Machinery for rules/09-consult-skills: "can't" is only legal after the
# search comes up empty — then it must name the exact missing access.
#
# Exit 0 = allow. Exit 2 = block once (Claude searches or restates precisely,
# then finishes). Loop-guarded via stop_hook_active; fails open everywhere.
input="$(cat)"

case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

GUARD_PY=""
if command -v python3 >/dev/null 2>&1; then GUARD_PY=python3
elif command -v python >/dev/null 2>&1; then GUARD_PY=python
else exit 0
fi

"$GUARD_PY" - "$input" <<'PY'
import json, sys, re

# First-person helplessness only — "you can't" or prose about limits elsewhere
# must not trip this.
HELPLESS = [
    r"\bi can(?:'|no)t\b",
    r"\bi(?:'m| am) (?:unable|not able)\b",
    r"\bi don'?t have (?:access|the ability|the tools|a way)\b",
    r"\bthere(?:'s| is) no way (?:for me )?to\b",
    r"\b(?:that|this|it) (?:is|'s) not possible for me\b",
    r"\bi lack (?:access|the tools|the ability)\b",
]
# Evidence the agent actually looked before pleading empty-handed.
SEARCHED = [
    "find-skills.py", "ListConnectors", "ToolSearch", "SearchSkills",
    "env-facts.local.md", "env-scout",
]

def transcript_text(tp):
    try:
        with open(tp, encoding="utf-8", errors="replace") as f:
            return f.read()
    except Exception:
        return None

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

reply = last_assistant_text(tp).lower()
if not reply or not any(re.search(p, reply) for p in HELPLESS):
    sys.exit(0)

full = transcript_text(tp)
if full is None:
    sys.exit(0)
if any(m in full for m in SEARCHED):
    sys.exit(0)   # they looked first — a precise "can't" is legal

print("BLOCKED: this reply claims 'can't' but the session never searched what "
      "it actually holds. Before pleading helpless: (1) search the skill "
      "library — python3 skills/finding-skills/tool/find-skills.py \"<task>\" "
      "(or ~/.claude/skills) — 400+ skills exist and one likely covers this; "
      "(2) check connectors/tools — ListConnectors, ToolSearch; (3) read the "
      "probed fact sheet — .claude/env-facts.local.md. Then either USE what "
      "you find, or restate the refusal naming the exact missing access "
      "(which token, connector, or surface). A vague 'can't' is a rule "
      "violation (rules/09-consult-skills).", file=sys.stderr)
sys.exit(2)
PY
code=$?
[ "$code" -eq 2 ] && exit 2
exit 0
