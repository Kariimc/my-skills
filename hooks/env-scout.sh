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

  # ── Capability inventory (the cure for "acts like it has nothing") ────────
  SK_DIR=""; AG_DIR=""
  for d in "$HOME/.claude" "$ROOT"; do
    [ -z "$SK_DIR" ] && [ -d "$d/skills" ] && SK_DIR="$d/skills"
    [ -z "$AG_DIR" ] && [ -d "$d/agents" ] && AG_DIR="$d/agents"
  done
  NSK=0; NAG=0
  [ -n "$SK_DIR" ] && NSK=$(find "$SK_DIR" -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
  [ -n "$AG_DIR" ] && NAG=$(find "$AG_DIR" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
  echo
  NLIB=0
  [ -d "$ROOT/skills" ] && NLIB=$(find "$ROOT/skills" -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
  LIB_NOTE=""
  [ "$NLIB" -gt "$NSK" ] && LIB_NOTE=" — plus the FULL $NLIB-skill library in this repo's skills/ (auto-load is the core tier only; pull any other via /pull-skill or the finder)"
  echo "## YOU HAVE (verified just now — never claim otherwise without searching)"
  echo "- $NSK skills live at ${SK_DIR:-'(none found — name that gap, do not guess)'}$LIB_NOTE — search BEFORE building or refusing: python3 skills/finding-skills/tool/find-skills.py \"<task>\""
  echo "- $NAG agents at ${AG_DIR:-'(none found)'} — dispatchable via the Agent tool"
  echo "- Connectors & deferred tools may exist beyond what is listed in context: check ListConnectors / ToolSearch before saying a capability is missing"
  echo "- Source of all of it: the Kariimc/my-skills repo (public; raw.githubusercontent.com fetch works even when this box is not that repo)"
  echo "- READ IN FULL what a task names: a skill you invoke, a file you edit, a doc you cite — skimming a staged skill and shipping a partial run is the #1 quality failure (the 3D run-card exists because of it)"

  echo
  echo "_Full sheet also at .claude/env-facts.local.md. Durable NEW facts (a capability gained/lost) belong in PROGRESS.md the same session — see rules/07._"
} | tee "$OUT" 2>/dev/null

exit 0
