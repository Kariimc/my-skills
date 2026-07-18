#!/bin/bash
# guard-fabrication.sh — Stop guardrail.
# Blocks a session from ending while this session's new CODE still carries
# fabrication markers (TODO/FIXME/XXX, "rest of code remains the same", etc).
# Kariim's rule: done = 100%, zero loose ends. A parked TODO is a loose end the
# agent chose not to mention.
#
# Pairs with mark-session-head.sh (SessionStart) so the scope is exactly this
# session's work — committed or not. Detection lives in detect-fabrication.sh,
# shared verbatim with the CI gate, so local and cloud can never disagree.
#
# Exit 0 = allow stop. Exit 2 = block (Claude fixes, then finishes).
# Fails open everywhere: a guard that can lock a session is worse than none.

input="$(cat)"

# Loop guard: if this hook already blocked once this stop, let it through.
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -z "$root" ] && exit 0

DET="$(dirname "$0")/detect-fabrication.sh"
[ -f "$DET" ] || exit 0

TMP="${TMPDIR:-${TEMP:-/tmp}}"
[ -d "$TMP" ] || TMP=/tmp
hash="$(printf '%s' "$root" | cksum 2>/dev/null | cut -d' ' -f1)"
marker="$TMP/claude-session-head-$hash"

base=""
if [ -n "$hash" ] && [ -f "$marker" ]; then
  base="$(cat "$marker" 2>/dev/null)"
  # A rebase/amend mid-session can orphan the sha. Fall back rather than error.
  git -C "$root" cat-file -e "$base^{commit}" 2>/dev/null || base=""
fi

# -a matters: a PNG in the diff otherwise yields "Binary file matches" or stalls.
if [ -n "$base" ]; then
  diff_out="$(git -C "$root" diff --no-color -a "$base" 2>/dev/null)"
else
  diff_out="$(git -C "$root" diff --no-color -a HEAD 2>/dev/null)"
fi
[ -z "$diff_out" ] && exit 0

hits="$(printf '%s\n' "$diff_out" | bash "$DET" 2>/dev/null)"
rc=$?
[ "$rc" = "1" ] || exit 0
[ -z "$hits" ] && exit 0

msg="GUARDRAIL BLOCKED (Fabrication): code you added this session still has placeholders or parked work. Kariim's rule is done = 100%, zero loose ends — a TODO is a loose end you chose not to mention. Finish the real implementation, or if it genuinely cannot be done now, say so in ONE line and remove the marker. Offenders:
$hits"
echo "$msg" >&2
echo "$msg"
exit 2
