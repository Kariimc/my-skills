#!/bin/bash
set -uo pipefail

# ═════════════════════════════════════════════════════════════════════════════
# apex-gates — the single source of truth for every control-plane gate.
#
# One library, called by all enforcement points (pre-commit, pre-push, CI) so a
# gate is defined exactly once and runs everywhere identically.
#
# Usage:
#   apex-gates.sh <gate|all> [--staged]
#   gates: doctor  hooklint  secrets  selfintegrity  live
#
# Exit 0 = pass. Exit 1 = HARD failure (blocks the action). SOFT issues warn.
# --staged scopes file scans to git-staged files (used by pre-commit).
# ═════════════════════════════════════════════════════════════════════════════

STAGED=0
GATE="${1:-all}"
[ "${2:-}" = "--staged" ] && STAGED=1
[ "${1:-}" = "--staged" ] && { STAGED=1; GATE="all"; }

# ── repo root: dir containing skills/ and rules/ ─────────────────────────────
ROOT="${APEX_ROOT:-}"
if [ -z "$ROOT" ]; then
  d="$PWD"
  while [ "$d" != "/" ]; do
    [ -d "$d/skills" ] && [ -d "$d/rules" ] && { ROOT="$d"; break; }
    d="$(dirname "$d")"
  done
fi
[ -n "$ROOT" ] && [ -d "$ROOT/skills" ] || { echo "apex-gates: not in a skills repo"; exit 0; }
cd "$ROOT"

HARD=0
note_hard() { echo "  HARD  $1"; HARD=$((HARD+1)); }
note_soft() { echo "  soft  $1"; }

# Which files to scan for content gates.
scan_files() {
  if [ "$STAGED" = "1" ]; then
    git diff --cached --name-only --diff-filter=ACM 2>/dev/null
  else
    git ls-files 2>/dev/null
  fi
}

# ── GATE: doctor (skill/metadata integrity) ──────────────────────────────────
gate_doctor() {
  echo "› doctor"
  if [ -x bin/skill-doctor.sh ]; then
    bin/skill-doctor.sh >/tmp/apex-doctor.out 2>&1 || { sed 's/^/    /' /tmp/apex-doctor.out; note_hard "skill-doctor reported blocking issues"; return; }
    grep -E 'skill-doctor:' /tmp/apex-doctor.out | sed 's/^/    /'
  else
    note_hard "bin/skill-doctor.sh missing"
  fi
}

# ── GATE: hooklint (no broken/ input-eating hooks) ───────────────────────────
gate_hooklint() {
  echo "› hooklint"
  local f
  for f in hooks/*.sh .githooks/* bin/*.sh; do
    [ -f "$f" ] || continue
    case "$f" in *.md) continue;; esac
    bash -n "$f" 2>/tmp/apex-syn.out || { sed 's/^/    /' /tmp/apex-syn.out; note_hard "syntax error in $f"; }
  done
  # Live stdin test for the prompt router (the heredoc-ate-stdin bug class).
  if [ -x hooks/harness-router.sh ]; then
    local out
    out="$(printf '%s' '{"prompt":"build me an app"}' | hooks/harness-router.sh 2>/dev/null)" || { note_hard "harness-router.sh crashed on sample input"; return; }
    echo "$out" | grep -q 'harness-build' || note_hard "harness-router.sh did not route a sample 'build' prompt (stdin not consumed?)"
  fi
}

# ── GATE: secrets (no credentials committed) ─────────────────────────────────
gate_secrets() {
  echo "› secrets"
  local pat='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[0-9A-Za-z-]{10,}|gh[pousr]_[0-9A-Za-z]{36,}|sk-[A-Za-z0-9]{32,}'
  local hits=0 file
  while IFS= read -r file; do
    [ -f "$file" ] || continue
    case "$file" in *.png|*.jpg|*.jpeg|*.gif|*.pdf|*.ico|*.webp) continue;; esac
    if grep -nIEq "$pat" "$file" 2>/dev/null; then
      echo "    leak in $file:"; grep -nIE "$pat" "$file" 2>/dev/null | sed 's/^/      /' | cut -c1-120; hits=$((hits+1))
    fi
  done < <(scan_files)
  [ "$hits" -gt 0 ] && note_hard "$hits file(s) contain credential-shaped strings"
}

# ── GATE: selfintegrity (the guard that guards the guards) ────────────────────
gate_selfintegrity() {
  echo "› selfintegrity"
  local req
  for req in bin/skill-doctor.sh bin/apex-gates.sh .githooks/pre-commit .githooks/pre-push .github/workflows/apex.yml apex/GATES.md; do
    [ -f "$req" ] || note_hard "missing protected file: $req"
  done
  # The doctor must still enforce its HARD gate (not gutted to always-pass).
  [ -f bin/skill-doctor.sh ] && ! grep -q 'HARD' bin/skill-doctor.sh && note_hard "skill-doctor.sh has no HARD checks (tampered?)"
  # Hooks must be wired (soft: not knowable in CI).
  local hp; hp="$(git config --get core.hooksPath 2>/dev/null || true)"
  [ "$hp" = ".githooks" ] || note_soft "core.hooksPath is '$hp' (expected .githooks) — run bin/apex.sh to re-arm"
  # Every gate named in the manifest must be implemented here.
  if [ -f apex/GATES.md ]; then
    local g
    for g in $(grep -oE '`gate_[a-z]+`' apex/GATES.md | tr -d '`' | sort -u); do
      declare -F "$g" >/dev/null || note_soft "manifest lists $g but it is not implemented"
    done
  fi
}

# ── GATE: live (is the change actually synced & firing?) ──────────────────────
gate_live() {
  echo "› live"
  local cdir="$HOME/.claude"
  [ -d "$cdir" ] || { note_soft "no ~/.claude in this environment — skipping live check"; return; }
  [ -d "$cdir/skills/apex" ] || note_soft "apex skill not yet synced to ~/.claude (start a new session or run sync)"
  if [ -f "$cdir/settings.json" ]; then
    grep -q 'harness-router.sh' "$cdir/settings.json" || note_soft "harness-router not registered in ~/.claude/settings.json"
  fi
}

# ── GATE: extra (ratchet-generated drop-in checks) ───────────────────────────
# Every mistake the ratchet captures becomes a self-contained apex/checks/*.sh.
# They run here automatically — the layer extends itself without touching this
# core library. Each check: exit 0 = pass, non-zero = HARD.
gate_extra() {
  echo "› extra (ratchet checks)"
  local c found=0
  for c in apex/checks/*.sh; do
    [ -f "$c" ] || continue
    found=1
    if ! bash "$c" >/tmp/apex-extra.out 2>&1; then
      sed 's/^/    /' /tmp/apex-extra.out; note_hard "ratchet check failed: $(basename "$c")"
    fi
  done
  [ "$found" = "0" ] && echo "    (none registered yet)"
}

run() { case "$1" in
  doctor) gate_doctor;; hooklint) gate_hooklint;; secrets) gate_secrets;;
  selfintegrity) gate_selfintegrity;; live) gate_live;; extra) gate_extra;;
  *) echo "unknown gate: $1"; exit 2;; esac; }

echo "═══ apex-gates ($GATE${STAGED:+ , staged=$STAGED}) ═══"
if [ "$GATE" = "all" ]; then
  for g in doctor hooklint secrets selfintegrity extra live; do run "$g"; done
else
  run "$GATE"
fi

echo "─────────────────────────────────────────────"
if [ "$HARD" -gt 0 ]; then echo "✗ apex-gates: $HARD HARD failure(s)"; exit 1; fi
echo "✓ apex-gates: all gates passed"; exit 0
