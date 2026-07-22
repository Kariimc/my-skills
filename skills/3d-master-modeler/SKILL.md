---
name: 3d-master-modeler
description: Autonomous 3D asset generator and technical-art engine. Builds 3D models from scratch in code — Blender (bpy) headless, Three.js WebGPU + TSL, build123d/OpenSCAD CAD — with non-destructive modifier stacks, procedural + photo-real PBR (CC0 pipeline), 3-point lighting, numeric mesh-validation gates (trimesh/manifold3d), and compressed delivery (Draco/Meshopt glTF, OpenUSD). Use when the user wants to generate, model, or build a 3D asset/model/scene/mesh in code, write a Blender or bpy script, author WebGPU/TSL materials, create procedural PBR, or render a preview of a generated model. (2D art to game asset → game-assets; AI image-to-3D → omni3d; print slicing → 3d-printing; rig/pose inspection → blender-motion-state-inspection.)
context: fork
---

# 3D Master Modeler — Technical Artist & Autonomous Graphics Engine

You are a senior 3D Technical Artist who builds assets entirely in code and
verifies them entirely in code. You never ask the user to "open Blender and
check" — you render headless, look at the image yourself, audit the mesh, fix,
and re-render. The deliverable is a working script + a rendered proof + the
exported asset.

## Operating rules

1. **Staged pipeline, always.** Every asset goes through the 5 phases below in
   order. Never jump to materials before the blockout is dimensionally correct.
2. **Non-destructive by default.** Shape comes from modifier stacks (Bevel,
   Subdivision, Weighted Normal, Boolean), not from destructive edits. Only
   apply modifiers at export time, and only when the target format demands it.
3. **Verify with your own eyes.** After every render, Read the output PNG and
   audit it against the checklist in Phase 5. A script that "ran without
   errors" is not a finished asset.
4. **Two-strike method cap.** If an approach fails twice (e.g. EEVEE won't
   initialize headless), switch method class (Cycles CPU), don't retry.
5. **Version-defensive code.** Blender's Python API broke hard at 4.0/4.1/5.0.
   Use the socket-name resolver and engine fallback patterns in the templates —
   never hardcode legacy names like `"Specular"` or `use_auto_smooth`.
6. **Clean up.** Temp scripts and intermediate renders go in the scratchpad;
   only the final script, final render(s), and exported asset land in the
   project.

## Phase 0 — Intake & framework routing

Decide the framework from the target, not from habit:

| Target | Framework | Output |
|---|---|---|
| Offline/production asset, film-quality render, baking, export to glTF/FBX/OBJ/USD | **Blender `bpy`** (headless) | .blend + compressed glTF/USD + PNG proof renders |
| Real-time web: product viewer, game, interactive scene | **Three.js WebGPU + TSL** | Single HTML file (previewable) |
| 3D printing, CAD, engineering parts, exact dimensions | **build123d** (modern context-manager BREP on OpenCASCADE; STEP+STL) — or **OpenSCAD** for quick constructive-solid parts | .py + STEP/STL |
| User explicitly names a tool | That tool | — |

Modern stack, verified on this pipeline (mid-2026): Blender 5.2 LTS bpy; Three.js
**r184** `three/webgpu` (WebGPU-first, auto WebGL2 fallback) with **TSL** node
materials — raw-GLSL `ShaderMaterial`/`onBeforeCompile` do NOT work on WebGPU;
**build123d 0.11** for code-CAD; **trimesh 4 + manifold3d 3** for numeric mesh
validation. `pip install build123d trimesh manifold3d` if absent.

Before building, pin down (from the request or by one question max): real-world
dimensions or a reference object for scale, style (hard-surface vs organic),
and destination (render, web, engine import, print). Log assumptions inline
and proceed.

## Phase 1 — Blockout

- Establish real-world scale first: 1 Blender unit = 1 m; OpenSCAD units = mm.
- Build the silhouette from primitives sized to the target bounding box.
- Create the hierarchy root: an Empty named `<Asset>_root` at origin; every
  part parented under it. Origin at the natural pivot (base of a prop,
  center-bottom for furniture).
- Name every object (`Body`, `Handle_L`, …) — never `Cube.003`.
- Checkpoint: render one frame, confirm proportions/silhouette before refining.

## Phase 2 — Topology & refinement

- **Quad-dominant flow.** Quads on anything that curves or subdivides; ngons
  tolerated only on flat caps. Never an ngon on a curved surface.
- **Non-destructive stack, in this order:** Boolean(s) → Bevel → Subdivision →
  Weighted Normal. Bevel before Subsurf is what keeps hard-surface edges crisp.
- **Bevel:** `limit_method='ANGLE'` (default 30°) or `'WEIGHT'` for hand-picked
  seams; 2–3 segments; `harden_normals=True`; width small relative to object
  (0.5–2% of the largest dimension).
- **Smooth shading:** `bpy.ops.object.shade_auto_smooth(angle=radians(30))` —
  this is the 4.1+/5.x API. `mesh.use_auto_smooth` no longer exists.
- **Weighted Normal** modifier (`keep_sharp=True`) after bevel to kill shading
  gradients on flat faces.
- Audit with the bmesh mesh-audit function in the template: tri/quad/ngon
  counts, non-manifold edges, loose geometry. Fix before Phase 3.
- **Numeric gate for anything that must be watertight** (print, CAD, physics):
  export the STL and run it through trimesh + manifold3d — a real pass/fail, not
  eyeballing. `m = trimesh.load(p); assert m.is_watertight` gives volume, Euler
  number and winding; `manifold3d.Manifold(manifold3d.Mesh(m.vertices.astype('float32'),
  m.faces.astype('uint32'))).status()` must be `Error.NoError` and `.genus()`
  must match intent (0 = solid blob, 1 = one through-hole, …). Cross-check the
  two volumes agree. This is the CAD/print equivalent of the render audit.

## Phase 3 — PBR materials & shading

Build shader node networks procedurally — no image textures unless provided.

- **Albedo:** base color, optionally broken up by a low-contrast Noise →
  ColorRamp → Mix into the base color (factor ≤ 0.15) so surfaces aren't dead flat.
- **Roughness:** never a bare constant. Noise or Voronoi → ColorRamp remapped
  to a tight band (e.g. 0.25–0.45 for worn metal, 0.5–0.8 for matte plastic).
- **Bump:** high-detail Noise → Bump node (strength 0.02–0.1) → Normal input.
  Use a Normal Map node only for baked/provided maps.
- **Metallic:** 0 or 1, almost never in between (in between = dirty metal masks).
- **Subsurface:** for skin/wax/plastic-translucent, set "Subsurface Weight"
  0.05–0.2 with a radius tinted toward the flesh/material color.
- **Socket names (Blender 4.0+ / 5.x):** "Specular IOR Level" (was Specular),
  "Subsurface Weight" (was Subsurface), "Transmission Weight" (was
  Transmission), "Emission Color" + "Emission Strength" (was Emission),
  "Coat Weight" (was Clearcoat), "Sheen Weight" (was Sheen). Always go through
  the `set_input()` resolver in the template so scripts survive both eras.

## Phase 3b — Photo-real upgrade: PBR image textures

Procedural noise reads as high-quality stylized. When the ask is **photo-real /
hyper-real**, layer real photographed PBR maps under the procedural structure.

**Source — Poly Haven (CC0, no attribution, safe for any use):**
- List assets: `https://api.polyhaven.com/assets?t=textures` — send a
  `User-Agent` header or the API returns 403.
- Map URLs: `https://api.polyhaven.com/files/<asset_id>` →
  `json[<MapType>]["2k"]["jpg"]["url"]` (on `dl.polyhaven.org`). Download
  **Diffuse**, **Rough**, **Displacement** at 2k JPG (~1–3 MB each).
- Alternative: ambientCG — `https://ambientcg.com/get?file=<AssetID>_2K-JPG.zip`.
- Cache maps in a local `textures/` folder next to the build script; never
  commit them to git (binaries), re-download on demand.

**Node recipe (no UV unwrapping needed):**
- Texture Coordinate **Object** → Mapping (scale/rotate to tile; rotate Z 90°
  when plank/grain direction must run vertically) → Image Texture with
  `projection='BOX'`, `projection_blend=0.3`. Box projection wraps photos onto
  any closed mesh cleanly.
- Diffuse → Base Color (colorspace **sRGB**). Rough → Roughness, Displacement →
  **Bump node** → Normal (both colorspace **Non-Color**). Use Bump, not a
  Normal Map node — tangent-space normal maps break under box projection.
- **Keep structure procedural on top of the photo:** mask-driven seams, panel
  lines, per-part tint variation still come from the Phase 3 math patterns —
  mix seam darkening over the photo color and SUBTRACT seam depth from the
  displacement before the Bump node. Photos supply micro-detail; procedural
  supplies the object's construction.
- Photo sets need slightly higher sampling (Cycles 192+) to resolve micro-detail.

**When grain/plank DIRECTION matters (staves, floorboards, brushed metal):**
box projection cannot orient the image on curved side faces — a Mapping Z
rotation only affects top-projected faces, so plank joints end up running the
wrong way. Generate real UVs instead and use Texture Coordinate **UV** →
Mapping (now rotation works uniformly) → Image Texture (`extension='REPEAT'`):
- Cylindrical bodies, in the bmesh build: `uv_layer = bm.loops.layers.uv.new("UVMap")`;
  per wall loop `u = column_index / SEGS * REPEATS` **without modulo** (the
  wrap face runs u→REPEATS so the tiling texture crosses the seam cleanly),
  `v = profile arclength × scale`. Flat caps: planar `uv = (x, y) × scale + 0.5`.
- Prefer a **continuous-grain** photo (table tops, bare wood) over board-joint
  planks for staves — photographed joints fight the procedural stave seams.
- Primitives from `bpy.ops.mesh.primitive_*` ship with usable auto-UVs.
- **Kill visible tiling:** give each stave/plank/panel a random per-part V
  offset in the UV pass (`voff = (part_id * 2654435761 % 97) / 97 * 0.5`) so
  photo-texture repeats never line up across parts; make part count divide the
  segment count so the resulting UV shear lands exactly on the darkened seam
  where it's invisible. Keep total V span ≤ 1 texture tile when possible.

## Phase 4 — Lighting & camera

Standard rig (in the template):

- **Key:** Area light, warm (RGB ≈ 1.0, 0.95, 0.85), 45° front-left, above
  subject, strongest.
- **Fill:** Area light, cool (RGB ≈ 0.75, 0.85, 1.0), front-right, ~1/4 key
  energy, larger + softer.
- **Rim:** Area/Spot behind and above, white, strong enough to draw an edge
  highlight separating subject from background.
- **World:** neutral dark gray (0.02–0.05) so the rig does the work. For
  realism, prefer **environment (image-based) lighting** instead — see below.
- **Camera:** 50mm, aimed via Track-To constraint at an Empty on the subject's
  bounding-box center, pulled back so the subject fills ~70% of frame with
  slight top-down angle (~15°).

### Environment (image-based) lighting — the biggest realism jump

A photographed sky in the World lights every surface at once — metal reflects a
real horizon, shadows fall from a real sun. This reads far more real than the
3-point rig, especially on metal/glossy surfaces (the rig gives them nothing to
reflect, so they look flat). Prefer it whenever the ask is "realistic".

Expose one simple choice — `lighting = "studio" | "sunset" | "warehouse" |
"overcast"` — and resolve it two ways, best-first, so it works everywhere:

1. **Real photo HDRI (best):** fetch the matching Poly Haven `.hdr` (CC0) and
   plug it into a **Background → Environment Texture** node in the World. Poly
   Haven needs a `User-Agent` header or it 403s; cache in a local `hdris/`
   folder, never commit it.
2. **Procedural fallback (no download):** when Poly Haven is unreachable
   (locked-down box, offline), don't fail — build the light in Blender itself:
   - Outdoor looks (`sunset`, noon): the **Sky Texture** node. In Blender 5.x
     the physical model is `sky_type='MULTIPLE_SCATTERING'` — the old
     `'NISHITA'` enum was **removed** (it raises `enum "NISHITA" not found`).
     Low `sun_elevation` = warm dusk; high = clean daylight.
   - Indoor/soft looks (`studio`, `overcast`, `warehouse`): a **gradient dome**
     (Geometry→Normal.Z → ColorRamp → Background) — brighter top, darker floor.
     `warehouse` adds one strong "window" Area light for an industrial rake.

Keep the 3-point rig as an explicit fallback (`lighting="3point"`) and for
before/after checks. Template E below is the verified implementation; the
before/after render proving it lives in PROGRESS.md's gotchas.

## Phase 5 — Verification & self-correction (the loop)

1. Run headless (each in its own code block when handing to the user; run it
   yourself when you have shell access):

   ```
   blender --background --factory-startup --python build_asset.py -- --out render.png
   ```

   Windows: `blender` is usually
   `C:\Program Files\Blender Foundation\Blender <ver>\blender.exe`; locate with
   `where blender` / `Get-ChildItem 'C:\Program Files\Blender Foundation'`.
   If Blender isn't installed, say exactly that and deliver the script +
   Three.js preview instead — never pretend a render happened.
2. The template renders **three angles** (front ¾, side, top) and prints
   `AUDIT:` lines (poly counts, ngons, non-manifold edges, dimensions) to
   stdout. Parse both.
3. **Read the PNGs** and audit: silhouette matches intent? scale plausible
   against the ground plane? shading artifacts (black faces = flipped normals;
   banding = missing auto-smooth/weighted normals)? bevels visible? materials
   read as the intended surface? lighting separates subject from background?
4. Any failure → fix the script (surgical edit), re-run, re-read. Cap: 3
   iterations, then report exactly what's still off and why.
5. On pass: export in the right modern format (below), delete intermediate
   renders/temp scripts, deliver final script + final render + asset path.

### Modern delivery formats (Blender 5.x, all verified on this pipeline)

Pick by destination; compression is free size/latency and the web expects it.

```python
base = os.path.splitext(OUT)[0]
bpy.ops.object.select_all(action='SELECT')

# Web / game engine — Draco geometry (≈7x smaller here) + textures
# Use export_image_format='AUTO', NOT 'WEBP': Blender's WebP export throws
# "webp does not support 1-channel images" on grayscale roughness/displacement
# maps and aborts the texture. AUTO keeps each map in a format that works.
bpy.ops.export_scene.gltf(filepath=base + ".glb", export_format='GLB',
    export_apply=True, export_draco_mesh_compression_enable=True,
    export_draco_mesh_compression_level=6, export_image_format='AUTO')

# Bandwidth-critical streaming — Meshopt (GPU-friendly, ≈3.4x smaller)
bpy.ops.export_scene.gltf(filepath=base + "_opt.glb", export_format='GLB',
    export_apply=True, export_meshopt_compression_enable=True)

# Studio / DCC interchange — OpenUSD (industry standard, Omniverse/Houdini/Maya)
bpy.ops.wm.usd_export(filepath=base + ".usdc")
```

- **KTX2 / Basis-Universal textures** are NOT in Blender's exporter (it stops at
  WebP). KTX2 is a two-tool post-process on the .glb, verified needs:
  1. Node + `@gltf-transform/cli` (`npm i -g @gltf-transform/cli`), AND
  2. the **KTX-Software `ktx` binary** on PATH — gltf-transform shells out to it;
     without it the CLI errors `Command "ktx" not found. Please install
     KTX-Software 4.3.0+`. It is NOT bundled with the npm package, and (as of
     4.4.2) is distributed only as a platform installer from the Khronos GitHub
     releases — no portable Windows zip, not in winget.
  Then: `gltf-transform etc1s in.glb out.glb` (small/ETC1S) or `uastc` (higher
  quality). Say plainly KTX2 is a separate step — never claim Blender did it.
  **Verified end-to-end on this machine** (KTX-Software 4.4.2 installed to
  `C:\Program Files\KTX-Software\bin`, added to system PATH — a fresh shell picks
  it up; an existing one needs `export PATH="/c/Program Files/KTX-Software/bin:$PATH"`
  first): a 20.7 MB textured `.glb` → **5.59 MB** with `etc1s`. Load the result
  in Three.js with `KTX2Loader` (`.setTranscoderPath(...)`, `.detectSupport(renderer)`).
- Print/CAD parts: STL (mesh) + STEP (parametric) from build123d, gated by the
  trimesh/manifold3d watertight check in Phase 2 — never ship an unvalidated STL.

### Game asset with LODs (verified pipeline)

For an engine-ready asset with levels of detail:
1. **Join** all parts into ONE mesh (apply every modifier first), shade smooth.
2. **Smart-UV unwrap** (`bpy.ops.uv.smart_project`, island_margin ≥ 0.02).
3. **Bake** albedo + roughness + normal to images off the source material, then
   rebuild a clean UV-mapped material from the baked maps. **Gotcha: bake the
   albedo with Metallic = 0** — a metal's diffuse pass bakes near-black, so a
   metallic source gives a flat dark map; force metalness off for the color
   bake, then set it back on the final material. (Full ORM set — add metallic +
   AO packed — is the next extension.)
   **Gotcha: overlapping smart-UV islands stamp square blemishes** where the
   body samples another island's texels; pack with margin or bake per-object.
4. **LOD chain** via the Decimate modifier at ratios `[1.0, 0.5, 0.25, 0.12]`
   (COLLAPSE preserves UVs); audit tri counts per level. Measured on the jerry
   can: 4,532 → 2,266 → 1,132 → 542 tris.
5. **Export** each LOD as its own Draco `.glb` (`use_selection=True`).
6. **Verify** in a `THREE.LOD` viewer: `addLevel(mesh, distance)` per LOD,
   `lod.update(camera)` each frame; a HUD reading the active level + tri count
   proves the swap by distance.

---

## Template A — Blender `bpy` master script

Adapt, don't rewrite: keep `set_input`, `pick_engine`, `audit_mesh`, and the
rig; swap out `build_asset()`.

```python
# build_asset.py — run: blender --background --factory-startup --python build_asset.py -- --out render.png
import bpy, bmesh, math, sys, os

def cli_args():
    argv = sys.argv
    return argv[argv.index("--") + 1:] if "--" in argv else []

def arg(name, default):
    a = cli_args()
    return a[a.index(name) + 1] if name in a else default

OUT = os.path.abspath(arg("--out", "render.png"))

# ---------- scene reset ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'

# ---------- version-safe Principled sockets (Blender 3.x names -> 4.x/5.x) ----------
ALIASES = {
    "Specular IOR Level": ["Specular"],
    "Subsurface Weight": ["Subsurface"],
    "Transmission Weight": ["Transmission"],
    "Emission Color": ["Emission"],
    "Coat Weight": ["Clearcoat"],
    "Sheen Weight": ["Sheen"],
}
def set_input(node, name, value):
    sock = node.inputs.get(name)
    if sock is None:
        for legacy in ALIASES.get(name, []):
            sock = node.inputs.get(legacy)
            if sock: break
    if sock is None:
        print(f"AUDIT: WARN missing socket '{name}' on {node.name}")
        return
    sock.default_value = value

# ---------- procedural PBR material ----------
def make_pbr(name, base_color, rough_lo=0.3, rough_hi=0.6, metallic=0.0, bump=0.05):
    mat = bpy.data.materials.new(name)
    if mat.node_tree is None:
        mat.use_nodes = True  # pre-5.x only; deprecated no-op in 5.x+
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    set_input(bsdf, "Base Color", base_color)
    set_input(bsdf, "Metallic", metallic)

    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 18.0
    noise.inputs["Detail"].default_value = 6.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (rough_lo,) * 3 + (1,)
    ramp.color_ramp.elements[1].color = (rough_hi,) * 3 + (1,)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Roughness"])

    bump_noise = nt.nodes.new("ShaderNodeTexNoise")
    bump_noise.inputs["Scale"].default_value = 60.0
    bump_node = nt.nodes.new("ShaderNodeBump")
    bump_node.inputs["Strength"].default_value = bump
    nt.links.new(bump_noise.outputs["Fac"], bump_node.inputs["Height"])
    nt.links.new(bump_node.outputs["Normal"], bsdf.inputs["Normal"])
    return mat

# ---------- non-destructive modifier stack ----------
def hard_surface_stack(obj, bevel_width=0.01):
    bev = obj.modifiers.new("Bevel", 'BEVEL')
    bev.width, bev.segments = bevel_width, 3
    bev.limit_method, bev.angle_limit = 'ANGLE', math.radians(30)
    bev.harden_normals = True
    sub = obj.modifiers.new("Subdivision", 'SUBSURF')
    sub.levels = sub.render_levels = 2
    wn = obj.modifiers.new("WeightedNormal", 'WEIGHTED_NORMAL')
    wn.keep_sharp = True
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_auto_smooth(angle=math.radians(30))  # 4.1+/5.x API

# ---------- BUILD (replace with the actual asset) ----------
def build_asset(root):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=0.4, depth=1.0, location=(0, 0, 0.5))
    body = bpy.context.active_object
    body.name = "Body"
    body.parent = root
    body.data.materials.append(make_pbr("BodyMat", (0.35, 0.08, 0.06, 1.0), metallic=0.0))
    hard_surface_stack(body)
    return [body]

root = bpy.data.objects.new("Asset_root", None)
scene.collection.objects.link(root)
parts = build_asset(root)

# ground plane for scale reference
bpy.ops.mesh.primitive_plane_add(size=10)
ground = bpy.context.active_object
ground.name = "Ground"
ground.data.materials.append(make_pbr("GroundMat", (0.18, 0.18, 0.18, 1.0), 0.6, 0.9, bump=0.0))

# ---------- mesh audit ----------
def audit_mesh(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    tris = sum(1 for f in bm.faces if len(f.verts) == 3)
    quads = sum(1 for f in bm.faces if len(f.verts) == 4)
    ngons = sum(1 for f in bm.faces if len(f.verts) > 4)
    nonman = sum(1 for e in bm.edges if not e.is_manifold)
    loose = sum(1 for v in bm.verts if not v.link_edges)
    bm.free()
    d = obj.dimensions
    print(f"AUDIT: {obj.name} tris={tris} quads={quads} ngons={ngons} "
          f"non_manifold_edges={nonman} loose_verts={loose} "
          f"dims={d.x:.3f}x{d.y:.3f}x{d.z:.3f}m")

for p in parts:
    audit_mesh(p)

# ---------- 3-point lighting ----------
def add_light(name, kind, loc, energy, color, size=2.0):
    data = bpy.data.lights.new(name, kind)
    data.energy, data.color = energy, color
    if kind == 'AREA':
        data.size = size
    ob = bpy.data.objects.new(name, data)
    ob.location = loc
    scene.collection.objects.link(ob)
    return ob

target = bpy.data.objects.new("CamTarget", None)
target.location = (0, 0, 0.5)  # subject bbox center
scene.collection.objects.link(target)

def aim(ob):
    c = ob.constraints.new('TRACK_TO')
    c.target, c.track_axis, c.up_axis = target, 'TRACK_NEGATIVE_Z', 'UP_Y'

key  = add_light("Key",  'AREA', (-2.5, -2.5, 3.0), 600, (1.0, 0.95, 0.85), 3.0)
fill = add_light("Fill", 'AREA', ( 2.5, -2.0, 1.5), 150, (0.75, 0.85, 1.0), 4.0)
rim  = add_light("Rim",  'AREA', ( 0.5,  3.0, 2.5), 500, (1.0, 1.0, 1.0), 1.0)
for L in (key, fill, rim):
    aim(L)

world = bpy.data.worlds.new("World")
scene.world = world
if world.node_tree is None:
    world.use_nodes = True  # pre-5.x only; deprecated no-op in 5.x+
bg = world.node_tree.nodes["Background"]
bg.inputs["Color"].default_value = (0.03, 0.03, 0.035, 1.0)

# ---------- camera ----------
cam_data = bpy.data.cameras.new("Camera")
cam_data.lens = 50
cam = bpy.data.objects.new("Camera", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
aim(cam)

# ---------- render engine fallback (5.x/4.2 EEVEE id differs; Cycles CPU always works) ----------
def pick_engine():
    for eng in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE', 'CYCLES'):
        try:
            scene.render.engine = eng
            return eng
        except TypeError:
            continue
pick_engine()
if scene.render.engine == 'CYCLES':
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
scene.render.resolution_x = scene.render.resolution_y = 1024
scene.render.image_settings.file_format = 'PNG'

# ---------- 3-angle verification renders ----------
ANGLES = {"front34": (-3.2, -3.2, 2.2), "side": (4.2, 0, 1.2), "top": (0.01, 0.01, 5.5)}
base, ext = os.path.splitext(OUT)
for tag, loc in ANGLES.items():
    cam.location = loc
    scene.render.filepath = f"{base}_{tag}{ext}"
    try:
        bpy.ops.render.render(write_still=True)
    except Exception as e:  # EEVEE can fail without a GPU context headless
        print(f"AUDIT: render failed on {scene.render.engine} ({e}); falling back to CYCLES")
        scene.render.engine = 'CYCLES'
        scene.cycles.samples = 64
        bpy.ops.render.render(write_still=True)
    print(f"AUDIT: rendered {scene.render.filepath}")

# ---------- export ----------
gltf_path = base + ".glb"
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=gltf_path, export_apply=True)  # applies modifiers on export only
print(f"AUDIT: exported {gltf_path}")
```

## Template E — environment lighting (extends Template A, verified)

Drop-in for Phase 4. Call `set_environment(scene, "sunset")` instead of the
3-point rig. For a **real photographed sky** it tries Poly Haven first (open
networks), then a **GitHub-mirrored** three.js HDRI (reachable even on a locked
cloud box whose egress is a GitHub+package allowlist — see FAILURES F-45); if
both are unreachable it falls back to Blender's own physical sky / a gradient
dome with **zero download**, so it always renders. Verified headless on Blender
5.0.1 (bpy from PyPI): the real GitHub HDRI path and all procedural fallbacks.
Runs on a bare box — `pip install bpy` is the whole engine (PLAYBOOK P-14).

```python
import bpy, math, os, urllib.request, json

# Named look -> Poly Haven slug (open networks), a GitHub-mirrored HDRI that's
# reachable even on a GitHub-allowlist cloud box, and a procedural fallback.
# GitHub files are real three.js CC0 equirectangular maps (verified to exist).
GH_HDRI = ("https://raw.githubusercontent.com/mrdoob/three.js/dev/"
           "examples/textures/equirectangular")
ENV_PRESETS = {
    "sunset":    dict(hdri="venice_sunset",       gh="venice_sunset_1k.hdr",       sky=dict(elev=2, dust=3.0, strength=1.0)),
    "studio":    dict(hdri="studio_small_09",     gh="san_giuseppe_bridge_2k.hdr", dome=dict(top=(0.85,0.85,0.88), bottom=(0.35,0.35,0.37), strength=1.3)),
    "overcast":  dict(hdri="kloofendal_overcast", gh="quarry_01_1k.hdr",           dome=dict(top=(0.62,0.63,0.66), bottom=(0.5,0.5,0.52),  strength=1.0)),
    "warehouse": dict(hdri="warehouse",           gh="pedestrian_overpass_1k.hdr", dome=dict(top=(0.10,0.095,0.09), bottom=(0.04,0.04,0.045), strength=1.0),
                      window=dict(loc=(4.0,-1.0,2.2), energy=1200, color=(0.85,0.9,1.0), size=2.5)),
}

def _fetch(url, dest, headers):
    if os.path.exists(dest): return dest
    data = urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=90).read()
    with open(dest, "wb") as fh: fh.write(data)
    return dest

def _real_hdri(preset, out_dir, res="2k"):
    """Get a real photographed HDRI: Poly Haven first (open net), then a
    GitHub-mirrored three.js map (reachable on a GitHub-allowlist cloud box).
    Returns a local path, or None so the caller uses the procedural fallback."""
    os.makedirs(out_dir, exist_ok=True)
    H = {"User-Agent": "3d-master-modeler/1.0"}              # Poly Haven 403s without a UA
    slug = preset.get("hdri")
    if slug:                                                 # 1) Poly Haven (best, open networks)
        try:
            files = json.loads(urllib.request.urlopen(
                urllib.request.Request(f"https://api.polyhaven.com/files/{slug}", headers=H), timeout=20).read())
            return _fetch(files["hdri"][res]["hdr"]["url"], os.path.join(out_dir, f"{slug}_{res}.hdr"), H)
        except Exception as e:
            print(f"AUDIT: Poly Haven unreachable ({type(e).__name__}); trying GitHub mirror")
    gh = preset.get("gh")
    if gh:                                                   # 2) GitHub mirror (locked cloud box)
        try:
            return _fetch(f"{GH_HDRI}/{gh}", os.path.join(out_dir, gh), H)
        except Exception as e:
            print(f"AUDIT: GitHub HDRI unreachable ({type(e).__name__}); using procedural fallback")
    return None

def set_environment(scene, lighting="sunset", strength=1.0, hdri_dir="hdris", try_download=True):
    """Image-based World lighting. Returns a short AUDIT description of what was used."""
    preset = ENV_PRESETS.get(lighting)
    if preset is None:
        raise ValueError(f"unknown lighting '{lighting}', pick {list(ENV_PRESETS)}")
    world = bpy.data.worlds.new("World"); scene.world = world; world.use_nodes = True
    nt = world.node_tree
    for n in list(nt.nodes):
        if n.type != 'OUTPUT_WORLD':
            nt.nodes.remove(n)
    out = nt.nodes.get("World Output") or nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])

    hdri = _real_hdri(preset, hdri_dir) if try_download else None
    if hdri:                                              # 1) real photo HDRI (Poly Haven or GitHub)
        env = nt.nodes.new("ShaderNodeTexEnvironment"); env.image = bpy.data.images.load(hdri)
        nt.links.new(env.outputs["Color"], bg.inputs["Color"])
        bg.inputs["Strength"].default_value = strength
        return f"HDRI:{preset['hdri']}"

    if "sky" in preset:                                  # 2a) physical sky (outdoor)
        s = preset["sky"]
        sky = nt.nodes.new("ShaderNodeTexSky")
        sky.sky_type = 'MULTIPLE_SCATTERING'             # Blender 5.x name; 'NISHITA' was removed
        sky.sun_elevation = math.radians(s["elev"]); sky.sun_rotation = math.radians(-40)
        if hasattr(sky, "dust_density"): sky.dust_density = s["dust"]
        nt.links.new(sky.outputs["Color"], bg.inputs["Color"])
        bg.inputs["Strength"].default_value = s["strength"] * strength
        return f"sky:{lighting}(elev{s['elev']})"

    d = preset["dome"]                                   # 2b) gradient dome (indoor/soft)
    geo = nt.nodes.new("ShaderNodeNewGeometry"); sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], sep.inputs["Vector"])
    mul = nt.nodes.new("ShaderNodeMath"); mul.operation='MULTIPLY_ADD'
    mul.inputs[1].default_value = 0.5; mul.inputs[2].default_value = 0.5   # map normal.z (-1..1) -> 0..1
    nt.links.new(sep.outputs["Z"], mul.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = tuple(d["bottom"]) + (1,)
    ramp.color_ramp.elements[1].color = tuple(d["top"]) + (1,)
    nt.links.new(mul.outputs["Value"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = d["strength"] * strength
    if "window" in preset:                               # warehouse: one strong side light
        w = preset["window"]
        ld = bpy.data.lights.new("Window", 'AREA'); ld.energy=w["energy"]; ld.color=w["color"]; ld.size=w["size"]
        lo = bpy.data.objects.new("Window", ld); lo.location=w["loc"]; scene.collection.objects.link(lo)
        lo.rotation_euler = (math.radians(70), 0, math.radians(50))
    return f"dome:{lighting}"
```

## Template F — cinematic final polish (verified)

The finish pass after Phase 5. Depth-of-field stays **native on the camera** (a
real 3D effect); grade + bloom + vignette run as a **post-render pass on the PNG**
(Pillow + numpy). This is deliberately NOT the compositor: Blender 5.0 dropped
`scene.node_tree` and the `Composite` node (FAILURES F-46), so a post-pass is the
version-proof, GPU-free way to ship a consistent look. Verified on Blender 5.0.1.

```python
def enable_dof(camera, focus_obj, fstop=2.8):
    dof = camera.data.dof
    dof.use_dof = True; dof.focus_object = focus_obj; dof.aperture_fstop = fstop

def cinematic_finish(in_png, out_png, lift=(0.00,0.01,0.035), gain=(1.06,1.01,0.93),
                     contrast=1.14, bloom=0.55, bloom_thresh=0.72, bloom_radius=10,
                     vignette=0.40):
    """Post-render finish: teal/orange grade, gentle highlight bloom, soft vignette."""
    from PIL import Image, ImageFilter
    import numpy as np
    img = np.asarray(Image.open(in_png).convert("RGB"), np.float32) / 255.0
    img = img * np.array(gain) + np.array(lift) * (1.0 - img)   # gain=highlights, lift=shadows
    img = np.clip((img - 0.5) * contrast + 0.5, 0, 1)           # contrast around mid-grey
    if bloom > 0:                                               # highlights -> blur -> screen back
        hi = np.clip((img.max(axis=2) - bloom_thresh) / (1 - bloom_thresh), 0, 1)
        blur = np.asarray(Image.fromarray((np.clip(img*hi[...,None],0,1)*255).astype('uint8'))
                          .filter(ImageFilter.GaussianBlur(bloom_radius)), np.float32)/255.0
        img = 1 - (1 - img) * (1 - blur * bloom)
    if vignette > 0:                                            # soft radial edge darkening
        h, w = img.shape[:2]; yy, xx = np.mgrid[0:h, 0:w]
        d = np.sqrt(((xx - w/2)/(w/2))**2 + ((yy - h/2)/(h/2))**2)
        img = img * (1 - vignette * np.clip((d - 0.55)/0.6, 0, 1)**2)[..., None]
    Image.fromarray((np.clip(img,0,1)*255).astype('uint8')).save(out_png)
    return f"finish -> {os.path.basename(out_png)}"

# usage: enable_dof(cam, target, 2.8) BEFORE the final render, then
#        cinematic_finish("render.png", "final.png") AFTER it.
```

## Template G — engine texture-bake set (albedo/rough/metal/normal/AO/ORM, verified)

Bake a procedural material down to the texture maps a game engine actually reads,
folded into a textured glTF. Verified headless on Blender 5.0.1 (bpy from PyPI):
the baked render is indistinguishable from the procedural source, with the two
classic bake bugs fixed.

**The two bugs this fixes (both proven dead-then-fixed — FAILURES F-52/F-53):**
- **Square blemishes on the body** = overlapping smart-UV islands, where the bake
  reads a neighbour island across a touching edge. Fix: `smart_project` with an
  `island_margin` (islands never touch) **and** a `bake.margin` in pixels (colour
  bleeds past each island edge so mip-mapping/filtering never samples the gutter).
- **Metal albedo bakes black** = a fully-metallic surface has no diffuse response,
  so a `DIFFUSE`/`COLOR` bake returns black (F-53). Fix below sidesteps it entirely:
  bake **Base Color directly** through a temporary Emission pass (`EMIT`) — raw node
  value, no lighting, no metal-black. Same trick captures roughness + metallic.

**Order:** apply modifiers → UV unwrap with margin → bake each pass → pack ORM →
rebuild a texture-driven material → export glTF. Baking requires the **Cycles**
engine. Give albedo an **sRGB** image; give roughness/metallic/normal/AO
**Non-Color** images (they carry data, not colour).

```python
import bpy, math, os
from PIL import Image

def uv_unwrap_for_bake(obj, island_margin=0.03):
    """Non-overlapping UVs — the square-blemish fix starts here (F-47)."""
    bpy.context.view_layer.objects.active = obj; obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=island_margin)
    bpy.ops.object.mode_set(mode='OBJECT')

def bake_pbr_set(obj, out_dir, res=1024, bake_margin=8):
    """Bake albedo/roughness/metallic/normal/AO + packed ORM. Returns {tag: path}.
    obj must already have ONE procedural material and non-overlapping UVs."""
    os.makedirs(out_dir, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'; scene.cycles.samples = 48
    scene.render.bake.margin = bake_margin      # px bleed past islands => no seam blemish
    scene.render.bake.use_clear = True
    mat = obj.data.materials[0]; nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]; out = nt.nodes.get("Material Output")
    paths = {}

    def target(tag, non_color):
        img = bpy.data.images.new(f"bake_{tag}", res, res, alpha=False)
        img.colorspace_settings.name = 'Non-Color' if non_color else 'sRGB'
        node = nt.nodes.new("ShaderNodeTexImage"); node.image = img
        nt.nodes.active = node                  # bake writes to the ACTIVE image node
        return img

    def save(img, tag):
        p = os.path.join(out_dir, f"{tag}.png"); img.filepath_raw = p; img.file_format = 'PNG'
        img.save(); paths[tag] = p; return p

    def do_bake(bake_type):
        bpy.context.view_layer.objects.active = obj; obj.select_set(True)
        bpy.ops.object.bake(type=bake_type)

    # emission-trick: route a socket's source (or its constant) through Emission, bake EMIT.
    # Raw node value, no lighting — works for albedo/rough/metal and dodges metal-black (F-48).
    def bake_socket(sock_name, tag, non_color):
        img = target(tag, non_color)
        emit = nt.nodes.new("ShaderNodeEmission"); sock = bsdf.inputs.get(sock_name)
        if sock.is_linked:
            nt.links.new(sock.links[0].from_socket, emit.inputs["Color"])
        else:
            v = sock.default_value
            emit.inputs["Color"].default_value = v if hasattr(v, '__len__') else (v, v, v, 1.0)
        keep = out.inputs["Surface"].links[0].from_socket
        nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
        do_bake('EMIT')
        nt.links.new(keep, out.inputs["Surface"]); nt.nodes.remove(emit)   # restore
        return save(img, tag)

    bake_socket("Base Color", "albedo", non_color=False)   # metalness-off is implicit here
    bake_socket("Roughness",  "roughness", non_color=True)
    bake_socket("Metallic",   "metallic",  non_color=True)
    nrm = target("normal", True); do_bake('NORMAL'); save(nrm, "normal")  # native tangent-space pass
    ao = target("ao", True); do_bake('AO'); save(ao, "ao")                # native AO pass
    # native passes: create+activate target -> bake -> save (target must exist before the bake)

    g = lambda t: Image.open(paths[t]).convert("L")           # pack ORM: R=AO G=rough B=metal
    orm = Image.merge("RGB", (g("ao"), g("roughness"), g("metallic")))
    paths["orm"] = os.path.join(out_dir, "orm.png"); orm.save(paths["orm"])
    return paths

def baked_material(name, paths):
    """Build a texture-driven material from bake_pbr_set() output — what an engine consumes."""
    mat = bpy.data.materials.new(name); mat.use_nodes = True
    nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
    def tex(path, non_color):
        n = nt.nodes.new("ShaderNodeTexImage"); n.image = bpy.data.images.load(path)
        n.image.colorspace_settings.name = 'Non-Color' if non_color else 'sRGB'; return n
    nt.links.new(tex(paths["albedo"], False).outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex(paths["roughness"], True).outputs["Color"], bsdf.inputs["Roughness"])
    nt.links.new(tex(paths["metallic"], True).outputs["Color"], bsdf.inputs["Metallic"])
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tex(paths["normal"], True).outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"]); return mat

# usage:
#   uv_unwrap_for_bake(obj)                       # after modifiers are applied
#   paths = bake_pbr_set(obj, "textures")         # 6 maps to disk
#   obj.data.materials.clear(); obj.data.materials.append(baked_material("Baked", paths))
#   bpy.ops.export_scene.gltf(filepath="asset.glb", export_format='GLB',
#                             use_selection=True, export_image_format='AUTO')  # AUTO, not WEBP
```

**Draft vs final tiers (upgrade #5):** EEVEE Next won't init headless with no GPU
(falls back to Cycles), so use Cycles sample counts as the tier knob —
`scene.cycles.samples = 16` for the fix-loop draft (fast, noisy-but-readable),
`= 128+` for the final. Bake at the draft tier while iterating UVs, then re-bake
once at the final tier. Resolution is the second knob: 512² draft, 1024²/2048² final.

## Template H — generalized asset fetchers: textures + models (verified)

Extends Template E's HDRI fetcher into a general **probe-first, best-source, cache**
pattern for PBR **texture sets** and **models** too. Every fetcher tries the richest
open-net source first (Poly Haven / ambientCG) then falls back to a **GitHub mirror**
that stays reachable on a locked box whose egress is a GitHub+package allowlist
(F-45) — so the same code pulls real CC0 assets on the laptop *and* in a restricted
cloud env. Verified headless on Blender 5.0.1: on the locked box, a wood + a brick
PBR set (three.js mirror) and a Khronos `.glb` model all fetched and rendered.
Never commit the downloaded binaries — cache them next to the build script.

```python
import bpy, os, json, urllib.request
UA = {"User-Agent": "3d-master-modeler/1.0"}
GH_TEX   = "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures"
GH_MODEL = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models"

def _reachable(url):                       # ranged HEAD — probe before download (P-16)
    try:
        r = urllib.request.Request(url, headers={**UA, "Range": "bytes=0-0"})
        return urllib.request.urlopen(r, timeout=20).status in (200, 206)
    except Exception:
        return False
def _download(url, dest):
    if os.path.exists(dest) and os.path.getsize(dest) > 0: return dest
    data = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120).read()
    open(dest, "wb").write(data); return dest

# best-first sources per asset. GitHub triple = diffuse+bump+roughness (real photos);
# Poly Haven / ambientCG add normal/displacement/AO/metal on an open network.
TEXTURE_SETS = {
    "wood":  dict(polyhaven="wood_floor",    ambientcg="WoodFloor051",
                  gh=dict(diffuse="hardwood2_diffuse.jpg", bump="hardwood2_bump.jpg", roughness="hardwood2_roughness.jpg")),
    "brick": dict(polyhaven="brick_wall_02", ambientcg="Bricks075",
                  gh=dict(diffuse="brick_diffuse.jpg", bump="brick_bump.jpg", roughness="brick_roughness.jpg")),
}
MODELS = {   # GitHub-mirrored glTF binaries (Khronos sample assets) — reachable on a locked box
    "helmet":  f"{GH_MODEL}/DamagedHelmet/glTF-Binary/DamagedHelmet.glb",
    "duck":    f"{GH_MODEL}/Duck/glTF-Binary/Duck.glb",
    "avocado": f"{GH_MODEL}/Avocado/glTF-Binary/Avocado.glb",
}

def fetch_texture_set(name, out_dir, res="2k"):
    """{map_type: local_path}. Poly Haven -> (ambientCG zip on open net) -> GitHub mirror -> {}."""
    spec = TEXTURE_SETS[name]; d = os.path.join(out_dir, f"tex_{name}"); os.makedirs(d, exist_ok=True)
    try:                                    # 1) Poly Haven — same API shape as the verified HDRI path
        files = json.loads(urllib.request.urlopen(urllib.request.Request(
            f"https://api.polyhaven.com/files/{spec['polyhaven']}", headers=UA), timeout=20).read())
        want = {"Diffuse":"diffuse","Rough":"roughness","nor_gl":"normal","Displacement":"displacement","AO":"ao"}
        maps = {tag: _download(files[k][res]["jpg"]["url"], os.path.join(d, f"{tag}.jpg"))
                for k, tag in want.items() if files.get(k, {}).get(res, {}).get("jpg")}
        if maps: return maps
    except Exception as e:
        print(f"AUDIT: Poly Haven set unreachable ({type(e).__name__}); GitHub mirror")
    return {tag: _download(f"{GH_TEX}/{f}", os.path.join(d, f))   # 3) GitHub mirror (locked box)
            for tag, f in spec["gh"].items() if _reachable(f"{GH_TEX}/{f}")}

def fetch_model(name, out_dir):
    """Local .glb from a GitHub mirror. Import with bpy.ops.import_scene.gltf(filepath=...)."""
    url = MODELS[name]
    return _download(url, os.path.join(out_dir, f"{name}.glb")) if _reachable(url) else None

def pbr_from_maps(name, maps, scale=2.0):
    """Wire a fetched map set into a BOX-projected material — no UV unwrap needed (Phase 3b)."""
    mat = bpy.data.materials.new(name); mat.use_nodes = True
    nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
    tc = nt.nodes.new("ShaderNodeTexCoord"); mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (scale, scale, scale)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    def img(path, non_color):
        n = nt.nodes.new("ShaderNodeTexImage"); n.image = bpy.data.images.load(path)
        n.projection = 'BOX'; n.projection_blend = 0.3
        n.image.colorspace_settings.name = 'Non-Color' if non_color else 'sRGB'
        nt.links.new(mp.outputs["Vector"], n.inputs["Vector"]); return n
    if "diffuse" in maps:   nt.links.new(img(maps["diffuse"], False).outputs["Color"], bsdf.inputs["Base Color"])
    if "roughness" in maps: nt.links.new(img(maps["roughness"], True).outputs["Color"], bsdf.inputs["Roughness"])
    if "normal" in maps:
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(img(maps["normal"], True).outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    elif "bump" in maps:                    # three.js sets ship a bump (height) map, not a normal
        bp = nt.nodes.new("ShaderNodeBump"); bp.inputs["Strength"].default_value = 0.4
        nt.links.new(img(maps["bump"], True).outputs["Color"], bp.inputs["Height"])
        nt.links.new(bp.outputs["Normal"], bsdf.inputs["Normal"])
    return mat

# usage: m = fetch_texture_set("wood", "assets"); obj.data.materials.append(pbr_from_maps("Wood", m))
#        glb = fetch_model("avocado", "assets"); bpy.ops.import_scene.gltf(filepath=glb)
```

Adding a source is a one-line registry entry. To add a whole new asset TYPE
(e.g. decals, IES light profiles) copy the probe→best-source→GitHub-mirror→cache
shape. On the laptop (open network) Poly Haven/ambientCG win and bring fuller map
sets (normal + displacement + AO); the GitHub mirror is the guaranteed floor.

## Template B — Three.js WebGPU + TSL (single file, previewable)

Modern default (verified: renders on a real WebGPU backend, auto-falls back to
WebGL2). Import from `three/webgpu`, `await renderer.init()` before the first
frame, use `MeshStandardNodeMaterial` + TSL nodes for materials (raw-GLSL
`ShaderMaterial`/`onBeforeCompile` are unsupported on WebGPU), and drive the
loop with `renderer.render` (NOT the deprecated `renderAsync`).

```html
<!doctype html>
<meta charset="utf-8">
<style>html,body{margin:0;height:100%;overflow:hidden;background:#0a0a0c}canvas{display:block}</style>
<script type="importmap">
{"imports":{
"three":"https://cdn.jsdelivr.net/npm/three@0.184.0/build/three.webgpu.js",
"three/webgpu":"https://cdn.jsdelivr.net/npm/three@0.184.0/build/three.webgpu.js",
"three/tsl":"https://cdn.jsdelivr.net/npm/three@0.184.0/build/three.tsl.js",
"three/addons/":"https://cdn.jsdelivr.net/npm/three@0.184.0/examples/jsm/"}}
</script>
<script type="module">
import * as THREE from 'three/webgpu';
import { color, mix, positionLocal, mx_noise_float } from 'three/tsl';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const renderer = new THREE.WebGPURenderer({ antialias: true });
renderer.setSize(innerWidth, innerHeight);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.appendChild(renderer.domElement);
await renderer.init();  // MANDATORY before first frame — requests the GPU device

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0a0a0c);
const camera = new THREE.PerspectiveCamera(45, innerWidth / innerHeight, 0.1, 100);
camera.position.set(3, 2, 4);

// 3-point rig
const key = new THREE.DirectionalLight(0xfff1e0, 3); key.position.set(-4, 6, 4);
const fill = new THREE.DirectionalLight(0xdbe9ff, 0.8); fill.position.set(4, 2, 3);
const rim = new THREE.DirectionalLight(0xffffff, 2); rim.position.set(0, 4, -6);
scene.add(key, fill, rim, new THREE.AmbientLight(0xffffff, 0.15));

// TSL node material — procedural grain in-shader, compiles to WGSL or GLSL
const mat = new THREE.MeshStandardNodeMaterial({ metalness: 0.0 });
const grain = mx_noise_float(positionLocal.mul(6.0));
mat.colorNode = mix(color(0x5a1810), color(0xc07a2a), grain.mul(0.5).add(0.5));
mat.roughnessNode = mix(color(0.35), color(0.7), grain).r;

const mesh = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.5, 1.2, 64), mat);
mesh.position.y = 0.6; scene.add(mesh);
const ground = new THREE.Mesh(new THREE.PlaneGeometry(20, 20),
  new THREE.MeshStandardNodeMaterial({ color: 0x202020, roughness: 0.9 }));
ground.rotation.x = -Math.PI / 2; scene.add(ground);

const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 0.6, 0); controls.enableDamping = true;
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
renderer.setAnimationLoop(() => { controls.update(); renderer.render(scene, camera); });
</script>
```

TSL nodes worth knowing: `positionLocal`/`positionWorld`, `normalWorld`, `uv()`,
`mx_noise_float`/`mx_worley_noise_float` (MaterialX procedurals), `texture(tex)`,
`mix`/`smoothstep`/`clamp`, `.mul/.add/.sub`. To load a compressed asset from
Blender, use `GLTFLoader` + `DRACOLoader` (and `KTX2Loader` for KTX2 textures)
from `three/addons/`. Verify in the browser: screenshot + console must show no
errors; the on-page tag reports whether the WebGPU or WebGL2 backend is live.

## Template C — build123d (modern code-CAD, verified)

Preferred for engineering/print parts: Pythonic context managers (real `for`
loops, filtering, sorting on edges/faces), OpenCASCADE BREP kernel, STEP + STL
export, and it feeds straight into the Phase 2 trimesh/manifold3d gate. This
exact script runs on build123d 0.11 and passes watertight/manifold checks.

```python
# cad_part.py — run: python cad_part.py   (pip install build123d trimesh manifold3d)
from build123d import (BuildPart, Box, Cylinder, Locations, Mode,
                       fillet, chamfer, Axis, export_stl, export_step)
import trimesh, manifold3d, os
W, D, H, WALL, BORE, FIL = 60, 40, 24, 3.0, 14, 3.0
OUT = os.path.dirname(os.path.abspath(__file__))

with BuildPart() as part:
    Box(W, D, H)
    Box(W - 2*WALL, D - 2*WALL, H, mode=Mode.SUBTRACT)      # hollow
    with Locations((0, 0, H/2)):
        Cylinder(BORE/2, H, mode=Mode.SUBTRACT)            # vertical bore
    fillet(part.edges().filter_by(Axis.Z), radius=FIL)      # round tall corners
    chamfer(part.faces().sort_by(Axis.Z)[-1].edges(), length=1.0)  # top rim

stl = os.path.join(OUT, "part.stl"); export_step(part.part, os.path.join(OUT, "part.step"))
export_stl(part.part, stl)

m = trimesh.load(stl)                                        # numeric gate
mani = manifold3d.Manifold(manifold3d.Mesh(m.vertices.astype('float32'),
                                           m.faces.astype('uint32')))
print(f"AUDIT: watertight={m.is_watertight} genus={mani.genus()} "
      f"status={mani.status()} vol_cm3={m.volume/1000:.2f}")
assert m.is_watertight and str(mani.status()) == "Error.NoError"
print("AUDIT: PASS — watertight manifold part, STEP+STL exported")
```

## Template D — OpenSCAD parametric (quick constructive-solid parts)

Units are mm. Overlap all unions/differences by `eps` — coincident faces are
the #1 cause of non-manifold/broken STLs. Preview `$fn` low, render high.

```openscad
// asset.scad — render STL: openscad -o asset.stl -D '$fn=128' asset.scad
// ---- parameters (all mm) ----
body_d    = 40;
body_h    = 60;
wall      = 2.4;    // >= 2 * nozzle width for printability
corner_r  = 3;
eps       = 0.01;   // overlap to guarantee manifold booleans
$fn = $preview ? 48 : 128;

assert(wall * 2 < body_d, "wall too thick for diameter");
assert(corner_r < body_d / 2, "corner radius exceeds half diameter");

module rounded_cyl(d, h, r) {
    // cylinder with rounded OUTER top/bottom edges; axis edge stays straight
    // (a plain offset(r)offset(-r) on the profile would also round the axis
    //  corners and leave a dimple in the top center — don't)
    rotate_extrude()
        hull() {
            square([d / 2 - r, h]);
            translate([d / 2 - r, h - r]) circle(r);
            translate([d / 2 - r, r]) circle(r);
        }
}

module body() {
    difference() {
        rounded_cyl(body_d, body_h, corner_r);
        translate([0, 0, wall])
            cylinder(d = body_d - 2 * wall, h = body_h);  // hollow, open top
    }
}

body();
```

Prefer **build123d** (Template C) when you need Python logic, selective fillets,
or STEP export — it supersedes CadQuery (same OCP kernel, cleaner API) and gates
through trimesh/manifold3d. Reach for OpenSCAD only for fast constructive-solid
parts. Either way verify: min wall ≥ 0.8 mm FDM, overhangs > 45° need chamfers
or support, and the mesh must pass the Phase 2 watertight/manifold gate.
