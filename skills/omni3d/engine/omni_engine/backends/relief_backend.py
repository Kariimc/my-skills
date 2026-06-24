"""ReliefBackend — real, GPU-free image→3D (2.5D relief).

Turns an actual image into a real, textured triangle mesh: luminance becomes a
height field, displaced over a grid, UV-mapped to the source image, exported as
OBJ + MTL + texture (openable in Blender / UE5 / Unity). This is the verified
baseline that runs anywhere — unlimited and free. The high-quality full-3D path
(TRELLIS / TripoSR) is in mesh.py and needs a GPU.

Needs only Pillow + numpy.
"""
from __future__ import annotations

from pathlib import Path

from .base import Backend, ImageRequest, MeshRequest


class ReliefBackend(Backend):
    name = "relief"

    def __init__(self, grid: int = 192, depth: float = 0.18, invert: bool = False):
        self.grid = max(8, int(grid))   # max grid dimension (verts along long edge)
        self.depth = float(depth)        # relief height as fraction of unit size
        self.invert = bool(invert)       # bright=high (default) vs dark=high

    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        raise NotImplementedError("ReliefBackend is image→3D only; use the image backend for pictures.")

    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        from PIL import Image, ImageOps, ImageFilter
        import numpy as np

        out_path = Path(out_path)
        if out_path.suffix.lower() != ".obj":
            out_path = out_path.with_suffix(".obj")
        out_path.parent.mkdir(parents=True, exist_ok=True)

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

        # texture + material next to the mesh
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

        def idx(i, j):
            return j * gw + i + 1

        for j in range(gh - 1):
            for i in range(gw - 1):
                a, b, c, d = idx(i, j), idx(i + 1, j), idx(i + 1, j + 1), idx(i, j + 1)
                f.append(f"f {a}/{a} {b}/{b} {c}/{c}")
                f.append(f"f {a}/{a} {c}/{c} {d}/{d}")

        out_path.write_text("\n".join([f"mtllib {mtl}", "usemtl relief", *v, *vt, *f]) + "\n")
        return out_path
