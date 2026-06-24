#!/bin/bash
set -uo pipefail

# ═════════════════════════════════════════════════════════════════════════════
# apex — install, arm, and verify the entire control-plane guardrail layer.
#
# The one-prompt engine behind the `apex` skill. Idempotent: run it once and the
# layer maintains itself thereafter (hooks + CI + ratchet). Re-run any time to
# re-arm and get a status dashboard.
# ═════════════════════════════════════════════════════════════════════════════

ROOT="${APEX_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$ROOT" ] && [ -d "$ROOT/skills" ] || { echo "apex: run inside the skills repo."; exit 1; }
cd "$ROOT"

echo "═══════════════════════════════════════════════"
echo " APEX — control-plane fortification"
echo "═══════════════════════════════════════════════"

# 1. Make every guard executable.
chmod +x bin/*.sh .githooks/* hooks/*.sh apex/checks/*.sh 2>/dev/null || true

# 2. Arm local hooks (pre-commit + pre-push).
git config core.hooksPath .githooks
echo "✓ hooks armed         core.hooksPath = $(git config --get core.hooksPath)"

# 3. Confirm the CI mirror exists.
if [ -f .github/workflows/apex.yml ]; then
  echo "✓ CI mirror present   .github/workflows/apex.yml"
else
  echo "✗ CI mirror MISSING   .github/workflows/apex.yml — restore it"
fi

# 4. Heal any safe drift now.
[ -x bin/skill-doctor.sh ] && bin/skill-doctor.sh --fix >/dev/null 2>&1 && echo "✓ drift healed        counts + triage reconciled"

# 5. Run the full gate suite and report.
echo "───────────────────────────────────────────────"
if bin/apex-gates.sh all; then
  echo "───────────────────────────────────────────────"
  echo "APEX STATUS: ✓ fortified — all gates green, self-maintaining."
  exit 0
else
  echo "───────────────────────────────────────────────"
  echo "APEX STATUS: ✗ attention needed — fix the HARD failures above."
  exit 1
fi
