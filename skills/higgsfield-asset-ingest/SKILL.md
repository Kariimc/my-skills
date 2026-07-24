---
name: higgsfield-asset-ingest
description: Reliable intake workflow for Higgsfield website downloads and other generated media assets. Use when Codex, Claude Code, Claude Desktop, Google AI Studio/Antigravity, or another coding agent needs to find recently downloaded Higgsfield images/videos/audio, rename them, deduplicate them, write a manifest, and copy or move them directly into a project asset folder without Google Drive or manual file wrangling.
---

# Higgsfield Asset Ingest

## Overview

Use this skill to turn normal browser downloads from Higgsfield into predictable, project-local assets that any coding agent can find by path and manifest. Do not rely on Higgsfield web scraping or private browser state; the reliable contract is: user downloads files, the script imports complete media files from known local folders into the active project.

## Quick Start

1. Locate this skill folder.
2. Run a dry run from the target project root:

```bash
python /path/to/higgsfield-asset-ingest/scripts/ingest_assets.py --project . --dry-run
```

3. If the planned destination and files look right, run the import:

```bash
python /path/to/higgsfield-asset-ingest/scripts/ingest_assets.py --project . --prefix higgsfield
```

4. Read the generated `higgsfield-assets.json` manifest in the destination folder before wiring assets into the app.

## Workflow

- Read `references/workflow.md` when the user needs a full handoff plan, destination policy, Claude/Codex/Antigravity instructions, or troubleshooting guidance.
- Prefer `--source ~/Downloads` or the default source scan unless the user names a folder.
- Prefer copy mode. Use `--move` only when the user asks to clean the download folder.
- Use `--since-hours 24` during a monthly Higgsfield free-generation window to import only the current batch. Use `--since-hours 0 --source /exact/folder` for a curated folder.
- Use `--dest` for framework-specific paths, for example `--dest public/images` or `--dest src/assets/generated`.

## Script Contract

`scripts/ingest_assets.py` provides deterministic behavior:

- Scans complete media files from `~/Downloads` and `~/Desktop` by default.
- Supports images, videos, audio, SVG, GIF, AVIF, WEBP, and ZIP bundles.
- Ignores partial browser downloads such as `.crdownload`, `.download`, `.part`, and `.tmp`.
- Deduplicates by SHA-256 against prior imports and existing destination files.
- Renames files with stable, readable names: `<prefix>-<YYYYMMDD>-<sequence>-<kind>.<ext>`.
- Writes both JSON and CSV manifests so future agents can find imported files without guessing.

## Common Commands

```bash
# Preview recent downloads going into the auto-detected asset folder
python /path/to/higgsfield-asset-ingest/scripts/ingest_assets.py --project . --dry-run

# Import only today's/latest session into a React/Next public folder
python /path/to/higgsfield-asset-ingest/scripts/ingest_assets.py --project . --dest public/assets/higgsfield --since-hours 24 --prefix hero

# Import a curated folder and move files after successful copy into the project
python /path/to/higgsfield-asset-ingest/scripts/ingest_assets.py --project . --source "$HOME/Downloads/Higgsfield" --since-hours 0 --move --prefix campaign
```

## Failure Handling

- If no files are found, check that the browser download finished and rerun with `--since-hours 0 --source /exact/download/folder`.
- If the coding agent is remote/cloud-only, first sync or copy the destination folder plus manifest into the remote workspace; do not ask the user to upload loose files individually.
- If the target app has strict asset naming or compression rules, import first, then perform app-specific optimization as a separate step while preserving the manifest.
