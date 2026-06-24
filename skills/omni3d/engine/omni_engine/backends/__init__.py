"""Generation backends for the Omni3D engine."""
from .base import Backend, ImageRequest, MeshRequest

__all__ = ["Backend", "ImageRequest", "MeshRequest", "get_backend"]


def get_backend(name: str, **kwargs):
    """Factory: 'mock' (no deps), 'diffusers' (real image gen on GPU)."""
    name = (name or "mock").lower()
    if name == "mock":
        from .mock import MockBackend
        return MockBackend()
    if name in ("diffusers", "real", "auto"):
        from .diffusers_backend import DiffusersBackend
        return DiffusersBackend(**kwargs)
    raise ValueError(f"unknown backend: {name!r} (use 'mock' or 'diffusers')")
