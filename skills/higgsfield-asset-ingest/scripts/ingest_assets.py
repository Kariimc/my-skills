#!/usr/bin/env python3
"""Reliably import recently downloaded Higgsfield assets into a project."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

MEDIA_EXTS = {
    ".png", ".jpg", ".jpeg", ".webp", ".gif", ".avif", ".svg",
    ".mp4", ".mov", ".webm", ".m4v", ".avi", ".mkv",
    ".wav", ".mp3", ".m4a", ".aac", ".flac",
    ".zip",
}
PARTIAL_EXTS = {".crdownload", ".download", ".part", ".tmp"}
DEFAULT_SOURCE_NAMES = ["Downloads", "Desktop"]
DEST_CANDIDATES = [
    "public/assets/higgsfield",
    "public/assets/generated",
    "public/images/higgsfield",
    "src/assets/higgsfield",
    "assets/higgsfield",
    "app/assets/higgsfield",
]


@dataclass
class Asset:
    source: Path
    digest: str
    ext: str
    size: int
    mtime: float
    kind: str


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return re.sub(r"-+", "-", text).strip("-") or "asset"


def kind_for(ext: str) -> str:
    if ext in {".mp4", ".mov", ".webm", ".m4v", ".avi", ".mkv"}:
        return "video"
    if ext in {".wav", ".mp3", ".m4a", ".aac", ".flac"}:
        return "audio"
    if ext == ".zip":
        return "archive"
    return "image"


def source_dirs(args: argparse.Namespace) -> list[Path]:
    if args.source:
        return [Path(p).expanduser().resolve() for p in args.source]
    home = Path.home()
    return [(home / name).resolve() for name in DEFAULT_SOURCE_NAMES if (home / name).exists()]


def choose_dest(project: Path, explicit: str | None) -> Path:
    if explicit:
        return (project / explicit).resolve() if not Path(explicit).is_absolute() else Path(explicit).resolve()
    for rel in DEST_CANDIDATES:
        parent = project / Path(rel).parent
        if parent.exists():
            return (project / rel).resolve()
    return (project / DEST_CANDIDATES[0]).resolve()


def existing_digests(manifest_path: Path, dest: Path) -> set[str]:
    seen: set[str] = set()
    if manifest_path.exists():
        try:
            data = json.loads(manifest_path.read_text())
            for item in data.get("assets", []):
                if item.get("sha256"):
                    seen.add(item["sha256"])
        except Exception:
            pass
    if dest.exists():
        for path in dest.rglob("*"):
            if path.is_file() and path.suffix.lower() in MEDIA_EXTS:
                try:
                    seen.add(sha256(path))
                except OSError:
                    continue
    return seen


def scan(paths: list[Path], since_hours: float | None) -> list[Asset]:
    cutoff = None
    if since_hours is not None:
        cutoff = datetime.now(timezone.utc).timestamp() - since_hours * 3600
    assets: list[Asset] = []
    for root in paths:
        if not root.exists():
            continue
        files = root.rglob("*") if root.is_dir() else [root]
        for path in files:
            if not path.is_file():
                continue
            ext = path.suffix.lower()
            if ext in PARTIAL_EXTS or ext not in MEDIA_EXTS:
                continue
            try:
                st = path.stat()
            except OSError:
                continue
            if cutoff and st.st_mtime < cutoff:
                continue
            assets.append(Asset(path, sha256(path), ext, st.st_size, st.st_mtime, kind_for(ext)))
    return sorted(assets, key=lambda a: (a.mtime, str(a.source)))


def unique_path(dest: Path, base: str, ext: str) -> Path:
    candidate = dest / f"{base}{ext}"
    i = 2
    while candidate.exists():
        candidate = dest / f"{base}-{i}{ext}"
        i += 1
    return candidate


def load_manifest(path: Path) -> dict:
    if path.exists():
        try:
            return json.loads(path.read_text())
        except Exception:
            pass
    return {"schema": 1, "assets": []}


def write_outputs(manifest_path: Path, rows: list[dict]) -> None:
    manifest = load_manifest(manifest_path)
    manifest.setdefault("assets", []).extend(rows)
    manifest["updated_at"] = datetime.now(timezone.utc).isoformat()
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    csv_path = manifest_path.with_suffix(".csv")
    with csv_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["dest", "kind", "sha256", "source", "size", "imported_at"])
        writer.writeheader()
        for item in manifest["assets"]:
            writer.writerow({k: item.get(k, "") for k in writer.fieldnames})


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--project", default=".", help="Project root to receive assets")
    ap.add_argument("--source", action="append", help="Source file/folder; repeatable. Defaults to ~/Downloads and ~/Desktop")
    ap.add_argument("--dest", help="Destination folder relative to project or absolute")
    ap.add_argument("--prefix", default="higgsfield", help="Renamed asset prefix")
    ap.add_argument("--since-hours", type=float, default=72, help="Only import files modified in the last N hours; use 0 to disable")
    ap.add_argument("--move", action="store_true", help="Move instead of copy after successful import")
    ap.add_argument("--dry-run", action="store_true", help="Plan without changing files")
    args = ap.parse_args()

    project = Path(args.project).expanduser().resolve()
    dest = choose_dest(project, args.dest)
    manifest_path = dest / "higgsfield-assets.json"
    since = None if args.since_hours == 0 else args.since_hours
    found = scan(source_dirs(args), since)
    seen = existing_digests(manifest_path, dest)
    imported: list[dict] = []

    if not found:
        print("No complete media files found. Check --source or --since-hours.", file=sys.stderr)
        return 2

    if not args.dry_run:
        dest.mkdir(parents=True, exist_ok=True)

    for idx, asset in enumerate(found, start=1):
        if asset.digest in seen:
            print(f"SKIP duplicate {asset.source}")
            continue
        day = datetime.fromtimestamp(asset.mtime).strftime("%Y%m%d")
        base = slugify(f"{args.prefix}-{day}-{idx:03d}-{asset.kind}")
        target = unique_path(dest, base, asset.ext)
        rel_target = os.path.relpath(target, project)
        print(f"IMPORT {asset.source} -> {rel_target}")
        row = {
            "dest": rel_target,
            "kind": asset.kind,
            "sha256": asset.digest,
            "source": str(asset.source),
            "size": asset.size,
            "imported_at": datetime.now(timezone.utc).isoformat(),
        }
        imported.append(row)
        seen.add(asset.digest)
        if not args.dry_run:
            if args.move:
                shutil.move(str(asset.source), str(target))
            else:
                shutil.copy2(asset.source, target)

    if imported and not args.dry_run:
        write_outputs(manifest_path, imported)
    print(f"Imported {len(imported)} asset(s) into {dest}")
    return 0 if imported else 3


if __name__ == "__main__":
    raise SystemExit(main())
