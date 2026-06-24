#!/usr/bin/env bash
# Complete FREE pipeline (no GPU): image → 3D solid (engine) → Omni3D retopo + EITL.
# Proves engine + Omni3D work as ONE framework.
#
# Usage:  OMNI3D_DIR=/path/to/Omni-3d  make_asset.sh <image> [polyBudgetQuads=5000]
# Env:    OMNI3D_DIR  (required) a checkout of Kariimc/Omni-3d with `npm install` done
#         ENGINE_DIR  (default: ../engine) the free generation engine
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="${ENGINE_DIR:-$HERE/../engine}"
: "${OMNI3D_DIR:?set OMNI3D_DIR to your Omni-3d checkout (npm install done)}"
IMG="${1:?usage: make_asset.sh <image> [mobile_xr|hero|nanite]}"
BUDGET="${2:-mobile_xr}"      # polyBudget preset
WORK="$(mktemp -d)"

echo "→ [1/3] engine: image → watertight solid GLB (no GPU)"
( cd "$ENGINE_DIR" && python3 -m omni_engine.cli --backend real mesh "$IMG" --model relief -o "$WORK/asset.glb" )

echo "→ [2/3] export mesh → json"
python3 "$HERE/glb_to_json.py" "$WORK/asset.glb" "$WORK/mesh.json"

echo "→ [3/3] Omni3D: FULL real pipeline (retopo → skin-weights → retarget → EITL)"
cp "$HERE/pipeline_from_image.ts" "$HERE/omni_bridge.ts" "$OMNI3D_DIR/"
( cd "$OMNI3D_DIR" && ./node_modules/.bin/tsx pipeline_from_image.ts "$WORK/mesh.json" "$BUDGET" )

echo "→ game-ready asset: $WORK/asset.glb"
