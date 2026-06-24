# Omni3D — Master Handoff (self-hosted free generation)

Paste this as the first message in the **Omni-3d** repo session. Current state of
the whole build.

---

## GOAL
Self-hosted generator (image/text/video → image + 3D) on free open-source models,
so the user stops paying subscriptions. **Current decision:** take the **free,
no-GPU tier to its best ("apex")** now; keep the GPU/high-quality path wired for
later.

## WHERE THE CODE IS
All committed on **`master` of `github.com/Kariimc/my-skills`** under
`skills/omni3d/`. Fetch into this Omni-3d repo (clone my-skills or copy subtree):
- `engine/`        → the free generation engine (`omni_engine` Python pkg)
- `integration/`   → verified bridge: engine mesh → Omni3D retopo + EITL
- `SKILL.md`, `scripts/omni3d_drive.sh`

## ✅ VERIFIED WORKING (free, no GPU)
1. **Omni3D core**: `npm install`; `npm run pipeline:real` → 6 stages, `passed`.
   REST: `POST /pipeline` → 201; 6× advance → passed; artifacts returned.
2. **Image → 3D, REAL DEPTH (apex)**: `--model depth` runs **MiDaS small** (MIT,
   weights from GitHub releases) on CPU (~4s) → a **watertight, textured solid
   `.glb`** shaped by real depth. Verified via the engine CLI
   (`[mesh] generated with depth`). Falls back to luminance `relief` if torch
   absent. `relief` also gives a watertight subject-isolated solid.
   ```
   cd engine && python -m omni_engine.preflight
   python -m omni_engine.cli --backend real mesh photo.png --model depth -o model.glb
   ```
3. **Full pipeline end-to-end** (engine → Omni3D real retopo + EITL):
   `OMNI3D_DIR=. bash integration/make_asset.sh photo.png 5000`
   Verified: star → 27,460 tris → meshoptimizer retopo 10,000 tris (−64%) →
   EITL watertight ✓ manifold ✓ 0 bad edges.
- **10/10 unit tests pass** (`python -m unittest discover -s engine/tests`).

## 🔌 WIRED, NEEDS GPU (the future high-quality tier — keep it)
- `backends/diffusers_backend.py` — text→image (FLUX/SDXL). Logic unit-tested.
- `backends/mesh.py` — `triposr`/`trellis` runners (real API), auto-fallback to
  depth→relief. On a GPU box: `bash engine/setup.sh` → `preflight` picks by VRAM →
  `--backend diffusers image "..."` and `--model trellis`. One flag, same pipeline.

## ⚠️ ENVIRONMENT FACTS (cloud sandbox)
- **Blocked**: huggingface.co, hf-mirror.com, modelscope.cn, pytorch CPU index
  (no GPU, no HF model downloads).
- **Reachable**: PyPI (`pip install` incl. torch, trimesh, scipy, timm) and
  **GitHub release assets** (MiDaS weights download fine — that's how depth works).
- Download large files with `curl` + size/zip verify; torch.hub's downloader
  truncates ~80MB files behind the proxy (depth.py already does this).

## 📋 TASKS FOR THIS SESSION (ordered)
1. Pull `engine/` + `integration/` from my-skills. Confirm green:
   `python -m unittest discover -s engine/tests` (10 ok); `python -m
   omni_engine.preflight`.
2. **UNIFY THE PIPELINE (main remaining work)**: fold `integration/omni_bridge.ts`
   into a real provider so the runner's **Loop A3 consumes the engine mesh** as
   its high-poly input (replace synthetic `uvSphere` in
   `src/loops/providers/retopology.ts`). Then one `POST /pipeline` / `pipeline:real`
   does generate→retopo→rig→validate on REAL geometry. Keep the 6 real providers
   green. (`omni_bridge.ts` already proves `simplifyMesh` + `analyzeMesh` accept
   the engine mesh.)
3. **Further apex free-tier polish (optional)**: cleaner cutouts (rembg, GitHub
   weights), denser/smoother depth meshes, batch mode.
4. **Future GPU**: leave `diffusers` + `trellis`/`triposr` wired and documented;
   swapping the model is one flag, pipeline unchanged.

## VERIFY
- Engine: `python -m unittest discover -s engine/tests` → 10 ok.
- Real depth 3D: `--model depth` (above) → `[mesh] generated with depth`, watertight GLB.
- Free pipeline: `make_asset.sh` → retopo + EITL report.
- Omni3D core: `npm run pipeline:real` → `status: passed`.

## MY HARDWARE: no GPU for now (free tier focus)
---
