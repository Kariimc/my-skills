#!/bin/bash
set -uo pipefail

# ═════════════════════════════════════════════════════════════════════════════
# apex-ratchet — turn a mistake into a permanent gate, so it never recurs.
#
# This is the "never again" mechanism: a mistake happens at most once, then it
# becomes a self-contained check under apex/checks/ that runs on every commit,
# push, and CI build forever after.
#
# Usage:
#   apex-ratchet.sh "<one-line description of the mistake>"
#
# It (1) logs the mistake to apex/MISTAKE-LEDGER.md, and (2) scaffolds a runnable
# check at apex/checks/<slug>.sh for you to fill in with the actual assertion.
# ═════════════════════════════════════════════════════════════════════════════

ROOT="${APEX_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$ROOT" ] && [ -d "$ROOT/skills" ] || { echo "apex-ratchet: run inside the skills repo."; exit 1; }
cd "$ROOT"

DESC="${*:-}"
[ -n "$DESC" ] || { echo "usage: apex-ratchet.sh \"<what went wrong>\""; exit 2; }

# Slug from the description (lowercase, dashes, trimmed).
SLUG="$(printf '%s' "$DESC" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//' | cut -c1-48)"
[ -n "$SLUG" ] || SLUG="mistake"
CHECK="apex/checks/${SLUG}.sh"
mkdir -p apex/checks

LEDGER="apex/MISTAKE-LEDGER.md"
[ -f "$LEDGER" ] || printf '# Mistake ledger\n\nEvery entry is a mistake that is now permanently gated. Append-only.\n\n| # | Mistake | Gate |\n|---|---|---|\n' > "$LEDGER"
N=$(( $(grep -cE '^\| [0-9]+ \|' "$LEDGER" 2>/dev/null || echo 0) + 1 ))
printf '| %s | %s | `%s` |\n' "$N" "$DESC" "$CHECK" >> "$LEDGER"

if [ -f "$CHECK" ]; then
  echo "apex-ratchet: $CHECK already exists — ledger updated, check left intact."
  exit 0
fi

cat > "$CHECK" <<EOF
#!/bin/bash
set -uo pipefail
# Ratchet gate #$N — prevents recurrence of:
#   $DESC
#
# Runs from repo root via apex-gates.sh. Exit 0 = pass, non-zero = HARD failure.
# TODO: replace the placeholder below with the real assertion that would have
# caught this mistake (grep for the bad pattern, validate a file, run a command).

cd "\$(git rev-parse --show-toplevel)"

# Example pattern (delete and replace):
# if grep -rIlE 'BAD_PATTERN' skills/ >/dev/null 2>&1; then
#   echo "ratchet[$SLUG]: found the thing that should never happen"; exit 1
# fi

exit 0
EOF
chmod +x "$CHECK"

echo "apex-ratchet: gated mistake #$N"
echo "  ledger: $LEDGER"
echo "  check : $CHECK  (fill in the assertion, then commit)"
