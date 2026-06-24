#!/usr/bin/env bash
# One-time setup for the Omni3D free local generation engine.
# Creates a venv and installs the real-generation deps. A CUDA GPU is needed for
# usable speed; with no GPU you can still run the plumbing via `--backend mock`.
set -euo pipefail
cd "$(dirname "$0")"
PY="${PYTHON:-python3}"

echo "→ creating venv (.venv)"
"$PY" -m venv .venv
# shellcheck disable=SC1091
. .venv/bin/activate
python -m pip install -U pip

echo "→ installing engine deps (default torch is CPU; install a CUDA build for GPU)"
pip install -r requirements.txt

echo "→ preflight:"
python -m omni_engine.preflight || true

cat <<'NEXT'

Done. Next:
  • GPU torch:  pip install torch --index-url https://download.pytorch.org/whl/cu124
  • Image:      python -m omni_engine.cli --backend diffusers image "a bronze knight statue" -o knight.png
  • 3D:         see engine/README.md → "Image → 3D" to install a mesh runner, then
                python -m omni_engine.cli --backend diffusers mesh knight.png -o knight.glb
  • Models download from Hugging Face on first run (set HF_HOME to cache them).
NEXT
