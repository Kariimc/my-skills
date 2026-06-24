#!/usr/bin/env bash
# omni3d_drive.sh — drive the Omni3D pipeline: image/text/video → game-ready 3D asset.
#
# Usage:
#   omni3d_drive.sh                  # run the built-in REAL pipeline demo (ends: status passed)
#   omni3d_drive.sh job.json         # POST your own CreatePipelineRequest, run it to completion
#
# Env overrides:
#   OMNI3D_DIR  where the Omni3D repo lives   (default: $HOME/.omni3d/Omni-3d)
#   OMNI3D_URL  clone URL                     (default: https://github.com/Kariimc/Omni-3d.git)
#   PORT        API port                      (default: 8787)
set -euo pipefail

OMNI3D_DIR="${OMNI3D_DIR:-$HOME/.omni3d/Omni-3d}"
OMNI3D_URL="${OMNI3D_URL:-https://github.com/Kariimc/Omni-3d.git}"
PORT="${PORT:-8787}"
BASE="http://127.0.0.1:${PORT}"

# 1. Ensure the repo is present and installed (Node 20+ required; uses tsx, no build step).
if [ ! -d "$OMNI3D_DIR/.git" ]; then
  echo "→ cloning Omni3D into $OMNI3D_DIR"
  mkdir -p "$(dirname "$OMNI3D_DIR")"
  git clone "$OMNI3D_URL" "$OMNI3D_DIR"
fi
cd "$OMNI3D_DIR"
[ -d node_modules ] || { echo "→ npm install"; npm install --no-audit --no-fund; }

# 2. No payload → run the one-shot real pipeline (built-in test artifacts) and stop.
if [ $# -eq 0 ]; then
  echo "→ running built-in real pipeline (npm run pipeline:real)"
  exec npm run pipeline:real
fi

PAYLOAD="$1"
[ -f "$PAYLOAD" ] || { echo "payload not found: $PAYLOAD" >&2; exit 1; }

# 3. Start the API if it isn't already up (track whether we own the process).
OWN_SERVER=0
if ! curl -sf "$BASE/health" >/dev/null 2>&1; then
  echo "→ starting Omni3D API on :$PORT"
  PORT="$PORT" npm start >/tmp/omni3d-server.log 2>&1 &
  OWN_SERVER=$!
  for _ in $(seq 1 40); do curl -sf "$BASE/health" >/dev/null 2>&1 && break; sleep 0.5; done
fi
cleanup(){ [ "$OWN_SERVER" != 0 ] && kill "$OWN_SERVER" 2>/dev/null || true; }
trap cleanup EXIT

# 4. Create the job from your request payload.
JOB=$(curl -s -X POST "$BASE/pipeline" -H 'content-type: application/json' -d @"$PAYLOAD")
JID=$(printf '%s' "$JOB" | python3 -c 'import sys,json;print(json.load(sys.stdin)["jobId"])')
echo "→ job $JID created"

# 5. Advance one stage at a time (A1→A2→A3→B1→B2→C) until it terminates.
for i in $(seq 1 10); do
  OUT=$(curl -s -X POST "$BASE/jobs/$JID/advance")
  S=$(printf '%s' "$OUT" | python3 -c 'import sys,json;d=json.load(sys.stdin);j=d.get("job",d);print(j.get("status"))')
  echo "   advance $i → $S"
  case "$S" in passed|failed|done) break;; esac
done

# 6. Print the final asset manifest (artifact asset:// URIs + loop statuses).
echo "→ final job:"
curl -s "$BASE/jobs/$JID" | python3 -m json.tool
