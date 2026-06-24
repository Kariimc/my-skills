"""Real text→image backend via Hugging Face `diffusers` (runs on your GPU).

torch/diffusers are imported lazily so this module loads (and the rest of the
engine + tests run) on machines without them installed.
"""
from __future__ import annotations

from pathlib import Path
from typing import Optional

from .base import Backend, ImageRequest, MeshRequest
from ..config import IMAGE_MODELS, autoselect_image


class DiffusersBackend(Backend):
    name = "diffusers"

    def __init__(self, image_model: str = "auto", device: Optional[str] = None):
        self._key = image_model
        self._device = device
        self._pipe = None
        self._spec = None
        self._loaded_key = None

    # --- hardware helpers ---------------------------------------------------
    def _resolve_device(self) -> str:
        if self._device:
            return self._device
        import torch
        if torch.cuda.is_available():
            return "cuda"
        mps = getattr(getattr(torch, "backends", None), "mps", None)
        if mps is not None and mps.is_available():
            return "mps"
        return "cpu"

    def _vram_gb(self) -> float:
        import torch
        if torch.cuda.is_available():
            return torch.cuda.get_device_properties(0).total_memory / 1e9
        return 0.0

    # --- model loading ------------------------------------------------------
    def _load(self):
        import torch
        from diffusers import AutoPipelineForText2Image

        key = self._key
        if key in ("auto", "real", ""):
            key = autoselect_image(self._vram_gb())
        if self._pipe is not None and self._loaded_key == key:
            return self._pipe

        spec = IMAGE_MODELS[key]
        device = self._resolve_device()
        dtype = torch.float16 if device == "cuda" else torch.float32
        pipe = AutoPipelineForText2Image.from_pretrained(spec.id, torch_dtype=dtype)
        pipe = pipe.to(device)
        for opt in ("enable_attention_slicing", "enable_vae_tiling"):
            try:
                getattr(pipe, opt)()
            except Exception:
                pass
        self._pipe, self._spec, self._loaded_key = pipe, spec, key
        return pipe

    # --- API ----------------------------------------------------------------
    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        import torch

        out_path = Path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        pipe = self._load()
        spec = self._spec

        kwargs = dict(
            prompt=req.prompt,
            num_inference_steps=req.steps or spec.default_steps,
            width=req.width,
            height=req.height,
        )
        if req.negative_prompt and spec.pipeline != "flux":
            kwargs["negative_prompt"] = req.negative_prompt
        if req.guidance is not None:
            kwargs["guidance_scale"] = req.guidance
        elif spec.pipeline == "flux":
            kwargs["guidance_scale"] = 0.0  # schnell is guidance-distilled
        if req.seed is not None:
            kwargs["generator"] = torch.Generator(self._resolve_device()).manual_seed(req.seed)

        image = pipe(**kwargs).images[0]
        image.save(out_path)
        return out_path

    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        raise NotImplementedError(
            "3D generation runs through a dedicated mesh runner (TRELLIS / "
            "Hunyuan3D / TripoSR). See engine/README.md → 'Image → 3D'.")

    def close(self) -> None:
        self._pipe = None
        try:
            import gc
            import torch
            gc.collect()
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
        except Exception:
            pass
