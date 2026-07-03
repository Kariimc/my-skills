#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# harness-routing eval — runs every case in cases.jsonl through the REAL
# hooks/harness-router.sh (via its UserPromptSubmit stdin contract) and checks
# the harness it routes to against the expected label.
#
# This is a behavioral regression guard: if anyone edits a regex branch in
# harness-router.sh, cases that used to route one way start routing another and
# this eval fails with a precise per-case diff.
#
# Router output contract (from the hook): on a confident match it prints a line
#   [harness-router] This may match the **<Title>** — `<harness-name>` (...)
# and on no match it prints nothing. The eval treats the backticked
# `<harness-name>` as the actual route, or "none" when the router is silent.
#
# Speed: the router spawns its own python per invocation. To keep the harness
# itself cheap we do ALL json work in ONE python pass up front (emit a TSV of
# expected<TAB>payload), then the bash loop only pipes each payload into the
# router and greps the result — no extra python per case.
#
# Usage:   bash datasets/harness-routing/run-eval.sh
# Exit:    0 = all cases match expected; 1 = >=1 mismatch; 2 = setup error
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
ROUTER="$REPO/hooks/harness-router.sh"
CASES="$HERE/cases.jsonl"

[ -f "$ROUTER" ] || { echo "FATAL: router not found at $ROUTER" >&2; exit 2; }
[ -f "$CASES" ]  || { echo "FATAL: cases not found at $CASES"  >&2; exit 2; }

PY=""
for c in python3 python; do command -v "$c" >/dev/null 2>&1 && PY="$c" && break; done
[ -n "$PY" ] || { echo "FATAL: no python on PATH for the test harness" >&2; exit 2; }

# One python pass: validate each line and emit  expected \t compact-json-payload
# The payload is exactly {"prompt": "..."} — the hook's stdin contract.
TSV="$("$PY" - "$CASES" <<'PY'
import sys, json
path = sys.argv[1]
out = []
with open(path, encoding="utf-8") as f:
    for ln in f:
        ln = ln.strip()
        if not ln:
            continue
        obj = json.loads(ln)
        prompt = obj["prompt"]
        expected = obj["expected"]
        payload = json.dumps({"prompt": prompt})
        # payload has no tabs/newlines (json escapes them); safe as a TSV field.
        out.append(expected + "\t" + payload)
sys.stdout.write("\n".join(out))
PY
)"
[ -n "$TSV" ] || { echo "FATAL: no cases parsed from $CASES" >&2; exit 2; }

pass=0; fail=0; total=0
fail_report=""

while IFS=$'\t' read -r expected payload; do
  [ -z "$expected" ] && continue
  out="$(printf '%s' "$payload" | bash "$ROUTER" 2>/dev/null)"
  # Extract `harness-xxx` from the hint line; silent output => none.
  actual="$(printf '%s' "$out" | grep -oE '`harness-[a-z]+`' | head -n1 | tr -d '`')"
  [ -z "$actual" ] && actual="none"

  total=$((total+1))
  if [ "$actual" = "$expected" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    # recover the human-readable prompt for the report
    prompt="$(printf '%s' "$payload" | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["prompt"])')"
    fail_report="${fail_report}  expected=${expected}  actual=${actual}  ::  ${prompt}"$'\n'
  fi
done <<< "$TSV"

echo "harness-routing eval: ${pass}/${total} passed, ${fail} failed"
if [ "$fail" -gt 0 ]; then
  echo "── mismatches ──────────────────────────────────────────────"
  printf '%s' "$fail_report"
  exit 1
fi
echo "All cases route as expected. Router behavior matches the dataset."
exit 0
