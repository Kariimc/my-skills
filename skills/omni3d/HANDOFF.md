# Omni3D — Handoff Brief (continue the self-hosted free-generation build)

Paste this as the first message to the agent in the **Omni-3d** repo session.

---

**GOAL:** Make Omni3D a complete, self-hosted generator (text/image/video →
image + 3D) using **free open-source models on my own GPU**, so I stop paying
subscriptions. Unlimited runs, high-quality output. No paid APIs.

**ALREADY BUILT** — a self-contained Python engine lives in the
`Kariimc/my-skills` repo at `skills/omni3d/engine/` (branch
`claude/friendly-ramanujan-2n9ojl`, or `master` if merged). Fetch it and copy it
into this repo (e.g. `./generation/`). It contains the package `omni_engine`:
- **text→image** backend via `diffusers` — FLUX.1-schnell (Apache-2.0) default,
  SDXL / SD1.5 fallbacks, model auto-selected by VRAM.
- **MockBackend** (zero dependencies) that writes valid PNG/OBJ — lets the whole
  pipeline be tested with no GPU. All GPU-free unit tests pass.
- `preflight.py` (env/VRAM doctor), `cli.py` (`image` / `mesh`), `config.py`
  (model registry + licenses), `tests/` (green).
- **image→3D is scaffolded but NOT wired** — the `mesh` command raises
  `NotImplementedError` in the real backend. That's your main job.

**YOUR TASKS (in order):**
1. Copy `skills/omni3d/engine/` into this repo. Confirm green:
   `cd generation && python -m unittest discover -s tests` and
   `python -m omni_engine.preflight` (note the GPU/VRAM it reports).
2. Implement **image→3D**. Recommended model: **TRELLIS** (MIT) —
   `pip install git+https://github.com/microsoft/TRELLIS.git`. Implement
   `image_to_3d()` to load TRELLIS and export a real `.glb`. Add a **TripoSR**
   (MIT, ~6GB) fallback for smaller GPUs. Keep MockBackend tests passing.
3. Wire the engine into Omni3D's TS pipeline (`src/loops/providers/`,
   `src/loops/real-providers.ts`): the real providers should shell out to the
   Python engine and consume the real output files. When input is text-only,
   first run `omni_engine image` to create the reference picture, then
   `image_to_3d` to make the mesh that A3 retopology / B rigging / C validation
   operate on.
4. Replace the placeholder `asset://…` artifact URIs with **real on-disk file
   paths**, so `npm run pipeline:real` writes an actual `image.png` + `model.glb`
   and the API's `artifacts{}` points to them.
5. Verify on my GPU: generate an image, generate a 3D model, run a full job end
   to end. Report the model + VRAM used, the quality, and anything still
   synthetic. Be honest.

**PRINCIPLES:**
- Prefer permissive licenses (Apache-2.0 / MIT); flag any non-commercial model.
- High quality needs a CUDA GPU — that's expected and fine.
- Don't break Omni3D's existing 6 real providers (they already pass
  `npm run pipeline:real`).
- Work on a feature branch; show me before merging to `main`.

**MY HARDWARE:** <fill in — e.g. "RTX 4090, 24GB VRAM" or "no GPU yet, will rent">

---
