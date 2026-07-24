# Higgsfield Asset Intake Workflow

Use this when a user wants assets generated on the Higgsfield website to become project-ready files without cloud-drive handoffs.

## Reliable path

1. Ask the user to download assets from Higgsfield normally in the browser. Do not depend on a Higgsfield API unless the user provides one.
2. Run `scripts/ingest_assets.py` from this skill against the active project.
3. Use `--dry-run` first when the destination is uncertain.
4. Prefer copy mode by default so the browser download remains a backup. Use `--move` only when the user explicitly wants the downloads cleaned up.
5. Import from `~/Downloads` and `~/Desktop` by default. Add `--source /path/to/folder` for an export folder, Dropbox folder, external drive, or synced machine folder.
6. Use `--since-hours` to target the latest generation session. Use `--since-hours 0` only when importing an entire folder.
7. Commit the imported project assets in the target project only when the project normally versions generated media. Otherwise leave the manifest and assets uncommitted or follow that project's asset policy.

## Destination choices

The script auto-selects the first matching project convention and creates a Higgsfield-specific subfolder:

- `public/assets/higgsfield`
- `public/assets/generated`
- `public/images/higgsfield`
- `src/assets/higgsfield`
- `assets/higgsfield`
- `app/assets/higgsfield`

Override with `--dest path/inside/project` when the app has a known asset folder.

## Naming and provenance

Imported files are named as `<prefix>-<YYYYMMDD>-<sequence>-<kind>.<ext>`. The default prefix is `higgsfield`; pass `--prefix hero`, `--prefix onboarding`, or similar for app-specific names.

Each import updates `higgsfield-assets.json` and `higgsfield-assets.csv` in the destination folder with source path, destination path, sha256, kind, size, and import time. Agents should inspect the manifest instead of guessing filenames.

## Claude Code, Codex, and Google AI Studio handoff

When another agent needs the assets, tell it the destination folder and manifest path, for example:

```text
Use assets from public/assets/higgsfield. Read public/assets/higgsfield/higgsfield-assets.json, choose the newest imported hero image, rename references as needed, and wire it into the app.
```

Avoid Google Drive unless the project is remote-only and cannot access the local filesystem. If a cloud handoff is unavoidable, upload the entire destination folder including the manifest, not loose files.
