"""MeshBackend — image→3D orchestrator with graceful fallback.

Tries the high-quality GPU runner you asked for (TRELLIS / TripoSR); if its deps
or a GPU aren't present, falls back to the always-available ReliefBackend so the
`mesh` command ALWAYS produces a real file. The fallback path is the one verified
in this repo; the GPU runners are real integration code to finalize on hardware.
"""
from __future__ import annotations

import sys
from pathlib import Path

from .base import Backend, ImageRequest, MeshRequest

_ORDER = {
    "auto":    ["triposr", "trellis", "depth", "relief"],   # GPU first, else real depth, else luminance
    "triposr": ["triposr", "depth", "relief"],
    "trellis": ["trellis", "depth", "relief"],
    "depth":   ["depth", "relief"],
    "relief":  ["relief"],
}


def _run_relief(req: MeshRequest, out_path: Path) -> Path:
    from .relief_backend import ReliefBackend
    return ReliefBackend().image_to_3d(req, out_path)


def _run_depth(req: MeshRequest, out_path: Path) -> Path:
    from .relief_backend import ReliefBackend
    return ReliefBackend(source="depth").image_to_3d(req, out_path)


def _run_triposr(req: MeshRequest, out_path: Path) -> Path:
    """High-quality single-image→mesh via TripoSR (MIT). GPU recommended.
    Install: pip install git+https://github.com/VAST-AI-Research/TripoSR.git
    (verify on hardware; raises ImportError here → falls back to relief)."""
    import torch
    from PIL import Image
    from tsr.system import TSR

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = TSR.from_pretrained("stabilityai/TripoSR",
                                config_name="config.yaml", weight_name="model.ckpt")
    model.to(device)
    image = Image.open(req.image_path).convert("RGB")
    with torch.no_grad():
        scene_codes = model([image], device=device)
    mesh = model.extract_mesh(scene_codes, resolution=256)[0]
    out_path = Path(out_path).with_suffix(".glb")
    mesh.export(str(out_path))
    return out_path


def _run_trellis(req: MeshRequest, out_path: Path) -> Path:
    """Top-tier image→3D via TRELLIS (MIT). Needs a CUDA GPU + the TRELLIS repo.
    Install: pip install git+https://github.com/microsoft/TRELLIS.git (+ extras).
    (verify on hardware; raises ImportError here → falls back to relief)."""
    from PIL import Image
    from trellis.pipelines import TrellisImageTo3DPipeline
    from trellis.utils import postprocessing_utils

    pipe = TrellisImageTo3DPipeline.from_pretrained("microsoft/TRELLIS-image-large")
    pipe.cuda()
    outputs = pipe.run(Image.open(req.image_path).convert("RGB"), seed=req.seed or 0)
    glb = postprocessing_utils.to_glb(outputs["gaussian"][0], outputs["mesh"][0])
    out_path = Path(out_path).with_suffix(".glb")
    glb.export(str(out_path))
    return out_path


_RUNNERS = {"relief": _run_relief, "depth": _run_depth,
            "triposr": _run_triposr, "trellis": _run_trellis}


class MeshBackend(Backend):
    name = "mesh"

    def __init__(self, model: str = "auto"):
        self.model = (model or "auto").lower()

    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        raise NotImplementedError("MeshBackend is image→3D only; use the image backend for pictures.")

    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        last = None
        for runner in _ORDER.get(self.model, ["relief"]):
            try:
                result = _RUNNERS[runner](req, out_path)
                if runner != "relief":
                    sys.stderr.write(f"[mesh] generated with {runner}\n")
                elif self.model != "relief":
                    sys.stderr.write("[mesh] used relief fallback (install a GPU runner for full 3D)\n")
                return result
            except Exception as e:  # ImportError, no GPU, runtime — try the next
                last = e
                if runner != "relief":
                    sys.stderr.write(f"[mesh] {runner} unavailable ({type(e).__name__}: {e}); falling back…\n")
        raise RuntimeError(f"no mesh runner succeeded: {last}")
