"""ReliefBackend — real, GPU-free image→3D.

Turns an actual image into a real textured mesh derived from its content:
- `.glb` / `.gltf` → a **watertight SOLID**. With subject isolation on (default),
  the background is removed so the solid takes the *subject's silhouette* (a star
  becomes a star), not a rectangular slab. Front relief + flat back + walls,
  textured, engine-native — opens in UE5/Unity/Blender.
- `.obj`           → a textured relief surface + MTL + texture (pure writer).

Verified baseline that runs anywhere — unlimited and free. The high-quality
full-3D path (TRELLIS / TripoSR) lives in mesh.py and needs a GPU.

Needs Pillow + numpy (+ trimesh + scipy for the `.glb` solid / isolation).
"""
from __future__ import annotations

import sys
from pathlib import Path

from .base import Backend, ImageRequest, MeshRequest


class ReliefBackend(Backend):
    name = "relief"

    def __init__(self, grid: int = 192, depth: float = 0.18,
                 invert: bool = False, isolate: bool = True, source: str = "luminance"):
        self.grid = max(8, int(grid))
        self.depth = float(depth)
        self.invert = bool(invert)
        self.isolate = bool(isolate)
        self.source = source            # "luminance" | "depth" (MiDaS, real depth)

    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        raise NotImplementedError("ReliefBackend is image→3D only; use the image backend for pictures.")

    @staticmethod
    def _luminance(small, np):
        from PIL import ImageFilter, ImageOps
        lum = ImageOps.grayscale(small).filter(ImageFilter.GaussianBlur(1))
        return np.asarray(lum, dtype=np.float32) / 255.0

    # --- shared height-field computation ------------------------------------
    def _heightfield(self, req: MeshRequest):
        from PIL import Image
        import numpy as np

        img = Image.open(req.image_path).convert("RGB")
        w0, h0 = img.size
        scale = self.grid / max(w0, h0)
        gw, gh = max(2, round(w0 * scale)), max(2, round(h0 * scale))
        small = img.resize((gw, gh), Image.LANCZOS)

        if self.source == "depth":
            try:
                from .. import depth as depth_mod
                H = depth_mod.estimate_depth(req.image_path, gw, gh)   # real MiDaS depth
            except Exception as e:
                sys.stderr.write(f"[relief] depth model unavailable ({e}); using luminance\n")
                H = self._luminance(small, np)
        else:
            H = self._luminance(small, np)

        if self.invert:
            H = 1.0 - H
        H = H - H.min()
        if H.max() > 0:
            H = H / H.max()

        aspect = gw / gh
        ax, ay = (aspect, 1.0) if aspect >= 1 else (1.0, 1.0 / aspect)
        xs = (np.linspace(0, 1, gw) - 0.5) * ax
        ys = (0.5 - np.linspace(0, 1, gh)) * ay
        return img, small, H, xs, ys, gw, gh

    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        out_path = Path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        img, small, H, xs, ys, gw, gh = self._heightfield(req)

        if out_path.suffix.lower() in (".glb", ".gltf"):
            try:
                self._export_solid(img, small, H, xs, ys, gw, gh, out_path)
                return out_path
            except Exception as e:
                sys.stderr.write(f"[relief] solid GLB needs trimesh/scipy ({e}); writing OBJ instead\n")
                out_path = out_path.with_suffix(".obj")

        return self._export_obj_surface(img, H, xs, ys, gw, gh, out_path)

    # --- foreground mask (numpy + scipy, no model) --------------------------
    def _foreground_mask(self, small, gw, gh):
        import numpy as np
        try:
            from scipy import ndimage
        except Exception:
            return None
        arr = np.asarray(small, dtype=np.float32)            # (gh, gw, 3)
        border = np.concatenate([arr[0], arr[-1], arr[:, 0], arr[:, -1]], 0)
        bg = np.median(border, 0)
        dist = np.linalg.norm(arr - bg, axis=-1)             # distance from bg color
        thr = max(28.0, float(dist.mean()))
        fg = dist > thr
        fg = ndimage.binary_fill_holes(fg)
        lbl, n = ndimage.label(fg)
        if n > 1:                                            # keep largest blob
            sizes = ndimage.sum(np.ones_like(lbl), lbl, range(1, n + 1))
            fg = lbl == (int(np.argmax(sizes)) + 1)
        fg = ndimage.binary_closing(fg, iterations=1)
        return fg

    # --- watertight solid GLB (trimesh) -------------------------------------
    def _export_solid(self, img, small, H, xs, ys, gw, gh, out_path: Path):
        import numpy as np
        import trimesh

        base = max(self.depth * 0.5, 1e-3)
        X, Y = np.meshgrid(xs, ys)
        front = np.stack([X, Y, base + H * self.depth], -1).reshape(-1, 3)
        back = np.stack([X, Y, np.zeros_like(H)], -1).reshape(-1, 3)
        verts = np.concatenate([front, back], 0)
        u = np.tile(np.linspace(0, 1, gw), gh)
        v = 1 - np.repeat(np.linspace(0, 1, gh), gw)
        uv = np.concatenate([np.stack([u, v], -1)] * 2, 0)

        cell_full = np.ones((gh - 1, gw - 1), bool)
        cell, used_mask = cell_full, False
        if self.isolate:
            mask = self._foreground_mask(small, gw, gh)
            if mask is not None:
                c = mask[:-1, :-1] & mask[:-1, 1:] & mask[1:, :-1] & mask[1:, 1:]
                if 0.02 < c.mean() < 0.95:          # a real subject, not all/none
                    cell, used_mask = c, True

        mesh = self._build(verts, uv, cell, gw, gh, img)
        if used_mask and not mesh.is_watertight:    # safety: never ship a hole
            mesh = self._build(verts, uv, cell_full, gw, gh, img)
        mesh.export(str(out_path))
        return mesh

    def _build(self, verts, uv, cell, gw, gh, img):
        import numpy as np
        import trimesh

        N = gw * gh

        def fi(i, j): return j * gw + i
        def bi(i, j): return N + j * gw + i

        faces = []
        for j in range(gh - 1):
            for i in range(gw - 1):
                if not cell[j, i]:
                    continue
                a, b, c, d = fi(i, j), fi(i + 1, j), fi(i + 1, j + 1), fi(i, j + 1)
                pa, pb, pc, pd = bi(i, j), bi(i + 1, j), bi(i + 1, j + 1), bi(i, j + 1)
                faces += [[a, b, c], [a, c, d]]                 # front (+z)
                faces += [[pa, pc, pb], [pa, pd, pc]]           # back (−z)
                if j == 0 or not cell[j - 1, i]:                # top wall (a-b)
                    faces += [[a, pa, pb], [a, pb, b]]
                if i == gw - 2 or not cell[j, i + 1]:           # right wall (b-c)
                    faces += [[b, pb, pc], [b, pc, c]]
                if j == gh - 2 or not cell[j + 1, i]:           # bottom wall (c-d)
                    faces += [[c, pc, pd], [c, pd, d]]
                if i == 0 or not cell[j, i - 1]:                # left wall (d-a)
                    faces += [[d, pd, pa], [d, pa, a]]

        mesh = trimesh.Trimesh(
            vertices=verts, faces=np.asarray(faces, np.int64),
            visual=trimesh.visual.TextureVisuals(uv=uv, image=img), process=False)
        mesh.fix_normals()
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
