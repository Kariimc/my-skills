"""ReliefBackend — real, GPU-free image→3D.

Turns an actual image into a real textured mesh derived from its content:
- `.glb` / `.gltf`  → a **watertight SOLID** (front relief + flat back + side
  walls), textured, engine-native — opens straight in UE5/Unity/Blender.
- `.obj`            → a textured relief surface + MTL + texture (pure writer,
  zero extra deps).

This is the verified baseline that runs anywhere — unlimited and free. The
high-quality full-3D path (TRELLIS / TripoSR) lives in mesh.py and needs a GPU.

Needs Pillow + numpy (+ trimesh only for the `.glb` solid export).
"""
from __future__ import annotations

import sys
from pathlib import Path

from .base import Backend, ImageRequest, MeshRequest


class ReliefBackend(Backend):
    name = "relief"

    def __init__(self, grid: int = 192, depth: float = 0.18, invert: bool = False):
        self.grid = max(8, int(grid))
        self.depth = float(depth)
        self.invert = bool(invert)

    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        raise NotImplementedError("ReliefBackend is image→3D only; use the image backend for pictures.")

    # --- shared height-field computation ------------------------------------
    def _heightfield(self, req: MeshRequest):
        from PIL import Image, ImageOps, ImageFilter
        import numpy as np

        img = Image.open(req.image_path).convert("RGB")
        w0, h0 = img.size
        scale = self.grid / max(w0, h0)
        gw, gh = max(2, round(w0 * scale)), max(2, round(h0 * scale))
        small = img.resize((gw, gh), Image.LANCZOS)

        lum = ImageOps.grayscale(small).filter(ImageFilter.GaussianBlur(1))
        H = np.asarray(lum, dtype=np.float32) / 255.0
        if self.invert:
            H = 1.0 - H
        H -= H.min()
        if H.max() > 0:
            H /= H.max()

        aspect = gw / gh
        ax, ay = (aspect, 1.0) if aspect >= 1 else (1.0, 1.0 / aspect)
        xs = (np.linspace(0, 1, gw) - 0.5) * ax
        ys = (0.5 - np.linspace(0, 1, gh)) * ay
        return img, H, xs, ys, gw, gh

    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        out_path = Path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        img, H, xs, ys, gw, gh = self._heightfield(req)

        if out_path.suffix.lower() in (".glb", ".gltf"):
            try:
                self._export_solid(img, H, xs, ys, gw, gh, out_path)
                return out_path
            except Exception as e:  # trimesh missing → degrade to OBJ surface
                sys.stderr.write(f"[relief] solid GLB needs trimesh ({e}); writing OBJ instead\n")
                out_path = out_path.with_suffix(".obj")

        return self._export_obj_surface(img, H, xs, ys, gw, gh, out_path)

    # --- watertight solid GLB (trimesh) -------------------------------------
    def _export_solid(self, img, H, xs, ys, gw, gh, out_path: Path):
        import numpy as np
        import trimesh

        base = max(self.depth * 0.5, 1e-3)
        X, Y = np.meshgrid(xs, ys)                       # (gh, gw)
        front = np.stack([X, Y, base + H * self.depth], -1).reshape(-1, 3)
        back = np.stack([X, Y, np.zeros_like(H)], -1).reshape(-1, 3)
        verts = np.concatenate([front, back], 0)
        N = gw * gh

        def fi(i, j): return j * gw + i
        def bi(i, j): return N + j * gw + i

        faces = []
        for j in range(gh - 1):                          # front (+z)
            for i in range(gw - 1):
                a, b, c, d = fi(i, j), fi(i + 1, j), fi(i + 1, j + 1), fi(i, j + 1)
                faces += [[a, b, c], [a, c, d]]
        for j in range(gh - 1):                          # back (−z), reversed
            for i in range(gw - 1):
                a, b, c, d = bi(i, j), bi(i + 1, j), bi(i + 1, j + 1), bi(i, j + 1)
                faces += [[a, c, b], [a, d, c]]
        for i in range(gw - 1):                          # top + bottom walls
            faces += [[fi(i, 0), bi(i, 0), bi(i + 1, 0)], [fi(i, 0), bi(i + 1, 0), fi(i + 1, 0)]]
            jj = gh - 1
            faces += [[fi(i + 1, jj), bi(i + 1, jj), bi(i, jj)], [fi(i + 1, jj), bi(i, jj), fi(i, jj)]]
        for j in range(gh - 1):                          # left + right walls
            faces += [[fi(0, j + 1), bi(0, j + 1), bi(0, j)], [fi(0, j + 1), bi(0, j), fi(0, j)]]
            ii = gw - 1
            faces += [[fi(ii, j), bi(ii, j), bi(ii, j + 1)], [fi(ii, j), bi(ii, j + 1), fi(ii, j + 1)]]

        u = np.tile(np.linspace(0, 1, gw), gh)
        v = 1 - np.repeat(np.linspace(0, 1, gh), gw)
        uv = np.concatenate([np.stack([u, v], -1)] * 2, 0)

        mesh = trimesh.Trimesh(
            vertices=verts, faces=np.asarray(faces, np.int64),
            visual=trimesh.visual.TextureVisuals(uv=uv, image=img), process=False)
        mesh.merge_vertices()
        mesh.fix_normals()
        mesh.export(str(out_path))
        return mesh

    # --- textured OBJ surface (pure writer, no extra deps) ------------------
    def _export_obj_surface(self, img, H, xs, ys, gw, gh, out_path: Path):
        if out_path.suffix.lower() != ".obj":
            out_path = out_path.with_suffix(".obj")
        tex = f"{out_path.stem}_tex.png"
        mtl = f"{out_path.stem}.mtl"
        img.save(out_path.parent / tex)
        (out_path.parent / mtl).write_text(
            f"newmtl relief\nKa 1 1 1\nKd 1 1 1\nmap_Kd {tex}\n")

        v, vt, f = [], [], []
        for j in range(gh):
            for i in range(gw):
                v.append(f"v {xs[i]:.5f} {ys[j]:.5f} {H[j, i] * self.depth:.5f}")
                vt.append(f"vt {i / (gw - 1):.5f} {1 - j / (gh - 1):.5f}")

        def idx(i, j): return j * gw + i + 1

        for j in range(gh - 1):
            for i in range(gw - 1):
                a, b, c, d = idx(i, j), idx(i + 1, j), idx(i + 1, j + 1), idx(i, j + 1)
                f += [f"f {a}/{a} {b}/{b} {c}/{c}", f"f {a}/{a} {c}/{c} {d}/{d}"]

        out_path.write_text("\n".join([f"mtllib {mtl}", "usemtl relief", *v, *vt, *f]) + "\n")
        return out_path
