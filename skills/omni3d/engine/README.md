# Omni3D Free Local Generation Engine

Replace paid image/3D subscriptions with **open-source models running on your own
GPU** — unlimited generation, no per-asset cost. This engine is the "generation"
layer; Omni3D itself does the downstream work (retopology, auto-rig, validation,
UE5/Unity live-sync).

> **The honest deal:** "unlimited + free + high quality" means you supply the
> compute. These models need a CUDA GPU for usable speed and quality. No GPU? The
> `mock` backend still exercises the whole pipeline so you can wire/test it, and
> you can rent a GPU by the hour far cheaper than most subscriptions.

## What it does
| Command | Input → Output | Default model | License |
|---|---|---|---|
| `image` | text → PNG | FLUX.1-schnell (≥12GB) | Apache-2.0 — free, commercial OK |
| `mesh`  | image → GLB/OBJ | TRELLIS / Hunyuan3D / TripoSR | MIT / community |

Model is auto-picked from your VRAM (`preflight` shows the choice); override with
`--model`.

## Quick start
```bash
# 0. (no GPU needed) prove the plumbing works — writes a real PNG + OBJ
python -m omni_engine.cli --backend mock image "a bronze knight" -o knight.png
python -m unittest discover -s tests

# 1. install real deps (GPU machine)
bash setup.sh
python -m omni_engine.preflight          # checks GPU/VRAM, recommends models

# 2. generate for real
python -m omni_engine.cli --backend diffusers image "weathered bronze knight statue, rune gems" -o knight.png
python -m omni_engine.cli --backend diffusers mesh knight.png -o knight.glb
```

## Hardware → model guide
| VRAM | Image model | 3D model | Notes |
|---|---|---|---|
| 24GB+ | flux-schnell | trellis | best quality |
| 12–16GB | flux-schnell / sdxl | hunyuan3d | strong, mainstream |
| 8GB | sdxl | triposr | good |
| 6GB | sdxl-turbo | triposr | fast/light |
| <6GB / none | use `--backend mock` | — | plumbing only |

## Image → 3D (two quality tiers, with automatic fallback)
`mesh` always produces a real file. It tries your chosen GPU model, then falls
back to the GPU-free baseline:

- **`depth` (apex no-GPU — VERIFIED here):** real monocular **depth** (MiDaS
  small, MIT, weights from GitHub releases) drives the geometry, so the solid
  takes the subject's true shape — not just brightness. CPU-only, free,
  unlimited. First run downloads ~85MB; needs `torch` + `timm`. Falls back to
  luminance if unavailable.
- **`relief` (no-GPU fallback):** luminance height field → the image into a real
  **watertight, textured SOLID** `.glb` (front relief + flat back + walls), or a
  textured `.obj` surface. Needs only Pillow + numpy (+ trimesh + scipy for `.glb`).
- **`triposr` (MIT, ~6GB GPU):** full single-image→mesh. `pip install
  git+https://github.com/VAST-AI-Research/TripoSR.git`.
- **`trellis` (MIT, best, CUDA GPU):** top-tier. `pip install
  git+https://github.com/microsoft/TRELLIS.git` (+ extras).

```bash
python -m omni_engine.cli --backend real mesh knight.png --model depth   -o knight.glb   # apex no-GPU (real depth)
python -m omni_engine.cli --backend real mesh knight.png --model relief  -o knight.obj   # luminance fallback, any machine
python -m omni_engine.cli --backend real mesh knight.png --model triposr -o knight.glb   # GPU; auto-falls back to depth/relief
```
`--model auto` tries triposr → trellis → **depth** → relief, so a CPU machine
gets real depth-based 3D automatically. GPU runners are real integration code
(verify on hardware); the `depth` and `relief` paths are verified in this repo.

## Design (so it's testable + swappable)
- `omni_engine/backends/base.py` — `Backend` contract (`generate_image`, `image_to_3d`).
- `backends/mock.py` — zero-dependency backend that writes valid PNG/OBJ (used by tests + CPU dry-runs).
- `backends/diffusers_backend.py` — real image generation (torch/diffusers, lazy-imported).
- `backends/relief_backend.py` — real GPU-free image→3D (textured relief mesh).
- `backends/mesh.py` — image→3D orchestrator: TripoSR/TRELLIS → relief fallback.
- `config.py` — model registry + VRAM auto-selection (licenses noted).
- `preflight.py` — environment doctor.
- `cli.py` — `image` / `mesh` commands.
- `tests/` — GPU-free plumbing tests (PNG validity, OBJ geometry, auto-select, import-without-torch).

## Verification status
Verified here (GPU-free):
- ✅ image→3D `depth` (MiDaS) → real **depth-based watertight textured solid GLB**
  through the engine CLI (`[mesh] generated with depth`), CPU-only, ~4s inference.
- ✅ image→3D `relief` → watertight textured solid GLB (subject-isolated) + OBJ.
- ✅ DiffusersBackend request logic (FLUX guidance=0, SDXL negatives, seed).
- ✅ mock plumbing, VRAM auto-select, depth wiring — **10/10 unit tests pass**.

Needs your hardware (cannot run in a GPU-less, download-restricted sandbox):
- ⏳ real diffusion image weights + TRELLIS/TripoSR meshing — require a CUDA GPU
  **and** Hugging Face model downloads. Run `setup.sh` then `preflight` on your
  box; the code paths are in place.

## Licensing
Defaults are permissive (Apache-2.0 / MIT) so output is yours to use. `sdxl-turbo`
is non-commercial; some 3D models have community terms. **Verify the license of
whatever model you run** — terms change.
