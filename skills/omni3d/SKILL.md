---
name: omni3d
description: >-
  Turn an image, text prompt, or short video into a game-ready 3D asset using
  the Omni3D closed-loop pipeline — sharp-frame sampling → voxel draft → quad
  retopology → auto-rig + skin weights → motion retarget → engine validation,
  live-syncable into Unreal Engine 5 / Unity. Use when the user wants to make a
  3D model/asset from a reference image/video/text, run the Omni3D pipeline,
  retopologize or auto-rig a mesh, or produce a UE5/Unity asset.
metadata:
  origin: authored
  source-repo: https://github.com/Kariimc/Omni-3d
tools: Bash, Read, Write, AskUserQuestion
user-invocable: true
---

# Omni3D — image/text/video → game-ready 3D asset

Drives the **Omni3D** pipeline (the user's repo `Kariimc/Omni-3d`): a
video-native 3D production studio that rebuilds an object in 3D, retopologizes to
a clean quad mesh, auto-rigs it, retargets motion, validates against game-engine
rules, repairs its own defects, and live-syncs into UE5/Unity.

> **What this skill is NOT:** an image generator. Omni3D *consumes* an image (or
> text/video) and *outputs a 3D model*. To generate the input picture first, pair
> with the `skill-radar`/image tools; this skill takes it from input → 3D.

## What actually works today (verified)
Cloned, `npm install` (≈156 pkgs, ~5s), then:
- `npm run pipeline:real` → all **6 real providers** run → `status: passed`.
- REST API: `POST /pipeline` → `201`; six `advance` calls drive A1→A2→A3→B1→B2→C
  → `status: passed`; `GET /jobs/:id` returns the artifact manifest.

The six stages have **real** implementations (classic CV/geometry):
frame blur-scoring (variance of Laplacian), shape-from-silhouette voxel carving,
`meshoptimizer` decimation, bone-heat skin weights, foot-lock IK retarget, and
watertight/manifold EITL checks with an auto micro-repair back-edge.

**Scaffold boundary (be honest with the user):** the deep-learning reconstruction
(NeRF/triplane, GNN joint prediction, WHAM mocap, inverse-render PBR delight) and
the real file upload/download layer are **not yet wired** — artifacts come back as
`asset://…` URIs (a manifest), not finished `.glb/.fbx` files on disk. So today
this is a working, schema-validated, self-correcting pipeline + engine bridge you
can run and build on, not a turnkey photo→AAA-asset button.

## Prerequisites
- **Node 20+** and **npm** (the pipeline runs TypeScript via `tsx`, no build step).
- The Omni3D repo. The driver script clones it on first run.
- Optional: `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` to persist jobs (default store
  is in-memory; nothing to set up for a local run).

## Quick start (one command)
```bash
bash scripts/omni3d_drive.sh
```
Clones + installs Omni3D if needed, then runs the built-in real pipeline and
prints `status: passed | stages: 6`. Use this to confirm everything works.

## Make an asset from your own input
1. Write a request payload (`video` is required; inputs are `asset://` URIs).
   ```json
   {
     "text": "weathered bronze knight statue, glowing blue rune gems",
     "images": ["asset://uploads/ref_front.png"],
     "video": { "uri": "asset://uploads/orbit_pan.mp4", "container": "mp4",
                "durationSec": 12.4, "fps": 30, "resolution": [1920, 1080] },
     "targets": { "engine": "ue5", "unitScale": "cm", "polyBudget": "hero",
                  "humanoid": true, "rigStandard": "ue5_sk_mannequin" },
     "features": { "realPipeline": true }
   }
   ```
2. Run it to completion:
   ```bash
   bash scripts/omni3d_drive.sh job.json
   ```
   The script POSTs the job, advances it stage-by-stage to Loop C, and prints the
   final artifact manifest.

### Or drive the API by hand
```bash
PORT=8787 npm start                                  # in the Omni3D repo
curl -s -XPOST localhost:8787/pipeline -H 'content-type: application/json' -d @job.json   # → 201 + jobId
curl -s -XPOST localhost:8787/jobs/<jobId>/advance   # repeat ×6: A1→A2→A3→B1→B2→C
curl -s localhost:8787/jobs/<jobId>                  # status + artifacts{}
```
Add `?defect=vertex_tear|intersections|manifold` to `advance` to force an EITL
failure and watch the micro-repair loop recover.

## Field reference (valid enum values — strict schema)
| Field | Allowed values |
|---|---|
| `targets.engine` | `ue5` · `unity` · `both` |
| `targets.unitScale` | `cm` (default) · `m` |
| `targets.polyBudget` | `mobile_xr` · `hero` · `nanite` |
| `targets.rigStandard` | `ue5_sk_mannequin` · `unity_humanoid_mecanim` |
| `video.container` | `mp4` · `mov` |
| `features.realPipeline` | `true` = real providers · `false` (default) = synthetic |

## Pipeline stages
```
A1 frame_sampler → A2 voxel_draft → A3 retopology
→ B1 rigging_skinweights → B2 animation_retarget → C eitl_validation
```
Loop C gate: `E = w1·manifold + w2·intersections + w3·vertex_tear`; if `E > T` it
masks the worst site and re-runs Phase 2/3 (the self-repair back-edge).

## Live-sync into a game engine (optional)
```bash
npm run live:client -- <jobId> --url=ws://127.0.0.1:8787
```
Streams typed events (`stage.completed`, `eitl.result`, `asset.push`,
`pipeline.complete`); on pass, the engine bridge imports the mesh + materials
into UE5/Unity at 1 unit = 1 cm.

## Related
- `game-assets` / `game-art` — produce or refine the 2D/3D source art.
- `ar-vr-developer`, `animation-particle-design` — downstream engine work.
- `skill-radar` — find more tools/skills to extend this pipeline.
