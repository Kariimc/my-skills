"""Model registry + hardware-aware auto-selection.

Defaults favor PERMISSIVE licenses (Apache-2.0 / MIT) so generation is free for
personal AND commercial use. Always verify a model's current license yourself —
license terms change. `min_vram_gb` is a practical floor for usable speed.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ImageModel:
    id: str            # Hugging Face repo id
    label: str
    min_vram_gb: float
    license: str
    default_steps: int
    pipeline: str      # "flux" | "sdxl" | "sd"


# Ordered best→lightest. FLUX.1-schnell is the headline free/commercial option.
IMAGE_MODELS = {
    "flux-schnell": ImageModel(
        "black-forest-labs/FLUX.1-schnell", "FLUX.1-schnell", 12,
        "Apache-2.0 (free, commercial OK)", 4, "flux"),
    "sdxl": ImageModel(
        "stabilityai/stable-diffusion-xl-base-1.0", "SDXL 1.0", 8,
        "CreativeML OpenRAIL++-M (free)", 30, "sdxl"),
    "sdxl-turbo": ImageModel(
        "stabilityai/sdxl-turbo", "SDXL-Turbo", 6,
        "STAI Non-Commercial (free, personal)", 2, "sdxl"),
    "sd15": ImageModel(
        "stable-diffusion-v1-5/stable-diffusion-v1-5", "SD 1.5", 4,
        "CreativeML OpenRAIL-M (free)", 25, "sd"),
}


@dataclass(frozen=True)
class MeshModel:
    id: str
    label: str
    min_vram_gb: float
    license: str
    runner: str        # "trellis" | "hunyuan3d" | "triposr"


MESH_MODELS = {
    "trellis": MeshModel(
        "microsoft/TRELLIS-image-large", "TRELLIS (image-large)", 16,
        "MIT (free, commercial OK)", "trellis"),
    "hunyuan3d": MeshModel(
        "tencent/Hunyuan3D-2", "Hunyuan3D-2", 12,
        "Tencent Hunyuan Community (free self-host; verify terms)", "hunyuan3d"),
    "triposr": MeshModel(
        "stabilityai/TripoSR", "TripoSR", 6,
        "MIT (free, fast, ~6GB)", "triposr"),
}


def autoselect_image(vram_gb: float) -> str:
    if vram_gb >= 12:
        return "flux-schnell"
    if vram_gb >= 8:
        return "sdxl"
    if vram_gb >= 6:
        return "sdxl-turbo"
    return "sd15"


def autoselect_mesh(vram_gb: float) -> str:
    if vram_gb >= 16:
        return "trellis"
    if vram_gb >= 12:
        return "hunyuan3d"
    return "triposr"
