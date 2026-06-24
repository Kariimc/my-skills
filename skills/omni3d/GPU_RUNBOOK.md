# Omni3D — GPU Runbook (the "extremely high quality" tier)

The free tier (real-depth 3D) runs anywhere. The **top quality** tier — FLUX/SDXL
images + TRELLIS 3D — needs a CUDA GPU and the ability to download model weights
(this cloud sandbox blocks both). Everything is already wired; this is the whole
job once you're on a GPU.

## 1. Get a GPU (cheaper than the subscriptions you're dropping)
- **Own NVIDIA card?** 8GB+ works (12–24GB ideal). Skip to step 2.
- **Rent by the hour** (no commitment): RunPod, Vast.ai, or Lambda. A 24GB card
  (RTX 4090 / A5000) is ~$0.30–0.80/hr. One hour generates a LOT of assets.
  Pick a template with **CUDA 12 + PyTorch** preinstalled.

## 2. Install (one time, ~5–10 min)
```bash
git clone https://github.com/Kariimc/my-skills
cd my-skills/skills/omni3d/engine
bash setup.sh                     # installs CUDA torch + diffusers + deps
python -m omni_engine.preflight   # detects your GPU + VRAM, auto-picks free models
```
`preflight` tells you which models fit your card — no decision needed.

## 3. Generate — IMAGES (replaces Midjourney/DALL·E, unlimited, free)
```bash
python -m omni_engine.cli --backend diffusers image \
  "a weathered bronze knight statue, studio lighting, 8k" -o knight.png
```
- 24GB → FLUX.1-schnell (Apache-2.0, top quality). 8–12GB → SDXL. preflight chooses.

## 4. Generate — 3D MODELS (replaces Meshy/Tripo, unlimited, free)
```bash
pip install git+https://github.com/microsoft/TRELLIS.git    # MIT, best; or TripoSR for smaller GPUs
python -m omni_engine.cli --backend real mesh knight.png --model trellis -o knight.glb
```
First run downloads the model weights (works fine on a normal network — only this
sandbox blocked it).

## 5. Full unified pipeline (generate → retopo → rig → validate)
With a checkout of `Kariimc/Omni-3d` (npm install done):
```bash
OMNI3D_DIR=/path/to/Omni-3d \
  bash ../integration/make_asset.sh knight.png hero
```
Same pipeline you already verified on the free tier — just higher-quality input
geometry because `--model trellis` replaces `--model depth`. One flag is the only
difference.

## VRAM → model cheat sheet
| VRAM | Images | 3D |
|------|--------|----|
| 24GB+ | FLUX.1-schnell | TRELLIS |
| 12–16GB | SDXL | TRELLIS (or TripoSR) |
| 8GB | SDXL (512) | TripoSR |
| none | (use depth tier) | `--model depth` (free, CPU) |

## Cost reality
A typical image/3D subscription is $20–60/month. A rented 24GB GPU is ~$0.50/hr —
so a few hours a month of *unlimited* generation, and you own the output with no
per-asset fees or license traps. Stop the instance when done; pay only for runtime.

When you're on the box, run steps 2–4 and ping me — I'll drive it and finish the
Omni-3d fold-in live.
