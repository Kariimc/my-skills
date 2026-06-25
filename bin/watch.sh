#!/usr/bin/env bash
# watch.sh — auto-commit + sync whenever skills/commands/agents/rules change.
#
# Usage:
#   bash bin/watch.sh          # runs in foreground; Ctrl-C to stop
#   bash bin/watch.sh &        # run in background
#   nohup bash bin/watch.sh &  # survive terminal close
#
# On every detected change it:
#   1. Waits 2 s for any burst of writes to settle
#   2. Stages all changes in the watched directories
#   3. Commits with an auto-generated message (skips if nothing to commit)
#   4. Syncs to ~/.claude/ via session-start.sh
#   5. Pushes to origin (non-blocking; skipped if no remote or offline)

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WATCH_DIRS=("$REPO/skills" "$REPO/commands" "$REPO/agents" "$REPO/rules")

# ── pick a watcher ────────────────────────────────────────────────────────────
if command -v inotifywait >/dev/null 2>&1; then
  WATCHER=inotify
elif command -v fswatch >/dev/null 2>&1; then
  WATCHER=fswatch
else
  echo "[watch] neither inotifywait nor fswatch found — falling back to 5 s polling"
  WATCHER=poll
fi

echo "[watch] watching ${WATCH_DIRS[*]}"
echo "[watch] watcher: $WATCHER  |  repo: $REPO"

# ── sync + commit helper ──────────────────────────────────────────────────────
_sync_and_commit() {
  cd "$REPO"

  # Stage everything in the watched dirs that git knows about or is new
  for d in skills commands agents rules; do
    [ -d "$d" ] && git add "$d" 2>/dev/null || true
  done

  # Bail out if nothing changed
  git diff --cached --quiet && return 0

  # Build a compact commit message from what changed
  ADDED=$(git diff --cached --name-only --diff-filter=A | wc -l | tr -d ' ')
  MODIFIED=$(git diff --cached --name-only --diff-filter=M | wc -l | tr -d ' ')
  DELETED=$(git diff --cached --name-only --diff-filter=D | wc -l | tr -d ' ')
  MSG="auto: "
  [[ $ADDED   -gt 0 ]] && MSG+="${ADDED} added "
  [[ $MODIFIED -gt 0 ]] && MSG+="${MODIFIED} modified "
  [[ $DELETED -gt 0 ]] && MSG+="${DELETED} deleted "
  MSG+="[watch.sh]"

  git commit -m "$MSG" --no-verify >/dev/null 2>&1 \
    && echo "[watch] committed: $MSG" \
    || echo "[watch] commit failed (pre-commit gate?)"

  # Sync to ~/.claude/
  CLAUDE_PROJECT_DIR="$REPO" bash "$REPO/.claude/hooks/session-start.sh" \
    >/dev/null 2>&1 &
  echo "[watch] synced to ~/.claude/"

  # Best-effort push — don't fail if offline or no remote
  git push origin HEAD 2>/dev/null && echo "[watch] pushed to origin" || true
}

# ── watcher loops ─────────────────────────────────────────────────────────────
if [[ $WATCHER == inotify ]]; then
  # Watch recursively for close_write, create, delete, move events
  inotifywait -q -m -r -e close_write,create,delete,moved_to,moved_from \
    "${WATCH_DIRS[@]}" 2>/dev/null \
  | while read -r _dir _event _file; do
      sleep 2          # let burst of writes settle
      _sync_and_commit
    done

elif [[ $WATCHER == fswatch ]]; then
  fswatch -r "${WATCH_DIRS[@]}" | while read -r _path; do
    sleep 2
    _sync_and_commit
  done

else  # poll every 5 s
  while true; do
    sleep 5
    cd "$REPO"
    for d in skills commands agents rules; do
      [ -d "$d" ] && git add "$d" 2>/dev/null || true
    done
    git diff --cached --quiet || _sync_and_commit
  done
fi
