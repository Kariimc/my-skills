"""Preflight doctor: checks the environment and recommends models by VRAM.

Runs with no heavy deps installed (it just reports what's missing).
"""
from __future__ import annotations

import importlib.util
import json
import sys

from .config import IMAGE_MODELS, MESH_MODELS, autoselect_image, autoselect_mesh


def _have(mod: str) -> bool:
    return importlib.util.find_spec(mod) is not None


def check() -> dict:
    report = {"python": sys.version.split()[0], "ok": True, "checks": [],
              "gpu": None, "vram_gb": 0.0}

    def add(name, ok, detail=""):
        report["checks"].append({"name": name, "ok": bool(ok), "detail": detail})
        if not ok:
            report["ok"] = False

    add("python>=3.9", sys.version_info[:2] >= (3, 9), report["python"])
    for mod in ("torch", "diffusers", "transformers", "PIL"):
        ok = _have(mod)
        add(f"pip:{mod}", ok, "installed" if ok else "missing → run engine/setup.sh")

    vram, gpu = 0.0, None
    if _have("torch"):
        try:
            import torch
            if torch.cuda.is_available():
                gpu = torch.cuda.get_device_name(0)
                vram = torch.cuda.get_device_properties(0).total_memory / 1e9
            else:
                mps = getattr(getattr(torch, "backends", None), "mps", None)
                if mps is not None and mps.is_available():
                    gpu = "Apple MPS (shared memory)"
        except Exception as e:  # pragma: no cover - hardware dependent
            add("torch.cuda probe", False, str(e))
    report["gpu"], report["vram_gb"] = gpu, round(vram, 1)
    add("gpu", gpu is not None,
        gpu or "no CUDA/MPS GPU — real generation will be very slow (use --backend mock to test plumbing)")

    report["recommend_image"] = autoselect_image(vram)
    report["recommend_mesh"] = autoselect_mesh(vram)
    return report


def main() -> int:
    r = check()
    print(json.dumps(r, indent=2))
    img, mesh = IMAGE_MODELS[r["recommend_image"]], MESH_MODELS[r["recommend_mesh"]]
    print()
    print(f"GPU: {r['gpu'] or 'none'} | VRAM: {r['vram_gb']} GB")
    print(f"→ image model: {r['recommend_image']}  ({img.label}; {img.license})")
    print(f"→ 3D model:    {r['recommend_mesh']}  ({mesh.label}; {mesh.license})")
    print("OK — ready" if r["ok"] else "MISSING DEPS — run engine/setup.sh (mock backend still works)")
    return 0 if r["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
