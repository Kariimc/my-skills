#!/bin/bash
# guard-handoff.sh — Stop guardrail
# Refuses to let a session end when project files changed but no continuity
# file (PROGRESS.md or HANDOFF.md) was updated. Forces the agent to write the
# handoff itself, per the standing Continuity rule — the user never asks.
#
# Exit 0 = allow stop. Exit 2 = block stop (Claude sees the message, writes
# the handoff, then finishes).

input="$(cat)"

# Loop guard: if this hook already blocked once this stop, let it through.
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

# Fast path: not inside a git repo -> nothing to enforce.
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -z "$root" ] && exit 0

status="$(git -C "$root" status --porcelain 2>/dev/null)"
[ -z "$status" ] && exit 0   # nothing changed this session -> allowed to stop

# If a continuity file is among the changes, the handoff was written -> allow.
case "$status" in
  *PROGRESS.md*|*progress.md*|*HANDOFF.md*|*handoff.md*) exit 0 ;;
esac

msg="GUARDRAIL BLOCKED (Continuity): project files changed but PROGRESS.md/HANDOFF.md was not updated. Before finishing, update the repo's continuity file with: current state, what changed this session, exact next steps, and open decisions — detailed enough that any agent resumes cold with zero briefing. Then finish."
echo "$msg" >&2
echo "$msg"
exit 2
