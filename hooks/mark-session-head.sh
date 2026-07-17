#!/bin/bash
# mark-session-head.sh — SessionStart. Records the commit the session began at,
# so the Stop guard can scan exactly this session's work: committed OR not.
#
# Without this, a Stop guard can only see `git diff HEAD` (uncommitted). Agents
# commit before Stop fires, so that guard would read an empty diff and pass
# everything. Scanning the whole branch instead is the opposite failure: old
# TODOs from previous sessions false-block every turn, forever.
#
# Fails open and silent — a SessionStart hook must never block a session.

# TMPDIR is frequently UNSET in git-bash under Claude Code's cmd wrapper. Take
# the bare default and the marker lands nowhere, the Stop guard silently
# degrades to uncommitted-only, and the gate reports green while reading almost
# nothing. That is the exact bug this file exists to prevent.
TMP="${TMPDIR:-${TEMP:-/tmp}}"
[ -d "$TMP" ] || TMP=/tmp

root="$(git rev-parse --show-toplevel 2>/dev/null)"

# Reap markers older than 7 days so they never pile up.
find "$TMP" -maxdepth 1 -name 'claude-session-head-*' -mtime +7 -delete 2>/dev/null

if [ -z "$root" ]; then
  exit 0
fi

# Hash the repo ROOT, not cwd — two sessions in different subdirs of one repo
# must share a marker, and two different repos must never collide.
hash="$(printf '%s' "$root" | cksum 2>/dev/null | cut -d' ' -f1)"
[ -z "$hash" ] && exit 0
marker="$TMP/claude-session-head-$hash"

sha="$(git rev-parse HEAD 2>/dev/null)"
if [ -z "$sha" ]; then
  # Unborn HEAD (fresh repo, no commits). Clear any stale marker: leaving a
  # previous session's sha behind makes the guard scan two sessions of work.
  rm -f "$marker" 2>/dev/null
  exit 0
fi

printf '%s\n' "$sha" > "$marker" 2>/dev/null
exit 0
