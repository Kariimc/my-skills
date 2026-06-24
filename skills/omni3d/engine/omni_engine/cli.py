"""omni-engine CLI — free local image + 3D generation.

Examples:
  python -m omni_engine.cli --backend mock image "a bronze knight" -o knight.png
  python -m omni_engine.cli --backend diffusers image "a bronze knight" -o knight.png
  python -m omni_engine.cli --backend diffusers mesh knight.png -o knight.glb
"""
from __future__ import annotations

import argparse
from pathlib import Path

from .backends import get_backend, ImageRequest, MeshRequest


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="omni-engine",
                                description="Free local image + 3D generation for Omni3D.")
    p.add_argument("--backend", default="mock",
                   help="mock (no GPU/deps, for testing) | diffusers (real, GPU)")
    sub = p.add_subparsers(dest="cmd", required=True)

    pi = sub.add_parser("image", help="text → image")
    pi.add_argument("prompt")
    pi.add_argument("-o", "--out", default="out.png")
    pi.add_argument("--negative", default="")
    pi.add_argument("--width", type=int, default=1024)
    pi.add_argument("--height", type=int, default=1024)
    pi.add_argument("--steps", type=int, default=0)
    pi.add_argument("--seed", type=int, default=None)
    pi.add_argument("--model", default="auto",
                    help="auto | flux-schnell | sdxl | sdxl-turbo | sd15")

    pm = sub.add_parser("mesh", help="image → 3D model")
    pm.add_argument("image")
    pm.add_argument("-o", "--out", default="out.glb")
    pm.add_argument("--seed", type=int, default=None)
    pm.add_argument("--no-texture", action="store_true")
    pm.add_argument("--model", default="auto",
                    help="auto | triposr | trellis | relief (relief = GPU-free baseline)")

    a = p.parse_args(argv)

    if a.cmd == "image":
        if a.backend == "mock":
            backend = get_backend("mock")
        else:
            backend = get_backend("diffusers", image_model=a.model)
        target = lambda: backend.generate_image(
            ImageRequest(prompt=a.prompt, negative_prompt=a.negative,
                         width=a.width, height=a.height, steps=a.steps, seed=a.seed),
            Path(a.out))
    else:  # mesh
        backend = get_backend("mock") if a.backend == "mock" \
            else get_backend("mesh", model=a.model)
        target = lambda: backend.image_to_3d(
            MeshRequest(image_path=Path(a.image), texture=not a.no_texture, seed=a.seed),
            Path(a.out))

    try:
        out = target()
        print(f"wrote {out}")
        return 0
    finally:
        backend.close()


if __name__ == "__main__":
    raise SystemExit(main())
