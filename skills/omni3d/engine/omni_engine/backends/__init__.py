"""Generation backends for the Omni3D engine."""
from .base import Backend, ImageRequest, MeshRequest

__all__ = ["Backend", "ImageRequest", "MeshRequest", "get_backend"]


def get_backend(name: str, **kwargs):
    """Factory.
    - 'mock'      : zero-dep placeholder (PNG/OBJ) for testing
    - 'diffusers' : real text→image on GPU
    - 'mesh'      : image→3D orchestrator (TripoSR/TRELLIS → relief fallback)
    - 'relief'    : GPU-free image→3D baseline (real textured mesh)
    """
    name = (name or "mock").lower()
    if name == "mock":
        from .mock import MockBackend
        return MockBackend()
    if name in ("diffusers", "real"):
        from .diffusers_backend import DiffusersBackend
        return DiffusersBackend(**kwargs)
    if name == "mesh":
        from .mesh import MeshBackend
        return MeshBackend(**kwargs)
    if name == "relief":
        from .relief_backend import ReliefBackend
        return ReliefBackend(**kwargs)
    raise ValueError(f"unknown backend: {name!r} (mock|diffusers|mesh|relief)")
