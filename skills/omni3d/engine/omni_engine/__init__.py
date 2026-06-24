"""Omni3D free local generation engine — text→image and image→3D on your own GPU."""
from .backends import Backend, ImageRequest, MeshRequest, get_backend

__all__ = ["Backend", "ImageRequest", "MeshRequest", "get_backend"]
__version__ = "0.1.0"
