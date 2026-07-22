#!/usr/bin/env bash
# 3d-master-modeler dependency bootstrap.
# Idempotent + non-blocking: skips instantly when the engine is already present,
# otherwise installs the pinned deps IN THE BACKGROUND so session start never waits.
# Wired into the repo SessionStart hook (.claude/settings.json), so a fresh cloud
# box auto-installs the engine hands-free — no manual re-download, no blocked session.
# (The container is wiped between sessions, so the wheels are re-fetched each time;
#  this just makes that automatic and out of the way. To eliminate the fetch entirely
#  you'd need a custom environment image with the wheels pre-baked — an env-config job,
#  not a repo one.)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ="$DIR/requirements.txt"
LOG="/tmp/3d-master-modeler-deps.log"

# already installed → nothing to do (fast path, every warm session)
if python3 -c "import bpy" >/dev/null 2>&1; then
  exit 0
fi

# only bpy needs CPython 3.11; bail quietly if the interpreter can't host the wheel
PYV="$(python3 -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)"
if [ "$PYV" != "3.11" ]; then
  echo "3d-master-modeler: python $PYV present; bpy wheel needs 3.11 — skipping auto-install" >>"$LOG" 2>&1
  exit 0
fi

# install detached so the session starts immediately; result lands in $LOG
nohup python3 -m pip install -q -r "$REQ" >>"$LOG" 2>&1 &
exit 0
