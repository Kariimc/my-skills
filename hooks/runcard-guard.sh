#!/bin/bash
# runcard-guard.sh — Stop guardrail.
# When a session did 3D work with the 3d-master-modeler skill, refuse to end
# until a run-card exists and has no unfilled rows — the skill is a staged
# pipeline, never a menu (docs/3D-MASTER-MODELER-EXECUTION-PLAN.md, item 2;
# promotes the PROGRESS.md proposed rule to machinery).
#
# Exit 0 = allow stop. Exit 2 = block once (Claude fills the card or states
# N/A reasons, then finishes). Blocks at most once per turn (stop_hook_active)
# and fails open on every uncertainty, so it can never lock a session.
input="$(cat)"

case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

PY=""
if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else exit 0
fi

# NOTE: python stderr must reach the hook's stderr — on exit 2 it carries the
# block message Claude acts on. Never redirect it away.
export RUNCARD_INPUT="$input"
"$PY" - <<'PY'
import json, os, glob, sys

try:
    data = json.loads(os.environ.get("RUNCARD_INPUT") or "{}")
except Exception:
    raise SystemExit(0)

tp = data.get("transcript_path") or ""
if not tp or not os.path.isfile(tp):
    raise SystemExit(0)

# Only police sessions that actually INVOKED the 3D skill — a structural
# Skill tool_use in the transcript, never a text match. A session that edits
# or discusses the skill contains its name everywhere (the guard's own
# authoring session false-blocked twice on that: first on the bare name, then
# on its own marker strings). Text written into files appears in the JSONL as
# ESCAPED string content, so parsing each line and walking for a real
# tool_use dict is immune to mentions. Fail open on any parse trouble.
def is_3d_invoke(node):
    if isinstance(node, dict):
        if (node.get("type") == "tool_use" and node.get("name") == "Skill"
                and isinstance(node.get("input"), dict)
                and node["input"].get("skill") == "3d-master-modeler"):
            return True
        return any(is_3d_invoke(v) for v in node.values())
    if isinstance(node, list):
        return any(is_3d_invoke(v) for v in node)
    return False

invoked = False
try:
    with open(tp, encoding="utf-8", errors="replace") as f:
        for line in f:
            if "3d-master-modeler" not in line:   # cheap pre-filter
                continue
            try:
                if is_3d_invoke(json.loads(line)):
                    invoked = True
                    break
            except Exception:
                continue
except Exception:
    raise SystemExit(0)
if not invoked:
    raise SystemExit(0)

cwd = data.get("cwd") or os.getcwd()

# The skill's own template copy doesn't count — the WORKING copy does.
cards = [p for p in glob.glob(os.path.join(cwd, "**", "runcard*.md"), recursive=True)
         if "3d-master-modeler" not in p.replace(os.sep, "/")]

def blank_rows(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return sum(1 for line in f if "☐" in line)  # ☐ = unfilled row
    except Exception:
        return 0

if not cards:
    print("BLOCKED: this session used 3d-master-modeler but no run-card copy exists "
          "in the working directory. The skill is a staged pipeline, never a menu: "
          "copy skills/3d-master-modeler/runcard.md next to the asset, fill every "
          "row with its proof artifact (or an explicit 'N/A — reason'), then finish. "
          "A missing or blank card means the run is NOT done.", file=sys.stderr)
    raise SystemExit(2)

worst = max(cards, key=blank_rows)
n = blank_rows(worst)
if n:
    print(f"BLOCKED: run-card {os.path.relpath(worst, cwd)} still has {n} unfilled "
          "row(s) (☐). Every phase leaves a named proof artifact or an explicit "
          "'N/A — reason' — fill the remaining rows from work actually done (never "
          "retro-invent proofs; if a phase was skipped, do it or mark N/A with the "
          "real reason), then finish.", file=sys.stderr)
    raise SystemExit(2)
raise SystemExit(0)
PY
code=$?
[ "$code" -eq 2 ] && exit 2
exit 0
