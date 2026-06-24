#!/usr/bin/env bash
# Reproduce the plush-and-buttons asset set end-to-end, GPU-free.
#
#   refs (PIL procedural)  ->  omni_engine relief mesher  ->  watertight textured .glb  ->  3D previews
#
# Usage:  bash build.sh
# Env:    PYBIN  python to use (default: ../../engine venv if present, else python3)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ENGINE="$(cd "$HERE/../../engine" && pwd)"

# pick an interpreter that has Pillow/numpy/trimesh/scipy/matplotlib
PYBIN="${PYBIN:-}"
if [ -z "$PYBIN" ]; then
  for cand in "$HOME/.omni3d-venv/bin/python" "$ENGINE/.venv/bin/python" python3; do
    if "$cand" -c "import numpy,PIL,trimesh,scipy" 2>/dev/null; then PYBIN="$cand"; break; fi
  done
fi
[ -n "$PYBIN" ] || { echo "no python with deps; run: pip install Pillow numpy trimesh scipy matplotlib" >&2; exit 1; }
echo "→ using $PYBIN"

echo "→ 1/3 render references"
"$PYBIN" "$HERE/build_refs.py" "$HERE/refs"

echo "→ 2/3 mesh each reference into a watertight textured .glb"
mkdir -p "$HERE/assets"
for ref in "$HERE"/refs/*.png; do
  name="$(basename "${ref%.png}")"
  ( cd "$ENGINE" && "$PYBIN" -m omni_engine.cli --backend real mesh "$ref" \
      -o "$HERE/assets/$name.glb" --model relief )
done

echo "→ 3/3 render 3D previews + contact sheet"
"$PYBIN" "$HERE/preview.py" "$HERE/refs" "$HERE/previews"

echo "✓ done — assets in ./assets, previews in ./previews"
