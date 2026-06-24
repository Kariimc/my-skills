# Omni3D — Master Handoff (self-hosted free generation)

Paste this as the first message in the **Omni-3d** repo session. It is the
complete, current state of the build.

---

## GOAL
Make Omni3D a self-hosted generator (text/image/video → image + 3D) on free
open-source models, so the user stops paying subscriptions. **Decision (current):**
take the **free, no-GPU tier to its best ("apex")** now; keep the GPU/high-quality
path wired for the future.

## WHERE THE CODE IS
All of it is committed on **`master` of `github.com/Kariimc/my-skills`** under
`skills/omni3d/`. Fetch it into this Omni-3d repo (clone my-skills or copy the
subtree). Layout:
- `skills/omni3d/SKILL.md` — how to drive the Omni3D pipeline (verified).
- `skills/omni3d/engine/` — **the free generation engine** (`omni_engine` Python pkg).
- `skills/omni3d/integration/` — **verified bridge** engine→Omni3D (retopo+EITL).
- `skills/omni3d/scripts/omni3d_drive.sh` — drives Omni3D's REST pipeline.

## ✅ VERIFIED WORKING (free, no GPU, on master)
1. **Omni3D pipeline itself**: `npm install` (156 pkgs), `npm run pipeline:real`
   → 6 stages, `status: passed`. REST API: `POST /pipeline` → 201, 6× advance →
   passed, artifacts returned.
2. **Engine image→3D (`relief`)**: image → **watertight, subject-isolated,
   textured SOLID `.glb`**. Verified (star: 27,460 tris, watertight, bbox-fill
   0.33 = object-shaped, not a slab). 9/9 unit tests pass.
   ```
   cd skills/omni3d/engine
   python -m omni_engine.preflight
   python -m omni_engine.cli --backend real mesh photo.png --model relief -o model.glb
   ```
3. **Integration (engine → Omni3D)**: `skills/omni3d/integration/make_asset.sh`
   runs the COMPLETE free pipeline end-to-end. Verified:
   `star → engine 27,460 tris → Omni3D meshoptimizer retopo 10,000 tris (−64%) →
   Omni3D EITL: watertight ✓ manifold ✓ 0 boundary/non-manifold edges`.
   ```
   OMNI3D_DIR=/path/to/Omni-3d bash skills/omni3d/integration/make_asset.sh photo.png 5000
   ```

## 🔌 WIRED, NEEDS GPU (the future high-quality path — keep it)
- `omni_engine/backends/diffusers_backend.py` — text→image (FLUX.1-schnell /
  SDXL). Logic unit-tested (FLUX guidance=0, SDXL negatives, seed). Needs CUDA + HF.
- `omni_engine/backends/mesh.py` — `triposr` / `trellis` runners (real API code),
  auto-fallback to `relief`. Need CUDA + their pip installs.
- On a GPU box: `bash skills/omni3d/engine/setup.sh` → `preflight` auto-selects by
  VRAM → `--backend diffusers image "..."` and `--model trellis` just work.

## ⚠️ ENVIRONMENT FACTS (learned the hard way in the cloud sandbox)
- **Blocked** (firewall): huggingface.co, hf-mirror.com, modelscope.cn,
  download.pytorch.org CPU index. → no model-weight downloads, no GPU.
- **Reachable**: PyPI (`pip install` works incl. torch CUDA wheel, trimesh, scipy,
  timm), and **GitHub release assets** (e.g. MiDaS weights download fine, 85MB, 200).
- So in THIS cloud box only no-download / classical-CV models run. A real GPU box
  removes both limits.

## 🚧 IN PROGRESS — "apex free tier" via real depth (MiDaS)
Goal: replace the relief's luminance height field with **real monocular depth**
(MiDaS small) for genuinely 3D geometry, CPU-only, free. Weights ARE reachable
(GitHub releases). Blocker hit: `torch.hub.load("isl-org/MiDaS","MiDaS_small")`
tries to pull the EfficientNet backbone from `rwightman/gen-efficientnet-pytorch`
and prompts interactively (`EOFError` in non-TTY).
**Recommended fix (build direct, no backbone download):**
```python
# MiDaS repo already cached at <torchhub>/hub/isl-org_MiDaS_master
import sys, torch, numpy as np; from PIL import Image
sys.path.insert(0, MIDAS_REPO)
from midas.midas_net_custom import MidasNet_small
m = MidasNet_small(None, features=64, backbone="efficientnet_lite3",
                   exportable=True, non_negative=True, blocks={'expand': True})
# path=None ⇒ use_pretrained=False ⇒ NO backbone download; then load the real ckpt:
ckpt = "https://github.com/isl-org/MiDaS/releases/download/v2_1/midas_v21_small_256.pt"
m.load_state_dict(torch.hub.load_state_dict_from_url(ckpt, map_location="cpu")); m.eval()
# preprocess 256×256, ImageNet-normalize → m(x) → inverse depth → use as height field
```
Then feed that depth into `ReliefBackend` (new `--model depth`) and keep the
luminance path as fallback. Add a test that's skipped when torch/MiDaS absent.

## 📋 TASKS FOR THIS SESSION (ordered)
1. Pull `skills/omni3d/{engine,integration}` from my-skills into this repo.
   Confirm green: `cd engine && python -m unittest discover -s tests` (9/9),
   `python -m omni_engine.preflight`.
2. **Unify the pipeline**: fold `integration/omni_bridge.ts` into a real provider
   so the runner's **Loop A3 consumes the engine mesh** as its high-poly input
   (replace the synthetic `uvSphere` in `src/loops/providers/retopology.ts`).
   Then one `POST /pipeline` (or `pipeline:real`) does generate→retopo→rig→validate
   with REAL geometry. Keep the existing 6 real providers passing.
3. **Apex free tier**: finish the MiDaS depth integration above → much better
   no-GPU geometry. Optional: cleaner cutouts (rembg, GitHub-hosted weights),
   denser/smoother meshes.
4. **Future GPU path** (leave wired, document): on a GPU, `--backend diffusers`
   images + `--model trellis` 3D; swap is one flag, pipeline unchanged.

## VERIFY ANYTHING
- Engine: `python -m unittest discover -s skills/omni3d/engine/tests` → 9 ok.
- Free pipeline: `make_asset.sh` (above) → watertight retopo report.
- Omni3D core: `npm run pipeline:real` in the Omni-3d repo → `status: passed`.

## MY HARDWARE: <fill in — "no GPU for now" / "RTX 4090 24GB" / "will rent">
---
