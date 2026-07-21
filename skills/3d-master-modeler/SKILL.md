---
name: 3d-master-modeler
description: Autonomous 3D asset generator and technical-art engine. Builds 3D models from scratch in code — Blender Python (bpy) headless, Three.js/WebGL, OpenSCAD/CadQuery — with non-destructive modifier stacks, procedural PBR shader node networks, 3-point lighting rigs, and a headless-render verification loop. Use when the user wants to generate, model, or build a 3D asset/model/scene/mesh in code, write a Blender or bpy script, create procedural PBR materials, or render a preview of a generated model. (2D art to game asset → game-assets; AI image-to-3D → omni3d; print slicing → 3d-printing; rig/pose inspection → blender-motion-state-inspection.)
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
| Offline/production asset, film-quality render, baking, export to glTF/FBX/OBJ | **Blender `bpy`** (headless) | .blend + glTF/FBX + PNG proof renders |
| Real-time web: product viewer, game, interactive scene | **Three.js** | Single HTML file (previewable) |
| 3D printing, CAD, engineering parts, exact dimensions | **OpenSCAD** (or **CadQuery** when Python-side parametrics/STEP export needed) | .scad/.py + STL |
| User explicitly names a tool | That tool | — |

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

## Phase 4 — Lighting & camera

Standard rig (in the template):

- **Key:** Area light, warm (RGB ≈ 1.0, 0.95, 0.85), 45° front-left, above
  subject, strongest.
- **Fill:** Area light, cool (RGB ≈ 0.75, 0.85, 1.0), front-right, ~1/4 key
  energy, larger + softer.
- **Rim:** Area/Spot behind and above, white, strong enough to draw an edge
  highlight separating subject from background.
- **World:** neutral dark gray (0.02–0.05) so the rig does the work; plug an
  HDRI into an Environment Texture only if the user supplies one.
- **Camera:** 50mm, aimed via Track-To constraint at an Empty on the subject's
  bounding-box center, pulled back so the subject fills ~70% of frame with
  slight top-down angle (~15°).

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
5. On pass: export (glTF for engines/web, STL for print), delete intermediate
   renders/temp scripts, deliver final script + final render + asset path.

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

## Template B — Three.js real-time starter (single file, previewable)

WebGL build — runs everywhere. For WebGPU (r171+): import from
`three/webgpu`, `const renderer = new WebGPURenderer({antialias:true})`,
`await renderer.init()` before first frame, and prefer `MeshStandardNodeMaterial`
/ TSL for new shader work; it auto-falls back to WebGL 2.

```html
<!doctype html>
<meta charset="utf-8">
<style>html,body{margin:0;height:100%;overflow:hidden}canvas{display:block}</style>
<script type="importmap">
{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.178.0/build/three.module.js",
"three/addons/":"https://cdn.jsdelivr.net/npm/three@0.178.0/examples/jsm/"}}
</script>
<script type="module">
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(innerWidth, innerHeight);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0a0a0c);
const camera = new THREE.PerspectiveCamera(45, innerWidth / innerHeight, 0.1, 100);
camera.position.set(3, 2, 4);

// 3-point rig: warm key, cool fill, white rim + soft ambient
const key = new THREE.DirectionalLight(0xfff1e0, 3);
key.position.set(-4, 6, 4); key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
const fill = new THREE.DirectionalLight(0xdbe9ff, 0.8); fill.position.set(4, 2, 3);
const rim = new THREE.DirectionalLight(0xffffff, 2);  rim.position.set(0, 4, -6);
scene.add(key, fill, rim, new THREE.AmbientLight(0xffffff, 0.15));

// procedural geometry + PBR material (swap for the actual asset)
const geo = new THREE.CylinderGeometry(0.4, 0.4, 1, 64);
const mat = new THREE.MeshStandardMaterial({ color: 0x8a2016, roughness: 0.45, metalness: 0.0 });
const mesh = new THREE.Mesh(geo, mat);
mesh.position.y = 0.5; mesh.castShadow = true;
scene.add(mesh);

const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(20, 20),
  new THREE.MeshStandardMaterial({ color: 0x202020, roughness: 0.9 }));
ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true;
scene.add(ground);

const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 0.5, 0); controls.enableDamping = true;

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
renderer.setAnimationLoop(() => { controls.update(); renderer.render(scene, camera); });
</script>
```

Verify Three.js work through the browser tools / live preview (screenshot +
console check for WebGL errors), the same 3-angle audit as Blender.

## Template C — OpenSCAD parametric

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

CadQuery instead when you need Python logic, fillets on selected edges, or
STEP export: `result = cq.Workplane("XY").cylinder(60, 20).faces(">Z").shell(-2.4)`;
export with `cq.exporters.export(result, "asset.stl")`. Verify STLs by slicing
mentally against: manifold (OpenSCAD's Manifold backend reports errors at
render), min wall ≥ 0.8mm FDM, overhangs > 45° need chamfers or support.
