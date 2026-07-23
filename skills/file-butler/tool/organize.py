#!/usr/bin/env python3
"""file-butler — keeps messy zones (Downloads, Desktop, ...) organized.

Safety contract (non-negotiable, enforced in code):
  * NEVER deletes anything. Moves only, within the same zone.
  * Every move is journaled to a manifest; --undo <manifest> reverses it all.
  * Never touches: directories (v1 is files-only), hidden/system files,
    anything inside a git repo, in-flight downloads (.crdownload/.part/.tmp),
    files modified in the last hour, or the _Sorted tree itself.
  * Dry-run by default; --apply is required to move anything.

Usage:
  python3 organize.py                      # dry-run on default zones
  python3 organize.py --apply              # actually move
  python3 organize.py --zones "C:/Users/K/Downloads" --apply
  python3 organize.py --undo <manifest.jsonl>

Stdlib only — runs on any box with Python, no installs.
"""
import argparse
import json
import os
import sys
import time
from pathlib import Path

CATEGORIES = {
    "Images":     {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".svg", ".ico", ".tiff", ".heic"},
    "Documents":  {".pdf", ".docx", ".doc", ".txt", ".md", ".rtf", ".odt", ".epub"},
    "Sheets":     {".xlsx", ".xls", ".csv", ".tsv", ".ods"},
    "Slides":     {".pptx", ".ppt", ".key", ".odp"},
    "Archives":   {".zip", ".rar", ".7z", ".tar", ".gz", ".tgz", ".bz2", ".xz"},
    "Installers": {".exe", ".msi", ".dmg", ".pkg", ".deb", ".rpm", ".appimage", ".apk"},
    "Video":      {".mp4", ".mov", ".avi", ".mkv", ".webm", ".m4v"},
    "Audio":      {".mp3", ".wav", ".flac", ".m4a", ".ogg", ".aac"},
    "3D":         {".blend", ".glb", ".gltf", ".fbx", ".obj", ".stl", ".usd", ".usdz"},
    "Fonts":      {".ttf", ".otf", ".woff", ".woff2"},
    "Code":       {".py", ".js", ".ts", ".sh", ".ps1", ".json", ".yml", ".yaml", ".html", ".css"},
}
SORTED_DIR = "_Sorted"
SKIP_SUFFIXES = {".crdownload", ".part", ".tmp", ".download"}
MIN_AGE_SECONDS = 3600  # never move a file newer than 1 hour (may be in use)


def default_zones():
    home = Path.home()
    return [p for p in (home / "Downloads", home / "Desktop") if p.is_dir()]


def in_git_repo(path: Path) -> bool:
    for parent in [path] + list(path.parents):
        if (parent / ".git").exists():
            return True
    return False


def category_for(path: Path):
    ext = path.suffix.lower()
    for cat, exts in CATEGORIES.items():
        if ext in exts:
            return cat
    return "Other"


def unique_target(target: Path) -> Path:
    if not target.exists():
        return target
    stem, suffix, parent = target.stem, target.suffix, target.parent
    for i in range(1, 1000):
        cand = parent / f"{stem} ({i}){suffix}"
        if not cand.exists():
            return cand
    raise RuntimeError(f"could not find a free name for {target}")


def plan_zone(zone: Path):
    moves = []
    now = time.time()
    for entry in sorted(zone.iterdir()):
        if entry.is_dir():
            continue                       # v1: files only — never restructure dirs
        if entry.name.startswith(".") or entry.name.startswith("~$"):
            continue                       # hidden / office lock files
        if entry.suffix.lower() in SKIP_SUFFIXES:
            continue                       # in-flight download
        try:
            if now - entry.stat().st_mtime < MIN_AGE_SECONDS:
                continue                   # too fresh, may be in use
        except OSError:
            continue
        if in_git_repo(entry):
            continue                       # never touch a repo's files
        cat = category_for(entry)
        target = unique_target(zone / SORTED_DIR / cat / entry.name)
        moves.append((entry, target))
    return moves


def apply_moves(moves, manifest_path: Path):
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    done = 0
    with open(manifest_path, "a", encoding="utf-8") as mf:
        for src, dst in moves:
            dst.parent.mkdir(parents=True, exist_ok=True)
            try:
                os.replace(src, dst)       # atomic on the same volume
            except OSError as e:
                print(f"  SKIP (move failed, file untouched): {src} — {e}")
                continue
            mf.write(json.dumps({"from": str(src), "to": str(dst),
                                 "ts": time.strftime("%Y-%m-%dT%H:%M:%S")}) + "\n")
            done += 1
    return done


def undo(manifest_path: Path):
    lines = manifest_path.read_text(encoding="utf-8").splitlines()
    restored = skipped = 0
    for line in reversed(lines):           # reverse order, safest
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        src, dst = Path(rec["to"]), Path(rec["from"])
        if not src.exists():
            print(f"  SKIP undo (moved file no longer there): {src}")
            skipped += 1
            continue
        if dst.exists():
            dst = unique_target(dst)
        dst.parent.mkdir(parents=True, exist_ok=True)
        os.replace(src, dst)
        restored += 1
    print(f"undo: {restored} restored, {skipped} skipped")
    return 0 if skipped == 0 else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--zones", nargs="*", help="directories to organize (default: ~/Downloads ~/Desktop)")
    ap.add_argument("--apply", action="store_true", help="actually move files (default: dry-run)")
    ap.add_argument("--undo", metavar="MANIFEST", help="reverse every move in a manifest file")
    args = ap.parse_args()

    if args.undo:
        return undo(Path(args.undo))

    zones = [Path(z).expanduser() for z in args.zones] if args.zones else default_zones()
    zones = [z for z in zones if z.is_dir()]
    if not zones:
        print("no zones found to organize")
        return 0

    stamp = time.strftime("%Y%m%d-%H%M%S")
    manifest = Path.home() / ".file-butler" / f"manifest-{stamp}.jsonl"
    total = 0
    for zone in zones:
        moves = plan_zone(zone)
        print(f"\n{zone}: {len(moves)} file(s) to sort" + ("" if args.apply else " (dry-run)"))
        for src, dst in moves:
            print(f"  {src.name}  ->  {dst.relative_to(zone)}")
        if args.apply and moves:
            total += apply_moves(moves, manifest)
    if args.apply:
        print(f"\nmoved {total} file(s); undo anytime: python3 organize.py --undo {manifest}")
    else:
        print("\ndry-run only — nothing was moved. Re-run with --apply to do it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
