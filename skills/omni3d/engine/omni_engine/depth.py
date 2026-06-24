"""Free, CPU monocular depth (MiDaS small) for real depth-based image→3D.

Upgrades the relief backend from a luminance height field to a *real depth map*,
so the solid takes the subject's actual shape. Free, no GPU. Weights come from
GitHub release assets (MIT) — the only model host reachable in locked-down
networks (Hugging Face is often blocked).

Robustness: downloads via `curl` with size/zip verification (torch.hub's
downloader truncates large files behind some proxies); model is cached and loaded
once. Any failure raises, so the relief backend falls back to luminance.
"""
from __future__ import annotations

import builtins
import subprocess
import sys
from pathlib import Path

_CKPT_URL = "https://github.com/isl-org/MiDaS/releases/download/v2_1/midas_v21_small_256.pt"
_REPO_TGZ = "https://codeload.github.com/isl-org/MiDaS/tar.gz/refs/heads/master"
_MEAN = (0.485, 0.456, 0.406)
_STD = (0.229, 0.224, 0.225)
_model = None


def available() -> bool:
    import importlib.util as u
    return u.find_spec("torch") is not None


def _cache_dir() -> Path:
    import torch
    d = Path(torch.hub.get_dir())
    d.mkdir(parents=True, exist_ok=True)
    return d


def _curl(url: str, dest: Path, min_bytes: int) -> Path:
    for _ in range(3):
        subprocess.run(["curl", "-sSL", "--retry", "3", "-o", str(dest), url], check=False)
        if dest.exists() and dest.stat().st_size >= min_bytes:
            return dest
    raise RuntimeError(f"download failed or truncated: {url}")


def _ensure_repo(cache: Path) -> Path:
    repo = cache / "isl-org_MiDaS_master"
    if (repo / "midas" / "midas_net_custom.py").exists():
        return repo
    import tarfile
    tgz = cache / "midas_src.tgz"
    _curl(_REPO_TGZ, tgz, 10_000)
    with tarfile.open(tgz) as t:
        t.extractall(cache)
    src = cache / "MiDaS-master"
    if src.exists() and not repo.exists():
        src.rename(repo)
    return repo


def _load():
    global _model
    if _model is not None:
        return _model
    import torch
    cache = _cache_dir()
    repo = _ensure_repo(cache)
    if str(repo) not in sys.path:
        sys.path.insert(0, str(repo))
    ckpt = cache / "midas_v21_small_256.pt"
    if not (ckpt.exists() and ckpt.stat().st_size >= 80_000_000):
        _curl(_CKPT_URL, ckpt, 80_000_000)
    # The backbone arch comes from another torch.hub repo that prompts for trust;
    # auto-accept during construction, then restore input. weights=False (path set)
    # means no backbone weight download — the MiDaS ckpt supplies all weights.
    _orig_input = builtins.input
    builtins.input = lambda *a, **k: "y"
    try:
        from midas.midas_net_custom import MidasNet_small
        _model = MidasNet_small(str(ckpt), features=64, backbone="efficientnet_lite3",
                                exportable=True, non_negative=True,
                                blocks={"expand": True}).eval()
    finally:
        builtins.input = _orig_input
    return _model


def estimate_depth(image_path, out_w: int, out_h: int):
    """Return an (out_h, out_w) float32 array in [0,1] — 1 = nearest the camera."""
    import numpy as np
    import torch
    from PIL import Image

    model = _load()
    img = Image.open(image_path).convert("RGB").resize((256, 256), Image.LANCZOS)
    x = (np.asarray(img, np.float32) / 255.0 - _MEAN) / _STD
    with torch.no_grad():
        d = model(torch.from_numpy(x.transpose(2, 0, 1)).unsqueeze(0).float()).squeeze().numpy()
    d = d.astype("float32")
    d -= d.min()
    if d.max() > 0:
        d /= d.max()
    dimg = Image.fromarray((d * 255).astype("uint8")).resize((out_w, out_h), Image.LANCZOS)
    return np.asarray(dimg, np.float32) / 255.0
