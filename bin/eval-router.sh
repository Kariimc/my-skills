#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# eval-router.sh — runnable eval for the harness router hook.
#
# WHAT IT DOES
#   Feeds every prompt in datasets/harness-routing/cases.jsonl through the REAL
#   hook (hooks/harness-router.sh) exactly as Claude Code would — as a JSON
#   payload on stdin — then parses which harness the hook suggested (if any),
#   compares it to the case's `expected`, and prints a scorecard:
#     • per-class precision / recall / F1
#     • overall accuracy
#     • a list of every mismatch (prompt, expected, got)
#   Exits nonzero if overall accuracy falls below THRESHOLD (see below), so it
#   doubles as a CI gate against router regressions.
#
# DATASET SCHEMA (one JSON object per line, produced by a parallel task):
#     {"prompt": "<user prompt text>", "expected": "<label>"}
#   where <label> is one of the six harness names —
#     harness-build | harness-quality | harness-research |
#     harness-audit  | harness-autonomous | harness-refactor
#   OR a negative meaning "the router should stay silent": any of
#     none | "" | null   (all normalized to the pseudo-class "none").
#   Unknown/extra fields are ignored. `expected` may also be given bare as
#   just "build" etc.; it is normalized to the full "harness-build" form.
#
# HOW ROUTING IS READ
#   The hook prints at most one line containing the backticked harness name,
#   e.g.  ...— `harness-build` (plan → ...).  We extract the FIRST token
#   matching /harness-[a-z]+/ from the hook's stdout. No match ⇒ "none".
#
# USAGE
#     bash bin/eval-router.sh                 # run against the default dataset
#     DATASET=path/to/cases.jsonl bash bin/eval-router.sh
#     THRESHOLD=0.95 bash bin/eval-router.sh  # tighten the CI gate
#     bash -n bin/eval-router.sh              # syntax-check only
#
# EXIT CODES
#     0  accuracy >= THRESHOLD
#     1  accuracy <  THRESHOLD (regression)
#     2  setup error (missing hook, missing/empty dataset, no interpreter)
# ─────────────────────────────────────────────────────────────────────────────

# --- Locate repo paths relative to this script (works from any cwd) ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/harness-router.sh"
DATASET="${DATASET:-$REPO_ROOT/datasets/harness-routing/cases.jsonl}"

# Accuracy gate. Start lenient at 0.90 — the router is intentionally
# conservative (silent on ambiguous prompts), so a few negatives that "should"
# have routed are expected. Raise via THRESHOLD=... once the dataset stabilizes.
THRESHOLD="${THRESHOLD:-0.90}"

# The full label set. "none" is the pseudo-class for "router stayed silent".
CLASSES="harness-build harness-quality harness-research harness-audit harness-autonomous harness-refactor none"

# --- Preflight ---------------------------------------------------------------
if [ ! -f "$HOOK" ]; then
  echo "eval-router: hook not found: $HOOK" >&2
  exit 2
fi
if [ ! -s "$DATASET" ]; then
  echo "eval-router: dataset missing or empty: $DATASET" >&2
  echo "  (it is produced by a separate task; expected schema: {\"prompt\",\"expected\"})" >&2
  exit 2
fi

# Resolve the fastest interpreter for JSONL parsing only (routing itself goes
# through the hook). Prefer a real python over the slow WindowsApps shim; fall
# back to python3/python on PATH. No python ⇒ we cannot safely parse JSON.
EVAL_PY=""
for cand in \
  "${LOCALAPPDATA:-}/Python/pythoncore-3.14-64/python.exe" \
  "${LOCALAPPDATA:-}/Programs/Python/Python313/python.exe" \
  "${LOCALAPPDATA:-}/Programs/Python/Python312/python.exe"; do
  [ -x "$cand" ] && EVAL_PY="$cand" && break
done
if [ -z "$EVAL_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then EVAL_PY=python3
  elif command -v python >/dev/null 2>&1; then EVAL_PY=python
  else
    echo "eval-router: no python interpreter found to parse the dataset" >&2
    exit 2
  fi
fi

# --- Scratch files -----------------------------------------------------------
# TSV of parsed cases:   <expected-label>\t<prompt>
CASES_TSV="$(mktemp)"
# TSV of results:        <expected>\t<got>\t<prompt>
RESULTS_TSV="$(mktemp)"
cleanup() { rm -f "$CASES_TSV" "$RESULTS_TSV"; }
trap cleanup EXIT

# --- Parse the JSONL into TSV (expected, prompt) -----------------------------
# Normalization of `expected` lives here so the bash loop stays simple:
#   • strip a leading "harness-" then re-add it, so "build" and "harness-build"
#     both land on "harness-build"
#   • null / missing / empty / "none" → "none"
#   • tabs and newlines inside the prompt are squashed so the TSV stays 2-column
export EVAL_DATASET="$DATASET"
"$EVAL_PY" - > "$CASES_TSV" <<'PY'
import os, sys, json

valid = {
    "build", "quality", "research", "audit", "autonomous", "refactor",
}

def norm(label):
    if label is None:
        return "none"
    s = str(label).strip().lower()
    if s in ("", "none", "null", "n/a", "na"):
        return "none"
    if s.startswith("harness-"):
        s = s[len("harness-"):]
    if s in valid:
        return "harness-" + s
    # Unknown label: treat as its own class so it surfaces as a miss rather
    # than silently mapping to a real harness.
    return "harness-" + s

path = os.environ["EVAL_DATASET"]
out = sys.stdout
n = 0
with open(path, "r", encoding="utf-8") as fh:
    for raw in fh:
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except Exception:
            # Skip unparseable lines but keep going; count nothing for them.
            sys.stderr.write("eval-router: skipping unparseable line\n")
            continue
        prompt = obj.get("prompt")
        if prompt is None:
            continue
        expected = norm(obj.get("expected"))
        # Flatten whitespace so the prompt survives a tab-separated round trip.
        prompt = " ".join(str(prompt).split())
        out.write(expected + "\t" + prompt + "\n")
        n += 1
if n == 0:
    sys.stderr.write("eval-router: no usable cases parsed from dataset\n")
    sys.exit(3)
PY
parse_rc=$?
if [ "$parse_rc" -ne 0 ]; then
  echo "eval-router: failed to parse dataset (rc=$parse_rc)" >&2
  exit 2
fi

# --- Run each case through the real hook -------------------------------------
# The hook reads a JSON payload on stdin and prints one line (or nothing). We
# rebuild a minimal, correctly-escaped {"prompt": ...} payload per case via
# python so quotes/backslashes in the prompt can't corrupt the JSON.
route_one() {
  # $1 = prompt text; echoes the detected harness name or "none".
  local prompt="$1" payload out got
  payload="$(P="$prompt" "$EVAL_PY" -c 'import os,json,sys; sys.stdout.write(json.dumps({"prompt": os.environ["P"]}))')"
  # Never let a hook failure abort the whole eval; treat errors as "none".
  out="$(printf '%s' "$payload" | bash "$HOOK" 2>/dev/null || true)"
  # Extract the suggested harness. The hook prefixes every line with the
  # literal tag "[harness-router]", so a naive grep for /harness-[a-z]+/ would
  # match that tag first. The real suggestion is always backticked, e.g.
  # `harness-build` — so match the backticked form first, then fall back to any
  # harness-<word> token that isn't the router tag itself.
  got="$(printf '%s' "$out" | grep -oE '`harness-[a-z]+`' | head -n1 | tr -d '`' || true)"
  if [ -z "$got" ]; then
    got="$(printf '%s' "$out" | grep -oE 'harness-[a-z]+' | grep -v '^harness-router$' | head -n1 || true)"
  fi
  [ -z "$got" ] && got="none"
  printf '%s' "$got"
}

total=0
while IFS=$'\t' read -r expected prompt; do
  [ -z "${expected:-}" ] && continue
  got="$(route_one "$prompt")"
  printf '%s\t%s\t%s\n' "$expected" "$got" "$prompt" >> "$RESULTS_TSV"
  total=$((total + 1))
done < "$CASES_TSV"

if [ "$total" -eq 0 ]; then
  echo "eval-router: no cases were evaluated" >&2
  exit 2
fi

# --- Score: per-class precision/recall/F1, overall accuracy, mismatches ------
# All arithmetic in awk (integer counts → float ratios). awk also prints the
# scorecard. It exits 0 if accuracy >= THRESHOLD, else 1, and we propagate that.
awk -v classes="$CLASSES" -v threshold="$THRESHOLD" -v total="$total" '
BEGIN {
  FS = "\t"
  nclass = split(classes, C, " ")
}
{
  # NB: `exp` is a gawk builtin (e^x) — cannot be used as a variable name.
  ex = $1; got = $2; pr = $3
  seen_exp[ex] = 1; seen_got[got] = 1
  support[ex]++             # actual count per class (for recall denom)
  predicted[got]++          # predicted count per class (for precision denom)
  if (ex == got) {
    tp[ex]++
    correct++
  } else {
    # Buffer mismatches to print after the table.
    nm++
    mm_exp[nm] = ex; mm_got[nm] = got; mm_prompt[nm] = pr
  }
}
END {
  acc = (total > 0) ? correct / total : 0

  printf "\n"
  printf "Harness Router Eval\n"
  printf "===================\n"
  printf "dataset cases: %d\n\n", total

  # Column header.
  printf "%-20s %9s %7s %7s %9s\n", "class", "precision", "recall", "f1", "support"
  printf "%-20s %9s %7s %7s %9s\n", "--------------------", "---------", "-------", "-------", "-------"

  # Iterate classes in the canonical order, then any unexpected labels seen.
  for (i = 1; i <= nclass; i++) print_class(C[i])
  # Surface any class that appeared in data but not in the canonical list.
  for (k in seen_exp) if (!(k in printed)) print_class(k)
  for (k in seen_got) if (!(k in printed)) print_class(k)

  printf "\n"
  printf "overall accuracy: %.4f  (%d/%d correct)\n", acc, correct, total
  printf "threshold:        %.4f\n", threshold

  # Mismatch listing.
  if (nm > 0) {
    printf "\nmismatches (%d):\n", nm
    for (j = 1; j <= nm; j++) {
      p = mm_prompt[j]
      if (length(p) > 72) p = substr(p, 1, 69) "..."
      printf "  expected %-19s got %-19s | %s\n", mm_exp[j], mm_got[j], p
    }
  } else {
    printf "\nmismatches (0): none — perfect routing on this set.\n"
  }

  # Gate.
  if (acc + 1e-9 < threshold) {
    printf "\nRESULT: FAIL — accuracy %.4f < threshold %.4f\n", acc, threshold
    exit 1
  } else {
    printf "\nRESULT: PASS — accuracy %.4f >= threshold %.4f\n", acc, threshold
    exit 0
  }
}
# Print one metrics row for class c (guards divide-by-zero; skips classes with
# neither support nor predictions so the table stays tight).
function print_class(c,   prec, rec, f1) {
  if (c in printed) return
  printed[c] = 1
  if (support[c] == 0 && predicted[c] == 0) return
  prec = (predicted[c] > 0) ? tp[c] / predicted[c] : 0
  rec  = (support[c]   > 0) ? tp[c] / support[c]   : 0
  f1   = (prec + rec > 0)   ? 2 * prec * rec / (prec + rec) : 0
  printf "%-20s %9.3f %7.3f %7.3f %9d\n", c, prec, rec, f1, support[c]
}
' "$RESULTS_TSV"
