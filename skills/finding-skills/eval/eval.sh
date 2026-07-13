#!/usr/bin/env bash
# Regression gate for the skill dispatcher (mirrors bin/eval-router.sh).
# Feeds every case through the REAL find-skills.py and scores recall@k:
# an obvious-owner task must surface its skill in the top-k. Fails below THRESHOLD.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K="${K:-5}"; THRESHOLD="${THRESHOLD:-0.85}"
cases="$DIR/eval/cases.jsonl"; pass=0; total=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  total=$((total+1))
  q=$(printf '%s' "$line" | python3 -c "import sys,json;print(json.loads(sys.stdin.read())['query'])")
  names=$(python3 "$DIR/tool/find-skills.py" -k "$K" --json "$q" \
          | python3 -c "import sys,json;print(' '.join(h['name'] for h in json.load(sys.stdin)))")
  hit=$(printf '%s' "$line" | python3 -c "
import sys,json
exp=json.loads(sys.stdin.read())['expect']; got=set('''$names'''.split())
print(1 if any(e in got for e in exp) else 0)")
  if [ "$hit" = "1" ]; then pass=$((pass+1)); else echo "MISS: $q -> [$names]"; fi
done < "$cases"
acc=$(python3 -c "print(f'{$pass/$total:.3f}')")
echo "recall@$K: $pass/$total = $acc  (threshold $THRESHOLD)"
python3 -c "import sys; sys.exit(0 if $pass/$total >= $THRESHOLD else 1)"
