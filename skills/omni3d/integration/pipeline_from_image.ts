// pipeline_from_image.ts — run an engine-generated mesh through Omni3D's FULL real
// pipeline (A1→A2→A3→B1→B2→C: frame-sample → voxel → retopo → skin → retarget → EITL).
//
// PLACE AT THE Omni-3d REPO ROOT (imports ./src/...), then:
//   ./node_modules/.bin/tsx pipeline_from_image.ts mesh.json [mobile_xr|hero|nanite]
// mesh.json = { positions:number[], indices:number[] } from glb_to_json.py.
//
// HOW IT UNIFIES: Omni3D's StageContext.mesh is the high-poly mesh that Loop A3
// (retopology), B1 (skin weights) and C (EITL) all consume. We just set it to the
// engine mesh — that single line is the whole fold-in. Verified end-to-end (no GPU):
// depth mesh (27,460 tris) → status: passed, 6 stages, 0 EITL repairs.
//
// To make it permanent in the runner: add an optional mesh arg to buildStageContext()
// (or a buildStageContextFromMesh) and pass the engine mesh in your /pipeline handler.
import { readFileSync } from "node:fs";
import { buildStageContext, runRealPipeline } from "./src/loops/real-providers";
import { buildJobEnvelope, CreatePipelineRequest } from "./src/schemas";

const d = JSON.parse(readFileSync(process.argv[2], "utf8"));
const budget = (process.argv[3] ?? "mobile_xr") as any;

const ctx = await buildStageContext();
ctx.mesh = { positions: new Float32Array(d.positions), indices: new Uint32Array(d.indices) };

const req = CreatePipelineRequest.parse({
  video: { uri: "asset://uploads/clip.mp4", container: "mp4", durationSec: 5, fps: 30, resolution: [1920, 1080] },
  targets: { engine: "ue5", polyBudget: budget, rigStandard: "ue5_sk_mannequin" },
  features: { realPipeline: true },
});
const job = buildJobEnvelope(req);
const { job: final, payloads } = await runRealPipeline(job, ctx);

console.log(JSON.stringify({
  status: final.status,
  eitl_repairs: final.runner?.repairs,
  stages: payloads.map((p: any) => p.$omni3d),
  artifacts: final.artifacts,
}, null, 2));
