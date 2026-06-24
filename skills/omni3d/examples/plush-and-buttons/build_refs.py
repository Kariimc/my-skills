#!/usr/bin/env python3
"""Render clean reference images for the Omni3D mesher.

The Omni3D relief/depth backend isolates the foreground by border colour, then
turns luminance into relief height (brighter = more forward). So good inputs are:
  * a single subject on a plain, uniform background, with a clear margin, and
  * soft shading where each form is bright at its centre and darker at its edge.

We get that shading for ANY silhouette with a distance transform: paint a binary
mask, take distance-to-edge, and map it to a brightness dome. That makes plush
lobes and domed buttons that the luminance->height step reconstructs cleanly.

Outputs: <out_dir>/<name>.png  (default out_dir = ./refs)
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

SS = 2               # supersample factor (render big, downscale for anti-aliasing)
W = 1024             # final canvas size
BG = (236, 238, 242)  # plain cool-grey background (subjects must differ from this)


# ---------------------------------------------------------------------------
# low-level painting
# ---------------------------------------------------------------------------
def _mask_from_draw(draw_fn) -> np.ndarray:
    """Run an ImageDraw callback on a blank L image, return a 0..1 float mask."""
    im = Image.new("L", (W * SS, W * SS), 0)
    draw_fn(ImageDraw.Draw(im))
    return np.asarray(im, dtype=np.float32) / 255.0


def _dome(mask: np.ndarray, power: float = 0.55) -> np.ndarray:
    """Edge->centre brightness field (0 at the silhouette edge, 1 deep inside)."""
    d = ndimage.distance_transform_edt(mask > 0.5).astype(np.float32)
    if d.max() > 0:
        d /= d.max()
    return d ** power


def paint(canvas: np.ndarray, mask: np.ndarray, color, *,
          center=1.16, edge=0.52, power=0.55, feather=2.0, flat=False):
    """Composite a shaded part onto the canvas (painter's order: later = on top)."""
    color = np.asarray(color, np.float32)
    if flat:
        shade = np.full_like(mask, (center + edge) / 2.0)
    else:
        shade = edge + (center - edge) * _dome(mask, power)
    part = np.clip(color[None, None, :] * shade[..., None], 0, 255)
    alpha = mask
    if feather:
        alpha = np.asarray(
            Image.fromarray((mask * 255).astype(np.uint8)).filter(
                ImageFilter.GaussianBlur(feather)), np.float32) / 255.0
    a = alpha[..., None]
    canvas[:] = part * a + canvas * (1.0 - a)


# ---- shape helpers (coords are fractions 0..1 of the canvas) ---------------
def P(*xy):
    return tuple(int(round(c * W * SS)) for c in xy)


def ellipse(cx, cy, rx, ry):
    return lambda d: d.ellipse([P(cx - rx, cy - ry), P(cx + rx, cy + ry)], fill=255)


def circle(cx, cy, r):
    return ellipse(cx, cy, r, r)


def polygon(pts):
    return lambda d: d.polygon([P(x, y) for x, y in pts], fill=255)


def m(draw_fn):
    return _mask_from_draw(draw_fn)


def heart_pts(cx, cy, s, n=72):
    """Parametric heart silhouette centred at (cx,cy), scale s."""
    out = []
    for k in range(n):
        t = 2 * math.pi * k / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        out.append((cx + s * x / 17.0, cy - s * y / 17.0))
    return out


def eyes(canvas, pts, r=0.024):
    """Glossy dark plush eyes with a catch-light (reads cute, meshes as nubs)."""
    for cx, cy in pts:
        paint(canvas, m(circle(cx, cy, r)), (46, 40, 44), center=0.95, edge=0.32, power=0.7)
        paint(canvas, m(circle(cx - r * 0.32, cy - r * 0.34, r * 0.34)),
              (250, 250, 252), center=1.0, edge=0.9, feather=1.0, flat=True)


def new_canvas() -> np.ndarray:
    c = np.empty((W * SS, W * SS, 3), np.float32)
    c[:] = np.asarray(BG, np.float32)[None, None, :]
    return c


def finish(canvas: np.ndarray, path: Path):
    img = Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8))
    img = img.resize((W, W), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  wrote {path.name}")


# ---------------------------------------------------------------------------
# subjects
# ---------------------------------------------------------------------------
def teddy_bear(path):
    BR, BRL, DK = (150, 108, 70), (188, 152, 112), (70, 52, 48)
    c = new_canvas()
    paint(c, m(ellipse(0.27, 0.60, 0.075, 0.13)), BR)          # arms
    paint(c, m(ellipse(0.73, 0.60, 0.075, 0.13)), BR)
    paint(c, m(ellipse(0.40, 0.88, 0.095, 0.075)), BR)         # feet
    paint(c, m(ellipse(0.60, 0.88, 0.095, 0.075)), BR)
    paint(c, m(ellipse(0.40, 0.89, 0.05, 0.04)), BRL, power=0.8)   # foot pads
    paint(c, m(ellipse(0.60, 0.89, 0.05, 0.04)), BRL, power=0.8)
    paint(c, m(ellipse(0.50, 0.63, 0.25, 0.26)), BR)           # body
    paint(c, m(ellipse(0.50, 0.66, 0.15, 0.17)), BRL, power=0.7)   # tummy
    paint(c, m(circle(0.345, 0.20, 0.072)), BR)                # ears
    paint(c, m(circle(0.655, 0.20, 0.072)), BR)
    paint(c, m(circle(0.345, 0.20, 0.038)), BRL, power=0.8)
    paint(c, m(circle(0.655, 0.20, 0.038)), BRL, power=0.8)
    paint(c, m(circle(0.50, 0.35, 0.205)), BR)                 # head
    paint(c, m(ellipse(0.50, 0.41, 0.105, 0.082)), BRL, power=0.7)  # snout
    paint(c, m(ellipse(0.50, 0.375, 0.034, 0.026)), DK, center=0.9, edge=0.4)  # nose
    eyes(c, [(0.43, 0.33), (0.57, 0.33)], r=0.025)
    finish(c, path)


def bunny(path):
    CR, PK, IN = (224, 208, 184), (228, 168, 176), (236, 196, 200)
    c = new_canvas()
    paint(c, m(ellipse(0.30, 0.66, 0.06, 0.10)), CR)           # arms
    paint(c, m(ellipse(0.70, 0.66, 0.06, 0.10)), CR)
    paint(c, m(ellipse(0.41, 0.86, 0.085, 0.065)), CR)         # feet
    paint(c, m(ellipse(0.59, 0.86, 0.085, 0.065)), CR)
    paint(c, m(ellipse(0.41, 0.865, 0.045, 0.035)), PK, power=0.8)
    paint(c, m(ellipse(0.59, 0.865, 0.045, 0.035)), PK, power=0.8)
    paint(c, m(ellipse(0.50, 0.67, 0.185, 0.205)), CR)         # body
    paint(c, m(ellipse(0.435, 0.22, 0.052, 0.155)), CR)        # ears
    paint(c, m(ellipse(0.565, 0.22, 0.052, 0.155)), CR)
    paint(c, m(ellipse(0.435, 0.22, 0.026, 0.115)), IN, power=0.85)  # inner ears
    paint(c, m(ellipse(0.565, 0.22, 0.026, 0.115)), IN, power=0.85)
    paint(c, m(circle(0.50, 0.43, 0.165)), CR)                 # head
    paint(c, m(ellipse(0.445, 0.47, 0.062, 0.052)), CR, power=0.7)  # cheeks
    paint(c, m(ellipse(0.555, 0.47, 0.062, 0.052)), CR, power=0.7)
    paint(c, m(ellipse(0.50, 0.455, 0.026, 0.02)), PK, center=1.0, edge=0.5)  # nose
    eyes(c, [(0.445, 0.42), (0.555, 0.42)], r=0.023)
    finish(c, path)


def cat(path):
    GI, GL, PK, IN = (212, 138, 66), (235, 182, 120), (226, 150, 150), (236, 188, 188)
    c = new_canvas()
    paint(c, m(ellipse(0.74, 0.72, 0.055, 0.15)), GI)          # tail
    paint(c, m(ellipse(0.30, 0.66, 0.06, 0.11)), GI)           # arms
    paint(c, m(ellipse(0.70, 0.66, 0.06, 0.11)), GI)
    paint(c, m(ellipse(0.42, 0.87, 0.08, 0.06)), GI)           # feet
    paint(c, m(ellipse(0.58, 0.87, 0.08, 0.06)), GI)
    paint(c, m(ellipse(0.50, 0.67, 0.195, 0.21)), GI)          # body
    for sy in (0.60, 0.68, 0.76):                              # tabby back stripes
        paint(c, m(ellipse(0.50, sy, 0.13, 0.018)), (182, 108, 46), power=0.9, feather=3.0)
    paint(c, m(polygon([(0.355, 0.345), (0.40, 0.16), (0.475, 0.30)])), GI)  # ears
    paint(c, m(polygon([(0.645, 0.345), (0.60, 0.16), (0.525, 0.30)])), GI)
    paint(c, m(polygon([(0.378, 0.31), (0.405, 0.20), (0.452, 0.295)])), IN, power=0.9)
    paint(c, m(polygon([(0.622, 0.31), (0.595, 0.20), (0.548, 0.295)])), IN, power=0.9)
    paint(c, m(circle(0.50, 0.41, 0.175)), GI)                 # head
    paint(c, m(ellipse(0.455, 0.46, 0.058, 0.046)), GL, power=0.7)  # whisker pads
    paint(c, m(ellipse(0.545, 0.46, 0.058, 0.046)), GL, power=0.7)
    paint(c, m(polygon([(0.482, 0.445), (0.518, 0.445), (0.50, 0.47)])), PK,
          center=1.0, edge=0.55)                               # nose
    eyes(c, [(0.45, 0.40), (0.55, 0.40)], r=0.024)
    finish(c, path)


def button(path, color, holes, *, shape="round"):
    """Domed craft button: raised pad + rim ledge + recessed sew holes."""
    c = new_canvas()
    if shape == "heart":
        sil = m(polygon(heart_pts(0.5, 0.5, 0.34)))
        pad = m(polygon(heart_pts(0.5, 0.505, 0.30)))
    else:
        sil = m(circle(0.5, 0.5, 0.345))
        pad = m(circle(0.5, 0.5, 0.30))
    paint(c, sil, color, center=1.05, edge=0.42, power=0.5)        # body + rim
    paint(c, pad, np.clip(np.asarray(color) * 1.08, 0, 255),
          center=1.12, edge=0.78, power=0.6)                       # raised inner pad
    dark = tuple(int(x * 0.30) for x in color)                     # recessed holes
    for hx, hy in holes:
        paint(c, m(circle(hx, hy, 0.04)), dark, center=0.7, edge=0.25, power=0.8, feather=1.5)
    finish(c, path)


SUBJECTS = {
    "plush_teddy_bear":  lambda p: teddy_bear(p),
    "plush_bunny":       lambda p: bunny(p),
    "plush_ginger_cat":  lambda p: cat(p),
    "button_round_2hole": lambda p: button(p, (74, 140, 205),
                                           [(0.45, 0.5), (0.55, 0.5)]),
    "button_round_4hole": lambda p: button(p, (232, 196, 86),
                                           [(0.45, 0.45), (0.55, 0.45),
                                            (0.45, 0.55), (0.55, 0.55)]),
    "button_heart_2hole": lambda p: button(p, (220, 96, 120),
                                           [(0.45, 0.52), (0.55, 0.52)], shape="heart"),
}


def main(argv=None):
    out = Path(argv[0]) if argv else Path("refs")
    print(f"rendering {len(SUBJECTS)} references -> {out}/")
    for name, fn in SUBJECTS.items():
        fn(out / f"{name}.png")
    print("done")


if __name__ == "__main__":
    main(sys.argv[1:])
