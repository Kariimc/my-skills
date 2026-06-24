#!/usr/bin/env python3
"""Render a faithful 3D preview of each relief asset (headless, no GPU/display).

The Omni3D relief solid is the subject's luminance turned into a height field and
isolated from its background. We reconstruct that exact field from the reference
image and render it as a true-colour 3D surface with matplotlib (Agg backend), so
the preview shows what the .glb actually looks like in 3D. Also writes a contact
sheet of all previews.

Usage: preview.py <refs_dir> <out_dir>
"""
from __future__ import annotations

import glob
import os
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image, ImageFilter, ImageOps
from scipy import ndimage

GRID = 150        # preview resolution (light)
DEPTH = 0.22      # matches the relief backend's z-scale feel


def height_and_color(path: str):
    img = Image.open(path).convert("RGB")
    small = img.resize((GRID, GRID), Image.LANCZOS)
    rgb = np.asarray(small, np.float32) / 255.0

    # foreground mask (same border-median trick the mesher uses)
    a = np.asarray(small, np.float32)
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]]).reshape(-1, 3)
    bg = np.median(border, 0)
    fg = np.linalg.norm(a - bg, axis=-1) > max(28.0, np.linalg.norm(a - bg, axis=-1).mean())
    fg = ndimage.binary_fill_holes(fg)

    lum = np.asarray(ImageOps.grayscale(small).filter(ImageFilter.GaussianBlur(1)),
                     np.float32) / 255.0
    lum = lum - lum[fg].min() if fg.any() else lum
    lum = np.clip(lum, 0, None)
    if lum.max() > 0:
        lum = lum / lum.max()
    H = np.where(fg, lum * DEPTH, np.nan)          # background -> NaN (not drawn)
    rgba = np.dstack([rgb, fg.astype(np.float32)])  # alpha hides background
    return H, rgba


def render_one(path: str, out: Path):
    H, rgba = height_and_color(path)
    gh, gw = H.shape
    X, Y = np.meshgrid(np.linspace(-1, 1, gw), np.linspace(1, -1, gh))

    fig = plt.figure(figsize=(4, 4), dpi=140)
    ax = fig.add_subplot(111, projection="3d")
    ax.plot_surface(X, Y, np.nan_to_num(H, nan=0.0), facecolors=rgba,
                    rcount=gh, ccount=gw, linewidth=0, antialiased=False, shade=False)
    ax.set_zlim(0, 1.1)
    ax.set_box_aspect((1, 1, 0.55))
    ax.view_init(elev=62, azim=-90)
    ax.set_axis_off()
    fig.subplots_adjust(0, 0, 1, 1)
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out, transparent=True)
    plt.close(fig)
    print(f"  preview {out.name}")


def contact_sheet(previews, out: Path, cols=3, cell=420, pad=18, bg=(248, 249, 251)):
    imgs = [Image.open(p).convert("RGBA") for p in previews]
    rows = (len(imgs) + cols - 1) // cols
    W = cols * cell + (cols + 1) * pad
    Hgt = rows * cell + (rows + 1) * pad
    sheet = Image.new("RGB", (W, Hgt), bg)
    for i, im in enumerate(imgs):
        im = im.resize((cell, cell), Image.LANCZOS)
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + pad)
        sheet.paste(im, (x, y), im)
    sheet.save(out)
    print(f"  contact sheet {out.name} ({W}x{Hgt})")


def main(argv):
    refs = Path(argv[0]) if argv else Path("refs")
    out = Path(argv[1]) if len(argv) > 1 else Path("previews")
    files = sorted(glob.glob(str(refs / "*.png")))
    print(f"rendering {len(files)} previews -> {out}/")
    previews = []
    for f in files:
        p = out / (Path(f).stem + ".png")
        render_one(f, p)
        previews.append(p)
    contact_sheet(previews, out / "_contact_sheet.png")
    print("done")


if __name__ == "__main__":
    main(sys.argv[1:])
