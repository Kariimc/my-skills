#!/bin/bash
# Regression proof for the Kariim-only Chief-of-Staff edit lock.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$ROOT/hooks/guard-destructive.sh"
fails=0
passed=0

check() {
  local name="$1" payload="$2" expected="$3" actual
  printf '%s' "$payload" | bash "$GUARD" >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    passed=$((passed + 1))
  else
    echo "FAIL $name: exit=$actual want=$expected"
    fails=$((fails + 1))
  fi
}

check "agent edit blocked" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/repo/agents/chief-of-staff.md"}}' 2
check "rule edit blocked" \
  '{"tool_name":"Write","tool_input":{"file_path":"/repo/rules/15-chief-of-staff.md"}}' 2
check "enforcement switch blocked" \
  '{"tool_name":"Write","tool_input":{"file_path":"/home/kariim/.claude/cos/ENFORCE"}}' 2
check "unrelated agent edit allowed" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/repo/agents/planner.md"}}' 0
check "shell write blocked" \
  '{"tool_name":"Bash","tool_input":{"command":"Add-Content agents/chief-of-staff.md changed"}}' 2
check "shell read allowed" \
  '{"tool_name":"Bash","tool_input":{"command":"Get-Content agents/chief-of-staff.md"}}' 0

payload='{"tool_name":"Bash","tool_input":{"command":"Add-Content agents/chief-of-staff.md changed"}}'
printf '%s' "$payload" | KARIIM_COS_EDIT=yes bash "$GUARD" >/dev/null 2>&1
actual=$?
if [ "$actual" -eq 0 ]; then
  passed=$((passed + 1))
else
  echo "FAIL authorized override: exit=$actual want=0"
  fails=$((fails + 1))
fi

if bash -n "$GUARD"; then
  passed=$((passed + 1))
else
  echo "FAIL guard syntax"
  fails=$((fails + 1))
fi

if [ "$fails" -ne 0 ]; then
  echo "cos-edit-lock: $fails failure(s), $passed/8 passed"
  exit 1
fi

echo "cos-edit-lock: 8/8 passed"
