#!/bin/bash
set -euo pipefail
# ─────────────────────────────────────────────────────────────────────────────
# eval-models.sh — grade candidate models against the Fable gold standards.
#
# WHAT IT DOES
#   For every task dir in datasets/gold-standards/ (prompt.md + gold.md +
#   rubric.md), sends prompt.md to each candidate model via the Claude Code
#   CLI, saves the answer under runs/<date>/, then has the JUDGE model score
#   candidate-vs-gold against rubric.md. Prints a task × model scorecard and
#   flags Fable parity (score >= PARITY, default 8).
#   Safety refusals (stop-and-refuse output) are labeled ROUTED and excluded
#   from scoring — a refusal is a routing fact, not a quality signal.
#
# USAGE
#   bash bin/eval-models.sh                          # defaults below
#   MODELS="claude-sonnet-5" bash bin/eval-models.sh
#   JUDGE=claude-opus-4-8 PARITY=8 bash bin/eval-models.sh
#   bash -n bin/eval-models.sh                       # syntax check
#
# EXIT CODES: 0 ran and scored · 2 setup error (no CLI / no dataset)
# NOTE: informational by default (no accuracy gate) — model comparison is a
#   measurement, not a regression test. Add a gate only if a floor emerges.
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GS_DIR="$REPO_ROOT/datasets/gold-standards"
MODELS="${MODELS:-claude-sonnet-5 claude-opus-4-8}"
JUDGE="${JUDGE:-claude-opus-4-8}"
PARITY="${PARITY:-8}"
RUN_DIR="$GS_DIR/runs/$(date +%Y-%m-%d)"

command -v claude >/dev/null 2>&1 || { echo "eval-models: claude CLI not on PATH" >&2; exit 2; }
ls -d "$GS_DIR"/*/prompt.md >/dev/null 2>&1 || { echo "eval-models: no task dirs under $GS_DIR" >&2; exit 2; }
mkdir -p "$RUN_DIR"

RESULTS_TSV="$(mktemp)"; trap 'rm -f "$RESULTS_TSV"' EXIT

looks_refused() {  # crude but safe: short output that opens by declining
  local f="$1"
  [ "$(wc -c < "$f")" -lt 400 ] && grep -qiE "can't help|cannot help|unable to (help|assist)|won't be able" "$f"
}

for task_dir in "$GS_DIR"/*/; do
  task="$(basename "$task_dir")"
  [ -f "$task_dir/prompt.md" ] && [ -f "$task_dir/gold.md" ] && [ -f "$task_dir/rubric.md" ] || continue
  for model in $MODELS; do
    ans="$RUN_DIR/$task.$model.md"
    echo "── $task × $model" >&2
    if ! claude -p "$(cat "$task_dir/prompt.md")" --model "$model" > "$ans" 2>/dev/null || [ ! -s "$ans" ]; then
      printf '%s\t%s\tERROR\n' "$task" "$model" >> "$RESULTS_TSV"; continue
    fi
    if looks_refused "$ans"; then
      printf '%s\t%s\tROUTED\n' "$task" "$model" >> "$RESULTS_TSV"; continue
    fi
    grade="$RUN_DIR/$task.$model.grade.md"
    claude -p "You are a strict grader. Score the CANDIDATE against the GOLD using the RUBRIC.
Score each dimension 0-2 quoting the candidate's own words as evidence. Do not
reward content absent from the candidate. End with exactly one line: TOTAL: <n>/10

RUBRIC:
$(cat "$task_dir/rubric.md")

GOLD:
$(cat "$task_dir/gold.md")

CANDIDATE:
$(cat "$ans")" --model "$JUDGE" > "$grade" 2>/dev/null || true
    score="$(grep -oE 'TOTAL: *[0-9]+/10' "$grade" | tail -n1 | grep -oE '[0-9]+' | head -n1 || true)"
    printf '%s\t%s\t%s\n' "$task" "$model" "${score:-UNGRADED}" >> "$RESULTS_TSV"
  done
done

awk -v parity="$PARITY" -F'\t' '
{ r[$1 FS $2] = $3; tasks[$1]=1; models[$2]=1 }
END {
  printf "\nGold-Standard Model Eval  (parity bar: >=%d/10)\n", parity
  printf "================================================\n"
  printf "%-22s", "task"
  for (m in models) printf " %-18s", m
  printf "\n"
  for (t in tasks) {
    printf "%-22s", t
    for (m in models) {
      v = r[t FS m]
      tag = (v+0 >= parity && v ~ /^[0-9]+$/) ? v"/10 PARITY" : (v ~ /^[0-9]+$/ ? v"/10" : v)
      printf " %-18s", tag
    }
    printf "\n"
  }
  printf "\nAnswers + judge transcripts: see runs/ dir. ROUTED = safety refusal (excluded). \n"
}' "$RESULTS_TSV"
echo "run dir: $RUN_DIR"
