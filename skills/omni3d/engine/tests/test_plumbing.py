"""GPU-free verification of the engine plumbing using the MockBackend.

Proves the CLI produces REAL, valid files (PNG with correct dimensions, OBJ with
geometry) and that hardware auto-selection picks the right models. Swapping in a
real backend changes only the bytes, not this data flow.

Run:  python -m unittest discover -s tests   (from engine/)
"""
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ENGINE = Path(__file__).resolve().parents[1]  # .../skills/omni3d/engine


def png_dimensions(path: Path):
    b = path.read_bytes()
    assert b[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    return struct.unpack(">II", b[16:24])  # IHDR width, height


class Plumbing(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run([sys.executable, "-m", "omni_engine.cli", *args],
                              cwd=ENGINE, capture_output=True, text=True)

    def test_image_mock_writes_valid_png(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "x.png"
            r = self.run_cli("--backend", "mock", "image", "a red cube",
                             "-o", str(out), "--width", "320", "--height", "256")
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertTrue(out.exists())
            self.assertEqual(png_dimensions(out), (320, 256))

    def test_mesh_mock_writes_valid_obj(self):
        with tempfile.TemporaryDirectory() as d:
            img = Path(d) / "in.png"
            img.write_bytes(b"\x89PNG\r\n\x1a\n")
            out = Path(d) / "m.obj"
            r = self.run_cli("--backend", "mock", "mesh", str(img), "-o", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            txt = out.read_text()
            self.assertGreaterEqual(txt.count("\nv "), 8)  # 8 cube vertices
            self.assertIn("f ", txt)                        # has faces

    def test_autoselect_by_vram(self):
        sys.path.insert(0, str(ENGINE))
        from omni_engine.config import autoselect_image, autoselect_mesh
        self.assertEqual(autoselect_image(24), "flux-schnell")
        self.assertEqual(autoselect_image(8), "sdxl")
        self.assertEqual(autoselect_image(4), "sd15")
        self.assertEqual(autoselect_mesh(24), "trellis")
        self.assertEqual(autoselect_mesh(6), "triposr")

    def test_engine_imports_without_torch(self):
        # The package + factory must import even when torch/diffusers are absent.
        r = subprocess.run(
            [sys.executable, "-c",
             "import omni_engine; from omni_engine.backends import get_backend; "
             "get_backend('mock'); print('ok')"],
            cwd=ENGINE, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("ok", r.stdout)


if __name__ == "__main__":
    unittest.main()
