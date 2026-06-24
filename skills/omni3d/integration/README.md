# Omni3D Integration Kit — engine + Omni3D = one framework

Proves and runs the **complete free pipeline**: an input image becomes a 3D solid
(the GPU-free engine), which is then **retopologized and validated by Omni3D's own
real providers** — a game-ready, topology-checked asset, no GPU and no
subscriptions.

## Verified result (no GPU)
```
engine star solid  27,460 tris
   → Omni3D retopology (meshoptimizer)  →  10,000 tris  (64% reduction, mobile_xr budget)
   → Omni3D EITL validation             →  watertight ✓  manifold ✓  0 boundary/non-manifold edges
```

## Run it
```bash
OMNI3D_DIR=/path/to/Omni-3d  bash make_asset.sh yourphoto.jpg 5000
```
- `make_asset.sh` — orchestrates: engine (`image → asset.glb`) → `glb_to_json.py`
  → `omni_bridge.ts` (Omni3D retopo + EITL). Needs a Kariimc/Omni-3d checkout with
  `npm install` done, and the engine in `../engine`.
- `omni_bridge.ts` — drop at the Omni-3d repo root; feeds any mesh through Omni3D's
  `simplifyMesh` (Loop A3 retopology) + `analyzeMesh` (Loop C EITL).
- `glb_to_json.py` — engine `.glb/.obj` → `{positions, indices}` JSON.

## How this becomes "fully wired" (the GPU-session task)
This kit calls Omni3D's providers from the outside to prove the data flows. The
final step (for the Omni-3d repo agent) is to fold `omni_bridge.ts` into a real
provider so the **runner's Loop A3 consumes the engine mesh** as its high-poly
input (replacing the synthetic `uvSphere`). Then one `POST /pipeline` runs
generate → retopo → rig → validate end to end. Swap the engine's `relief` model
for `triposr`/`trellis` on a GPU and the same pipeline yields top-tier quality.
