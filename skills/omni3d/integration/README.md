# Omni3D Integration Kit — engine + Omni3D = one framework

Runs the **complete free pipeline end-to-end**, verified, no GPU: an input image
becomes a 3D solid (the engine), which is then driven through **Omni3D's entire
real pipeline** — retopology → skin-weights → retarget → EITL validation — to a
game-ready, topology-checked, rigged asset. No subscriptions.

## Verified result (no GPU)
```
photo → engine (real-depth solid, 27,460 tris)
      → Omni3D FULL pipeline (realPipeline): A1 frame-sample · A2 voxel ·
        A3 retopology (meshoptimizer) · B1 skin-weights · B2 retarget · C EITL
      → status: passed   (6 stages, 0 EITL repairs, artifact manifest emitted)
```
(`omni_bridge.ts` also confirms the isolated step: 27,460 → 10,000 tris, −64%,
watertight ✓ manifold ✓ 0 bad edges.)

## Run it (one command)
```bash
OMNI3D_DIR=/path/to/Omni-3d  bash make_asset.sh yourphoto.jpg mobile_xr
```
Files:
- `make_asset.sh` — orchestrates: engine (`image → asset.glb`, real depth) →
  `glb_to_json.py` → `pipeline_from_image.ts` (full Omni3D A→C).
- `pipeline_from_image.ts` — **the unification**: runs the engine mesh through the
  whole real pipeline. Drop at the Omni-3d repo root.
- `omni_bridge.ts` — lightweight check (retopology + EITL only).
- `glb_to_json.py` — engine `.glb`/`.obj` → `{positions, indices}` JSON.

## How the fold-in works (already proven; make it permanent)
Omni3D's `StageContext.mesh` is the high-poly mesh that Loop A3 (retopology), B1
(skin) and C (EITL) consume. The integration is literally:
```ts
const ctx = await buildStageContext();
ctx.mesh = engineMesh;            // ← the whole fold-in
await runRealPipeline(job, ctx);
```
To bake it into the runner permanently: give `buildStageContext()` an optional
mesh argument (or add `buildStageContextFromMesh`) and pass the engine mesh from
the `POST /pipeline` handler. Then a single API call does generate → retopo →
rig → validate. Swap the engine's `--model depth` for `--model trellis` on a GPU
and the same pipeline yields top-tier quality — no other change.
