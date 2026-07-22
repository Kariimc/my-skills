# 3d-master-modeler free-upgrades — warm-start handoff

> Paste this whole file as the opening prompt for the next agent. It resumes
> cold with zero briefing. Branch: `claude/3d-modeler-free-upgrades-j6d5q9`
> (open PR #49, NOT merged to master). Read, in the repo:
> `skills/3d-master-modeler/SKILL.md`, this file, `PROGRESS.md` (newest entries),
> `FAILURES.md` F-44/F-45/F-46, `PLAYBOOK.md` P-12/P-13/P-14/P-15/P-16.

You are continuing an established build — free capability upgrades for the
`3d-master-modeler` skill. Do NOT rebuild what's verified. Prove everything with
a rendered image published to a clickable page; talk to Kariim in plain words.

## DONE and VERIFIED this run (do not redo)

- **#1 Environment (image-based) lighting — SKILL Template E, `set_environment()`.**
  `lighting = "studio" | "sunset" | "warehouse" | "overcast"`. Resolves best-first:
  Poly Haven HDRI → **GitHub-mirrored three.js HDRI** → Blender physical sky /
  gradient dome (zero-download). Proven: all 4 presets rendered with REAL skies
  fetched from GitHub, plus procedural fallbacks. Keeps a 3-point rig as fallback.
- **#3 Cinematic finish — SKILL Template F, `enable_dof()` + `cinematic_finish()`.**
  Native camera depth-of-field + a grade/bloom/vignette post-pass (Pillow+numpy).
  Deliberately NOT the compositor (Blender 5.0 removed `scene.node_tree` + the
  Composite node — F-46). Before/after proven.
- **#4 Engine texture-bake set — SKILL Template G, `bake_pbr_set()` +
  `baked_material()`.** Bakes albedo / roughness / metallic / normal / AO + packed
  ORM (R=AO,G=rough,B=metal) into a textured glTF. Both classic bugs fixed &
  proven: square blemishes (overlapping smart-UV → island margin + 8px bake margin,
  F-52) and metal-albedo-black (→ bake Base Color via an EMIT emission pass, F-53).
  Verified: baked render indistinguishable from procedural source, 871 KB .glb,
  clickable proof page. PLAYBOOK P-17.
- **#5 Draft/final tiers — documented in Template G.** EEVEE Next won't init
  headless (no GPU) → tier knob is Cycles samples (16 draft / 128+ final) + texture
  res (512 / 1024–2048). Guidance added; grounded in the verified headless-Cycles
  fallback (P-14). Not a separate template — it's a two-line setting.
- Proof artifacts (clickable): environment lighting page, and "Real Skies +
  Cinematic Finish" page. Demo asset = a metal canister built inline in the
  scratchpad scripts (ephemeral; the reusable code lives in the SKILL templates).

## ENVIRONMENT — this is the CLOUD box, not Kariim's Windows laptop (READ THIS)

- Bare Linux container. **Blender = `pip install bpy==5.0.1`** (Blender 5.0,
  needs CPython 3.11). Run scripts as plain `python3 script.py` — `import bpy`
  works directly; do NOT use `blender --background` (there's no blender binary,
  and blender.org is network-blocked). Installed already: bpy 5.0.1, trimesh,
  manifold3d, numpy, Pillow, huggingface_hub.
- **Network = GitHub + package-registries ONLY.** Probed: example.com BLOCKED;
  github.com / raw.githubusercontent.com / pypi.org = 200. Asset CDNs (Poly Haven,
  ambientCG, blender.org, huggingface.co) all 403. So: pull assets from **GitHub
  mirrors** (three.js ships CC0 HDRIs at
  `raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/equirectangular/`).
  PROBE hosts before assuming (PLAYBOOK P-16). Read `/root/.ccr/README.md` +
  `curl -sS "$HTTPS_PROXY/__agentproxy/status"` for the live policy. On Kariim's
  laptop the network is open and Poly Haven works directly.
- **Blender 5.0 API gotchas:** sky enum is `MULTIPLE_SCATTERING` not `'NISHITA'`
  (F-44); compositor reworked, use a post-pass not `scene.node_tree` (F-46);
  Principled sockets use the 4.x+/5.x names via the `set_input` resolver.
- **Perf:** 4 CPU cores, ~38 s/frame at 768px / 80 Cycles samples. EEVEE Next
  won't init headless (no GPU) → falls back to Cycles; for "draft" use low-sample
  Cycles. Batches exceed the 120 s foreground limit → run renders in background.
- **Bash guard:** no multi-statement quoted commands (`a; b`) — write a script
  file and run `bash file.sh`, or use one statement per call.

## REMAINING upgrades (priority order) — all free, all runnable here except #6

2. **Fetchers.** Generalise `_real_hdri` into asset/material/model fetchers:
   textures + models + HDRIs, ambientCG as a second source, and **prefer GitHub
   mirrors in restricted envs** (that's the working channel here). Cache under a
   local `textures/`/`assets/`; never commit binaries.
3. ~~Cinematic finish~~ **DONE** (Template F).
4. ~~Full engine texture-bake set~~ **DONE** (Template G, F-52/F-53, P-17).
5. ~~Draft/final tiers~~ **DONE** — documented in Template G (Cycles samples + res).
6. **Photo/text → 3D.** Wire the sibling `omni3d` skill (AI image-to-3D). Needs a
   GPU + multi-GB models — DEFER to Kariim's GPU / cloud; document + wire only.
7. **Effects/sim** (Mantaflow smoke/fire, cloth, rigid-body) — short shots only
   on CPU; document that large sims want the cloud path.
8. **Rig & animate** — pair `game-assets` + `blender-motion-state-inspection`;
   Rigify auto-rig, export glTF animation.
9. **Procedural detail & variation** — Geometry Nodes scatter/greebles + a
   wear/colour/panel variation generator (one asset → a family).

## DO NOT build (paid) — leave the path
Cloud-GPU rendering costs money → needs Kariim's explicit yes. Keep a
"Cloud GPU render — deferred" note in the skill: what it unlocks (fast renders,
heavy scenes, Unreal), the shape (ship the scene to a rented GPU / render service,
pull the result back), revisit trigger: "Enable when Kariim approves a cloud-GPU
budget." Document only.

## Guardrails (Kariim's standing rules)
Prove everything with a rendered image on a clickable page — never claim done
without the picture. Plain words, no jargon/paths in chat. Ask before installing
(name what/where/size). Surgical edits; pin verified version facts. Ship through
the apex gates (they run + pass automatically on commit), push to the branch,
PR #49 is already open (direct commits to master need Kariim's explicit yes).
Feed the ledgers same-turn: dead road → FAILURES.md, reusable method →
PLAYBOOK.md; keep `~/.claude/FAILURES.md` + `~/.claude/PLAYBOOK.md` in sync.
Update PROGRESS.md at the end.

## Definition of done (each upgrade)
Written into the skill as guidance + a verified template, execution-run on a real
asset, proof published to a clickable page, committed through the gates, pushed to
the branch. Kariim should be able to ask for the capability and have it just work.
