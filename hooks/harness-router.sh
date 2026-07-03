#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Harness router (UserPromptSubmit hook)
#
# Reads the user's prompt and, when it clearly matches one of the six "ultimate
# harnesses", injects a short routing hint into context so the right harness
# skill fires WITHOUT the user naming it. Conservative by design: emits at most
# one hint, and only on a confident keyword match. On anything ambiguous it
# stays silent and lets normal skill auto-invocation do its job.
#
# Output contract: for UserPromptSubmit, stdout (exit 0) is added to the model's
# context. We print one short hint block, or nothing.
# ─────────────────────────────────────────────────────────────────────────────

# Resolve the fastest available python; no interpreter → no-op (never block
# the prompt). Prefer a real install over the WindowsApps Store shim, which
# adds ~1s per spawn on this machine.
ROUTER_PY=""
for cand in \
  "${LOCALAPPDATA:-}/Python/pythoncore-3.14-64/python.exe" \
  "${LOCALAPPDATA:-}/Programs/Python/Python313/python.exe" \
  "${LOCALAPPDATA:-}/Programs/Python/Python312/python.exe"; do
  [ -x "$cand" ] && ROUTER_PY="$cand" && break
done
if [ -z "$ROUTER_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then ROUTER_PY=python3
  elif command -v python >/dev/null 2>&1; then ROUTER_PY=python
  else exit 0
  fi
fi

# Read the hook payload from stdin into an env var. We can't let the heredoc
# below consume stdin (Python would then read the script, not the payload).
HARNESS_HOOK_INPUT="$(cat)"
export HARNESS_HOOK_INPUT

"$ROUTER_PY" - <<'PY'
import os, json, re, sys

# Force UTF-8 stdout so the arrows in the hint blurbs never crash on Windows
# consoles that default to cp1252 (UnicodeEncodeError would otherwise block the
# prompt). errors="replace" degrades gracefully on any other unencodable char.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

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

# 2. Audit — assess a surface for problems (find, don't fix).
elif has(r"\baudit\b", r"\bwhat'?s (broken|wrong|redundant|missing)\b",
         r"\bsecurity review\b", r"\bvulnerab",
         r"\bproduction[- ]ready", r"\binventory\b", r"\bassess\b",
         r"\bcheck .* for (bugs|issues|problems|security)\b"):
    hint = ("harness-audit", "Audit Harness",
            "inventory the live surface → rank by severity → verify (read-only; fixes are a separate step)")

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

# 5. Refactor/Simplify — structure-only change, behavior preserved.
elif has(r"\brefactor", r"\bsimplif", r"\bdedup", r"\bconsolidat",
         r"\bdead code\b", r"\bduplicate (code|functions?|logic)\b",
         r"\breduce .*(complexity|duplication)\b", r"\btidy up\b",
         r"\bclean up (the |this |my )?(code|function|module|import)"):
    hint = ("harness-refactor", "Refactor/Simplify Harness",
            "baseline behavior → find dupes/dead code → small reversible steps → verify unchanged")

# 6. Build — the catch-all for substantive code work.
elif has(r"\bbuild (me |a |an |the )", r"\bimplement\b", r"\bship (a|an|the)\b",
         r"\bcreate (a|an) (app|game|api|tool|service|site|website|feature)\b",
         r"\badd .* (feature|endpoint|page|screen|command)\b",
         r"\bwrite (a|an) (app|game|api|service|tool|cli)\b"):
    hint = ("harness-build", "Build Harness",
            "plan → parallel build → review → verify → ship")

if hint:
    name, title, blurb = hint
    print(
        f"[harness-router] This may match the **{title}** — `{name}` "
        f"({blurb}). Hint, not a mandate: use it only if the task genuinely "
        f"exceeds a single focused loop; otherwise do the work directly."
    )
PY
exit 0
