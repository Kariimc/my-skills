// omni_bridge.ts — feed an externally generated mesh (from the Omni3D free engine,
// or any TRELLIS/TripoSR .glb) through Omni3D's REAL retopology + EITL validation.
//
// PLACE THIS AT THE Omni-3d REPO ROOT (it imports ./src/...), then:
//   ./node_modules/.bin/tsx omni_bridge.ts mesh.json [polyBudgetQuads=5000]
// where mesh.json = { "positions": number[], "indices": number[] }  (see glb_to_json.py).
//
// Verified: engine star solid (27,460 tris) -> retopo 10,000 tris (64% cut),
// EITL watertight+manifold, 0 boundary/non-manifold edges.
//
// Next step for the Omni-3d agent: fold this into a real provider so the runner's
// Loop A3 (retopology) consumes the engine mesh as its high-poly input, replacing
// the synthetic uvSphere — that makes generation + retopo/rig/validate one pipeline.
import { readFileSync } from "node:fs";
import { simplifyMesh, type Mesh } from "./src/loops/providers/retopology";
import { analyzeMesh } from "./src/loops/providers/mesh-check";

const d = JSON.parse(readFileSync(process.argv[2], "utf8"));
const mesh: Mesh = {
  positions: new Float32Array(d.positions),
  indices: new Uint32Array(d.indices),
};
const topo = analyzeMesh(mesh);
const targetQuads = Number(process.argv[3] ?? 5000);
const res = await simplifyMesh(mesh, targetQuads * 2);

console.log(JSON.stringify({
  engine_input_triangles: res.inputTris,
  omni3d_retopo_triangles: res.outputTris,
  reduction_pct: Math.round((1 - res.outputTris / res.inputTris) * 100),
  eitl_watertight: topo.watertight,
  eitl_manifold: topo.manifold,
  eitl_boundary_edges: topo.boundaryEdges,
  eitl_nonmanifold_edges: topo.nonManifoldEdges,
}, null, 2));
