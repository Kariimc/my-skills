#!/bin/bash
# env-scout.sh — SessionStart boot probe (docs/HARNESS-AGENT-ROADMAP.md #2).
# Fingerprints the box in a few seconds so no agent starts on a wrong belief
# about the environment (ledger F-43/F-45 class: absence asserted without
# coverage; "network blocks it" from one host's 403).
#
# Output contract: prints a compact fact sheet to stdout (SessionStart stdout
# lands in the model's context) and writes the same sheet to
# .claude/env-facts.local.md (untracked) for later reads. Fail-open: any
# individual probe failure is recorded as a fact, never an error; the script
# always exits 0 so it can never block a session.
#
# PROOF over guesswork: every line is the result of a command run just now —
# imports attempted, hosts actually curled — never a cached or assumed value.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="$ROOT/.claude/env-facts.local.md"
mkdir -p "$ROOT/.claude" 2>/dev/null

{
  echo "# Environment facts (probed at session start — trust these over memory)"
  echo

  # ── Interpreters & modules (attempt the import; never guess) ──────────────
  PY="$(command -v python3 || command -v python)"
  if [ -n "$PY" ]; then
    echo "- python: $("$PY" -V 2>&1)"
    MODS=""
    for m in bpy PIL numpy requests; do
      if "$PY" -c "import $m" >/dev/null 2>&1; then MODS="$MODS $m✓"; else MODS="$MODS $m✗"; fi
    done
    echo "- python modules:$MODS"
  else
    echo "- python: NOT FOUND"
  fi
  command -v node >/dev/null 2>&1 && echo "- node: $(node -v 2>/dev/null)" || echo "- node: not found"
  command -v blender >/dev/null 2>&1 && echo "- blender CLI: yes" || echo "- blender CLI: no (bpy module status above is what matters headless)"

  # ── Egress (probe a SPREAD of hosts; one 403 is never 'no downloads') ─────
  if command -v curl >/dev/null 2>&1; then
    NET=""
    for h in github.com raw.githubusercontent.com pypi.org example.com; do
      code=$(curl -s -o /dev/null --max-time 3 -w "%{http_code}" "https://$h" 2>/dev/null)
      NET="$NET $h:$code"
    done
    echo "- egress probe:$NET  (000=blocked/timeout; GitHub+PyPI open with others blocked ⇒ allowlist box, pull assets via GitHub mirrors — PLAYBOOK P-16)"
  fi

  # ── Disk & git ────────────────────────────────────────────────────────────
  echo "- disk free (this fs): $(df -h . 2>/dev/null | awk 'NR==2{print $4}')  (0 with low Used on a cloud box = session allowance spent, not a broken machine)"
  BR="$(git -C "$ROOT" branch --show-current 2>/dev/null)"
  [ -n "$BR" ] && echo "- git: branch $BR, $(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ') dirty files"

  # ── Surface capabilities (cross-session facts Kariim shouldn't repeat) ────
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d /opt/pw-browsers ] 2>/dev/null; then
    echo "- surface: CLOUD box (wiped between sessions; deps reinstall via SessionStart hooks; screen-eyes bridge is vision-IN only — no channel to run/install on the laptop from here)"
  fi
  [ -x /opt/pw-browsers/chromium ] 2>/dev/null && echo "- browser: Chromium at /opt/pw-browsers/chromium (do NOT playwright install)"

  echo
  echo "_Full sheet also at .claude/env-facts.local.md. Durable NEW facts (a capability gained/lost) belong in PROGRESS.md the same session — see rules/07._"
} | tee "$OUT" 2>/dev/null

exit 0
