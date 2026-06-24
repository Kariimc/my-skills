"""Export a mesh (.glb/.obj) to {positions, indices} JSON for omni_bridge.ts.

Usage: python glb_to_json.py asset.glb mesh.json
Needs trimesh (pip install trimesh).
"""
import json
import sys

import trimesh


def main(src: str, dst: str) -> int:
    m = trimesh.load(src, force="mesh")
    json.dump(
        {"positions": m.vertices.flatten().tolist(),
         "indices": m.faces.flatten().astype(int).tolist()},
        open(dst, "w"))
    print(f"{src}: {len(m.vertices)} verts / {len(m.faces)} tris -> {dst}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: python glb_to_json.py <mesh.glb|obj> <out.json>", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1], sys.argv[2]))
