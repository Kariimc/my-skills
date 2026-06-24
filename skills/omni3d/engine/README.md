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

## Image → 3D (install one runner)
The image backend ships ready; the 3D step needs the chosen model's runner:
- **TRELLIS** (MIT, best): `pip install git+https://github.com/microsoft/TRELLIS.git` + its CUDA extras.
- **Hunyuan3D-2** (free self-host): clone `Tencent/Hunyuan3D-2`, install its requirements.
- **TripoSR** (MIT, ~6GB, fast): `pip install git+https://github.com/VAST-AI-Research/TripoSR.git`.

Then the `mesh` command routes to it. (The `diffusers` backend currently raises a
clear error for `mesh` until a runner is wired — tracked in the skill's roadmap.)

## Design (so it's testable + swappable)
- `omni_engine/backends/base.py` — `Backend` contract (`generate_image`, `image_to_3d`).
- `backends/mock.py` — zero-dependency backend that writes valid PNG/OBJ (used by tests + CPU dry-runs).
- `backends/diffusers_backend.py` — real image generation (torch/diffusers, lazy-imported).
- `config.py` — model registry + VRAM auto-selection (licenses noted).
- `preflight.py` — environment doctor.
- `cli.py` — `image` / `mesh` commands.
- `tests/` — GPU-free plumbing tests (PNG validity, OBJ geometry, auto-select, import-without-torch).

## Licensing
Defaults are permissive (Apache-2.0 / MIT) so output is yours to use. `sdxl-turbo`
is non-commercial; some 3D models have community terms. **Verify the license of
whatever model you run** — terms change.
