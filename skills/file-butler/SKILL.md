---
name: file-butler
description: >-
  Keep the laptop's messy zones (Downloads, Desktop, any named folder) sorted
  automatically — moves only, never deletes, one-command undo per run, git
  repos and in-flight files untouchable. Use when the user says organize,
  tidy, sort, or clean up my files/folder/downloads/desktop, or to set up the
  recurring automatic tidy. Drives tool/organize.py; first run in a new zone
  is always a shown dry-run.
metadata:
  origin: authored
tools: Read, Bash, Grep, Glob
---

# File Butler

Hands-free tidiness with a paranoid safety contract. The engine is
`tool/organize.py` (pure Python stdlib — runs on the Windows laptop and any
box unchanged).

## The contract (enforced in the engine's code, verified by test)

- Moves only — nothing is ever deleted or overwritten; name collisions get
  ` (1)` suffixes.
- Every applied run writes an undo manifest to `~/.file-butler/`;
  `--undo <manifest>` reverses the whole run in reverse order.
- Untouchable: directories, git repos, hidden files, `.crdownload/.part/.tmp`
  in-flight files, files under 1 hour old, the `_Sorted` tree itself.
- Dry-run is the default; `--apply` is explicit.

## Use

```bash
python3 tool/organize.py                          # dry-run: ~/Downloads ~/Desktop
python3 tool/organize.py --apply                  # do it
python3 tool/organize.py --zones "D:/Renders" --apply
python3 tool/organize.py --undo ~/.file-butler/manifest-<stamp>.jsonl
```

Files land in `<zone>/_Sorted/<Category>/` — Images, Documents, Sheets,
Slides, Archives, Installers, Video, Audio, 3D, Fonts, Code, Other.

## Automatic mode (the point)

The `file-butler` agent runs this on a schedule via `loops/file-butler.md` —
registered on the laptop (the only surface that can reach its files; a cloud
session cannot, by architecture). New zone → one shown dry-run + one yes,
then it's automatic there. Every scheduled run's report + undo command lands
in the run log, so nothing ever happens invisibly.

## Proof (2026-07-23, this pipeline, real run)

11 mixed files sorted correctly by category; collision produced `report (1).pdf`;
repo-internal, fresh, in-flight, and hidden files all untouched; `--undo`
restored 12/12 moves with 0 skips.
