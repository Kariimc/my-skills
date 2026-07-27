#!/bin/bash
# verify-gate.sh — the Stop gate. A turn cannot end until the project verifies.
#
# Two modes, one file:
#   verify-gate.sh            (stdin = Stop hook JSON)  -> gate mode, exit 2 blocks
#   verify-gate.sh --run      (no stdin)                -> just run the checks
#
# Runs, in order and skipping cleanly whatever a project does not have:
#   typecheck -> lint -> build -> test
# Exits non-zero on the FIRST real failure.
#
# Cheap by design (it fires on every turn end):
#   * fast pre-filter — nothing to verify / no working-tree change => instant exit
#   * fingerprint cache — an unchanged tree that already passed is not re-run
#
# Cannot deadlock:
#   * 8 consecutive blocks in one session releases the gate with a warning
#   * VERIFY_SKIP=1 in the environment disables it outright
#   * every unexpected condition fails OPEN (exit 0)
#
# Run it by hand from any project with:  verify

set -u

STATE_DIR="${HOME}/.claude/.verify-gate"
mkdir -p "$STATE_DIR" 2>/dev/null

MODE="gate"
[ "${1:-}" = "--run" ] && MODE="run"

# ─────────────────────────── gate-mode preamble ────────────────────────────
SESSION_ID="manual"
if [ "$MODE" = "gate" ]; then
  input="$(cat)"
  [ -n "${VERIFY_SKIP:-}" ] && exit 0

  SESSION_ID=$(printf '%s' "$input" \
    | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')
  [ -z "$SESSION_ID" ] && SESSION_ID="unknown"

  HOOK_CWD=$(printf '%s' "$input" \
    | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed 's/^.*"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//; s|\\\\|/|g')
  [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] && cd "$HOOK_CWD" 2>/dev/null
fi

COUNT_FILE="$STATE_DIR/${SESSION_ID}.count"
PASS_FILE="$STATE_DIR/${SESSION_ID}.pass"

release_and_reset() { rm -f "$COUNT_FILE" 2>/dev/null; exit 0; }

# ───────────────────────────── fast pre-filter ─────────────────────────────
# Not a git repo, or nothing changed in the working tree => nothing to verify.
if [ "$MODE" = "gate" ]; then
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || release_and_reset
  DIRTY="$(git status --porcelain 2>/dev/null)"
  [ -z "$DIRTY" ] && release_and_reset

  FINGERPRINT="$(printf '%s|%s' "$(git rev-parse HEAD 2>/dev/null)" "$DIRTY" \
                 | sha1sum 2>/dev/null | cut -d' ' -f1)"
  if [ -n "$FINGERPRINT" ] && [ -f "$PASS_FILE" ]; then
    [ "$(cat "$PASS_FILE" 2>/dev/null)" = "$FINGERPRINT" ] && release_and_reset
  fi
fi

# ───────────────────────────── the checks ──────────────────────────────────
OUT=""
say() { OUT="${OUT}$1"$'\n'; [ "$MODE" = "run" ] && printf '%s\n' "$1"; }

TIMEOUT=""
command -v timeout >/dev/null 2>&1 && TIMEOUT="timeout 600"

FAILED=""
FAIL_LOG=""

run_step() {   # run_step <label> <command...>
  local label="$1"; shift
  say "--- $label ---"
  local log
  log="$( { $TIMEOUT "$@" ; } 2>&1 )"
  local rc=$?
  if [ $rc -eq 0 ]; then
    say "PASS  $label"
    return 0
  fi
  say "FAIL  $label  (exit $rc)"
  FAILED="$label"
  FAIL_LOG="$(printf '%s' "$log" | tail -30)"
  return 1
}

STEPS_RUN=0

# ---- Node / package.json --------------------------------------------------
if [ -f package.json ] && command -v node >/dev/null 2>&1; then
  PM=npm
  [ -f pnpm-lock.yaml ] && PM=pnpm
  [ -f yarn.lock ]      && PM=yarn
  [ -f bun.lockb ]      && PM=bun
  command -v "$PM" >/dev/null 2>&1 || PM=npm

  has_script() {
    node -e "try{const s=require(process.cwd()+'/package.json').scripts||{};process.exit(s[process.argv[1]]?0:1)}catch(e){process.exit(1)}" "$1" >/dev/null 2>&1
  }
  first_script() {  # echo the first of the given script names that exists
    for n in "$@"; do if has_script "$n"; then printf '%s' "$n"; return 0; fi; done
    return 1
  }

  export CI=true          # keeps vitest/jest out of interactive watch mode

  for group in "typecheck type-check tsc types" "lint" "build" "test tests"; do
    # shellcheck disable=SC2086
    s="$(first_script $group)" || { say "skip  ${group%% *} (no script)"; continue; }
    STEPS_RUN=$((STEPS_RUN+1))
    run_step "$s" "$PM" run "$s" || break
  done
fi

# ---- Python ---------------------------------------------------------------
if [ -z "$FAILED" ] && { [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; }; then
  if command -v ruff >/dev/null 2>&1; then
    STEPS_RUN=$((STEPS_RUN+1)); run_step "ruff check" ruff check .
  else
    say "skip  ruff (not installed)"
  fi
  if [ -z "$FAILED" ]; then
    if command -v pytest >/dev/null 2>&1 && { [ -d tests ] || [ -d test ]; }; then
      STEPS_RUN=$((STEPS_RUN+1)); run_step "pytest" pytest -q
    else
      say "skip  pytest (no pytest or no tests/ dir)"
    fi
  fi
fi

[ "$STEPS_RUN" -eq 0 ] && say "nothing to verify in this project"

# ───────────────────────────── verdict ─────────────────────────────────────
if [ "$MODE" = "run" ]; then
  if [ -n "$FAILED" ]; then printf '\nVERIFY FAILED at: %s\n' "$FAILED"; exit 1; fi
  printf '\nVERIFY PASSED\n'; exit 0
fi

if [ -z "$FAILED" ]; then
  [ -n "${FINGERPRINT:-}" ] && printf '%s' "$FINGERPRINT" > "$PASS_FILE"
  release_and_reset
fi

# --- failing: block, unless we have blocked 8 times already -----------------
N=0
[ -f "$COUNT_FILE" ] && N="$(cat "$COUNT_FILE" 2>/dev/null)"
case "$N" in ''|*[!0-9]*) N=0 ;; esac
N=$((N+1))
printf '%s' "$N" > "$COUNT_FILE"

if [ "$N" -ge 8 ]; then
  rm -f "$COUNT_FILE" 2>/dev/null
  printf 'VERIFY GATE RELEASED after 8 blocked attempts — "%s" is still failing. Not a pass; say so plainly.\n' "$FAILED" >&2
  exit 0
fi

{
  printf 'VERIFY GATE BLOCKED (%d/8) — this turn cannot end: "%s" is failing.\n\n' "$N" "$FAILED"
  printf '%s\n\n' "$FAIL_LOG"
  printf 'Fix it and let the gate re-run. Do not report this work as done.\n'
  printf 'If the failure is pre-existing and out of scope, say that in one line — the gate releases itself after 8 attempts.\n'
} >&2
exit 2
