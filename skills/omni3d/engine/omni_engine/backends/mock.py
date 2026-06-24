"""MockBackend — produces REAL, valid placeholder files with zero dependencies.

It writes a genuine PNG (correct signature + IHDR dimensions) and a genuine
Wavefront OBJ cube, so the end-to-end CLI/pipeline plumbing can be verified on
any machine with no GPU, no model downloads, and no extra packages. Swapping in
a real backend changes only the pixels/geometry, not the data flow.
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

from .base import Backend, ImageRequest, MeshRequest


def _png_bytes(w: int, h: int, rgb=(60, 90, 160)) -> bytes:
    """Minimal valid 8-bit RGB PNG of a solid color (no Pillow needed)."""
    def chunk(typ: bytes, data: bytes) -> bytes:
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF))

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)  # color type 2 = RGB
    row = b"\x00" + bytes(rgb) * w                        # filter byte 0 + pixels
    raw = row * h
    idat = zlib.compress(raw)
    return sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")


_CUBE_OBJ = """# omni3d mock cube
v -0.5 -0.5 -0.5
v  0.5 -0.5 -0.5
v  0.5  0.5 -0.5
v -0.5  0.5 -0.5
v -0.5 -0.5  0.5
v  0.5 -0.5  0.5
v  0.5  0.5  0.5
v -0.5  0.5  0.5
f 1 2 3 4
f 5 6 7 8
f 1 5 8 4
f 2 6 7 3
f 4 3 7 8
f 1 2 6 5
"""


class MockBackend(Backend):
    name = "mock"

    def generate_image(self, req: ImageRequest, out_path: Path) -> Path:
        out_path = Path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_bytes(_png_bytes(req.width, req.height))
        return out_path

    def image_to_3d(self, req: MeshRequest, out_path: Path) -> Path:
        out_path = Path(out_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        # Always emit a valid OBJ regardless of requested extension, so tests are
        # deterministic; real backends honor .glb/.obj.
        out_path.write_text(_CUBE_OBJ)
        return out_path
