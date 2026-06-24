#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Harness router (UserPromptSubmit hook)
#
# Reads the user's prompt and, when it clearly matches one of the five "ultimate
# harnesses", injects a short routing hint into context so the right harness
# skill fires WITHOUT the user naming it. Conservative by design: emits at most
# one hint, and only on a confident keyword match. On anything ambiguous it
# stays silent and lets normal skill auto-invocation do its job.
#
# Output contract: for UserPromptSubmit, stdout (exit 0) is added to the model's
# context. We print one short hint block, or nothing.
# ─────────────────────────────────────────────────────────────────────────────

# No python3 → no-op (never block the prompt).
command -v python3 >/dev/null 2>&1 || { exit 0; }

# Read the hook payload from stdin into an env var. We can't let the heredoc
# below consume stdin (Python would then read the script, not the payload).
HARNESS_HOOK_INPUT="$(cat)"
export HARNESS_HOOK_INPUT

python3 - <<'PY'
import os, json, re

try:
    data = json.loads(os.environ.get("HARNESS_HOOK_INPUT") or "{}")
except Exception:
    raise SystemExit(0)

prompt = (data.get("prompt") or "").lower()
if not prompt.strip():
    raise SystemExit(0)

def has(*pats):
    return any(re.search(p, prompt) for p in pats)

# Ordered most-specific → least. First match wins (one hint max).
hint = None

# 1. Autonomous-Ops — schedules, loops, monitoring, continuous work.
if has(r"\bevery \d+\s*(s|sec|second|m|min|minute|h|hour|day)",
       r"\bon a schedule\b", r"\bschedul(e|ed|ing)\b", r"\bcron\b",
       r"\bcontinuous(ly)?\b", r"\bkeep (working|running|going)\b",
       r"\bautonomous(ly)?\b", r"\b(monitor|watch|babysit)\b",
       r"\bin a loop\b", r"\brecurring\b"):
    hint = ("harness-autonomous", "Autonomous-Ops Harness",
            "loop + memory + schedule + recovery — persistent work across sessions")

# 2. Audit — assess a surface for problems.
elif has(r"\baudit\b", r"\bwhat'?s (broken|wrong|redundant|missing)\b",
         r"\bsecurity review\b", r"\bvulnerab", r"\bdead code\b",
         r"\bproduction[- ]ready", r"\binventory\b", r"\bassess\b",
         r"\bcheck .* for (bugs|issues|problems|security)\b"):
    hint = ("harness-audit", "Audit Harness",
            "inventory the live surface → rank by severity → verify → code-first fixes")

# 3. Research — investigate / compare / fact-find.
elif has(r"\bresearch\b", r"\binvestigat", r"\bcompare\b", r"\bcompetitor",
         r"\bcompetitive\b", r"\bmarket (analysis|research)\b",
         r"\bwhat'?s the best\b", r"\bfind out\b", r"\bdue diligence\b",
         r"\bfact[- ]check"):
    hint = ("harness-research", "Research/Verify Harness",
            "fan out searches → fetch sources → adversarially verify → cite")

# 4. Quality (GAN) — production-grade / polished / no slop.
elif has(r"\bproduction[- ]quality\b", r"\bpolished?\b", r"\bhigh[- ]craft\b",
         r"\bbeautiful\b", r"\bno slop\b", r"\bstunning\b", r"\btop[- ]quality\b",
         r"\bmake it (look )?(great|gorgeous|premium)\b"):
    hint = ("harness-quality", "Quality (GAN) Harness",
            "generate ↔ adversarial evaluator ↔ iterate until it clears a strict rubric")

# 5. Build — the catch-all for substantive code work.
elif has(r"\bbuild (me |a |an |the )", r"\bimplement\b", r"\bship (a|an|the)\b",
         r"\bcreate (a|an) (app|game|api|tool|service|site|website|feature)\b",
         r"\badd .* (feature|endpoint|page|screen|command)\b",
         r"\bwrite (a|an) (app|game|api|service|tool|cli)\b"):
    hint = ("harness-build", "Build Harness",
            "plan → parallel build → review → verify → ship")

if hint:
    name, title, blurb = hint
    print(
        f"[harness-router] This request matches the **{title}**. "
        f"Prefer the `{name}` skill ({blurb}) unless the task is trivial "
        f"enough to do directly. The five ultimate harnesses are: harness-build, "
        f"harness-quality, harness-research, harness-audit, harness-autonomous."
    )
PY
exit 0
