"""Backend contract for the Omni3D free local generation engine.

A Backend turns a prompt into an image, and an image into a 3D mesh. Real
backends load open-source models on your GPU; the MockBackend produces valid
placeholder files so the plumbing can be tested with no GPU and no downloads.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class ImageRequest:
    prompt: str
    negative_prompt: str = ""
    width: int = 1024
    height: int = 1024
    steps: int = 0            # 0 → use the model's default
    seed: Optional[int] = None
    guidance: Optional[float] = None


@dataclass
class MeshRequest:
    image_path: Path
    texture: bool = True
    seed: Optional[int] = None


class Backend(ABC):
    """Abstract generation backend. Implementations must write a real file to
    `out_path` and return it."""

    name: str = "base"

    @abstractmethod
    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        ...

    @abstractmethod
    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        ...

    def close(self) -> None:  # optional resource cleanup (free GPU memory, etc.)
        return None
