#!/usr/bin/env python3
"""imgdiff — numeric image comparison for the visual harness exit gate.

Usage:
    python3 imgdiff.py CANDIDATE REFERENCE [--threshold 12] [--allow-resize]

Prints native dimensions of both images (check them FIRST — a dimension
mismatch shipped repeated crop bugs), then per-channel RMSE on a 0–255 scale.

Exit codes:  0 = PASS (dims match & rmse <= threshold)
             1 = FAIL (mismatch or rmse above threshold)
             2 = error (missing file / unreadable image)

By default a dimension mismatch is an automatic FAIL even if content is close:
matching the reference's native size is part of the deliverable. Pass
--allow-resize only when the brief explicitly targets a different size.
"""
import argparse
import sys


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("candidate")
    ap.add_argument("reference")
    ap.add_argument("--threshold", type=float, default=12.0,
                    help="max RMSE (0-255 scale) to PASS; default 12")
    ap.add_argument("--allow-resize", action="store_true",
                    help="resize candidate to reference size instead of failing on mismatch")
    args = ap.parse_args()

    try:
        from PIL import Image
        import numpy as np
    except ImportError as e:
        print(f"ERROR: {e} — install pillow+numpy (3d-master-modeler/setup.sh does this)")
        return 2

    try:
        cand = Image.open(args.candidate).convert("RGB")
        ref = Image.open(args.reference).convert("RGB")
    except Exception as e:
        print(f"ERROR: cannot open image: {e}")
        return 2

    print(f"candidate: {cand.size[0]}x{cand.size[1]}  {args.candidate}")
    print(f"reference: {ref.size[0]}x{ref.size[1]}  {args.reference}")

    if cand.size != ref.size:
        if not args.allow_resize:
            print("FAIL: dimension mismatch — inspect the reference's NATIVE size and "
                  "re-render; do not crop-and-hope. (--allow-resize only if the brief "
                  "targets a different size.)")
            return 1
        cand = cand.resize(ref.size, Image.LANCZOS)
        print("note: candidate resized to reference size (--allow-resize)")

    import numpy as np
    a = np.asarray(cand, dtype=np.float64)
    b = np.asarray(ref, dtype=np.float64)
    rmse = float(np.sqrt(((a - b) ** 2).mean()))
    per = [float(np.sqrt(((a[..., i] - b[..., i]) ** 2).mean())) for i in range(3)]
    print(f"rmse: {rmse:.2f}  (R {per[0]:.2f} / G {per[1]:.2f} / B {per[2]:.2f})  threshold: {args.threshold}")

    if rmse <= args.threshold:
        print("PASS")
        return 0
    print("FAIL: above threshold — find the largest-error region and correct it "
          "(np.abs(a-b).mean(axis=2) heatmap localizes it), then re-render.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
