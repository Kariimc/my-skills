#!/bin/bash
# selftest-guards.sh — proves the five guardrail hooks block/allow correctly.
# Run any time: bash ~/.claude/hooks/selftest-guards.sh
cd ~ || exit 1
fails=0
t() { printf '%s' "$2" | bash ".claude/hooks/$3" >/dev/null 2>&1; code=$?
  if [ "$code" -eq "$4" ]; then echo "PASS $1"; else echo "FAIL $1 exit=$code want=$4"; fails=$((fails+1)); fi; }

t "reset--hard blocked"        '{"tool_name":"Bash","tool_input":{"command":"git reset --hard HEAD~1"}}' guard-destructive.sh 2
t "clean-fd blocked"           '{"tool_name":"Bash","tool_input":{"command":"git clean -fd"}}' guard-destructive.sh 2
t "checkout-dot blocked"       '{"tool_name":"Bash","tool_input":{"command":"git checkout ."}}' guard-destructive.sh 2
t "restore-dot blocked"        '{"tool_name":"Bash","tool_input":{"command":"git restore ."}}' guard-destructive.sh 2
t "checkout-branch allowed"    '{"tool_name":"Bash","tool_input":{"command":"git checkout feature-branch"}}' guard-destructive.sh 0
t "forcepush blocked"          '{"tool_name":"Bash","tool_input":{"command":"git push -f origin main"}}' guard-destructive.sh 2
t "force-with-lease allowed"   '{"tool_name":"Bash","tool_input":{"command":"git push --force-with-lease origin main"}}' guard-destructive.sh 0
t "safe-cmd allowed"           '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' guard-destructive.sh 0
t "junk-backup blocked"        '{"tool_name":"Write","tool_input":{"file_path":"C:/app/utils_backup.js"}}' guard-junk-files.sh 2
t "junk-v2 blocked"            '{"tool_name":"Write","tool_input":{"file_path":"C:/app/index_v2.tsx"}}' guard-junk-files.sh 2
t "junk-bak blocked"           '{"tool_name":"Write","tool_input":{"file_path":"C:/app/config.bak"}}' guard-junk-files.sh 2
t "normal-file allowed"        '{"tool_name":"Write","tool_input":{"file_path":"C:/app/src/Navbar.tsx"}}' guard-junk-files.sh 0
t "testfile allowed"           '{"tool_name":"Write","tool_input":{"file_path":"C:/app/tests/test_version_parser.py"}}' guard-junk-files.sh 0
t "stop loop-guard allowed"    '{"stop_hook_active":true}' guard-handoff.sh 0

# guard-handoff against a real throwaway repo
tmp=$(mktemp -d) && cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
echo code > app.js
printf '%s' '{"stop_hook_active":false}' | bash ~/.claude/hooks/guard-handoff.sh >/dev/null 2>&1
[ $? -eq 2 ] && echo "PASS stop-blocked-no-handoff" || { echo "FAIL stop-blocked-no-handoff"; fails=$((fails+1)); }
echo state > PROGRESS.md
printf '%s' '{"stop_hook_active":false}' | bash ~/.claude/hooks/guard-handoff.sh >/dev/null 2>&1
[ $? -eq 0 ] && echo "PASS stop-allowed-with-progress" || { echo "FAIL stop-allowed-with-progress"; fails=$((fails+1)); }
git add -A && git commit -qm x
printf '%s' '{"stop_hook_active":false}' | bash ~/.claude/hooks/guard-handoff.sh >/dev/null 2>&1
[ $? -eq 0 ] && echo "PASS stop-allowed-clean-repo" || { echo "FAIL stop-allowed-clean-repo"; fails=$((fails+1)); }
cd ~ && rm -rf "$tmp"

# --- reply guards (plain-words + loose-ends) against temp transcripts --------
# The reply hooks run Windows python, which cannot read a Git-Bash /tmp path, so
# make the temp dir with python itself (returns a real C:/... path both python
# and bash can open) instead of mktemp.
ttw=$(python - <<'PY' 2>/dev/null
import tempfile
print(tempfile.mkdtemp().replace("\\","/"))
PY
)
mk() { # mk <file> <text>  -> one-line assistant transcript
  python - "$ttw/$1" "$2" <<'PY' 2>/dev/null
import json,sys
open(sys.argv[1],"w",encoding="utf-8").write(json.dumps(
  {"type":"assistant","message":{"content":[{"type":"text","text":sys.argv[2]}]}})+"\n")
PY
}
rg() { # rg <name> <transcript-file> <hook> <want-exit>
  printf '%s' "{\"transcript_path\":\"$ttw/$2\",\"stop_hook_active\":false}" \
    | bash ~/.claude/hooks/"$3" >/dev/null 2>&1; code=$?
  if [ "$code" -eq "$4" ]; then echo "PASS $1"; else echo "FAIL $1 exit=$code want=$4"; fails=$((fails+1)); fi
}
mk wall.jsonl "Pushed commit a1b2c3d..e4f5a6b. Ran tsc + npm build in dashboard/server.py, byte-identity holds."
mk plain.jsonl "Done. X reads your briefings out loud now and you can cut him off anytime."
mk legwork.jsonl "It is built. You should run the briefing yourself to confirm it works."
mk clean.jsonl "Done and verified end to end. Nothing left for you."
rg "plainwords blocks a wall"     wall.jsonl    plain-words-guard.sh 2
rg "plainwords allows plain"      plain.jsonl   plain-words-guard.sh 0
rg "looseends blocks legwork"     legwork.jsonl loose-ends-guard.sh  2
rg "looseends allows clean"       clean.jsonl   loose-ends-guard.sh  0
printf '%s' '{"stop_hook_active":true}' | bash ~/.claude/hooks/plain-words-guard.sh >/dev/null 2>&1
[ $? -eq 0 ] && echo "PASS plainwords loop-guard" || { echo "FAIL plainwords loop-guard"; fails=$((fails+1)); }
printf '%s' '{"stop_hook_active":true}' | bash ~/.claude/hooks/loose-ends-guard.sh >/dev/null 2>&1
[ $? -eq 0 ] && echo "PASS looseends loop-guard" || { echo "FAIL looseends loop-guard"; fails=$((fails+1)); }
[ -n "$ttw" ] && rm -rf "$ttw"

echo "----"
[ "$fails" -eq 0 ] && echo "ALL GUARDS VERIFIED" || echo "$fails FAILURE(S)"
exit "$fails"
