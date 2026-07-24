# Vendored: impeccable

This skill is vendored **verbatim** from the upstream open-source project so it runs in
this library with zero CLI install (no `npx impeccable install` needed — it syncs like
every other skill here).

- **Upstream:** https://github.com/pbakaus/impeccable (by Paul Bakaus)
- **Home:** https://impeccable.style
- **License:** Apache License 2.0 — see [`LICENSE`](./LICENSE). Redistribution with
  attribution is permitted by that license; this file and the preserved `LICENSE` are
  that attribution.
- **Vendored from:** the repo's `.claude/skills/impeccable/` tree (SKILL.md v4.0.2).
- **Vendored on:** 2026-07-24.

## Updating

To refresh, re-copy `.claude/skills/impeccable/` from the upstream repo over this folder
and keep `LICENSE` + this file. Do not hand-edit the vendored files — local edits will be
lost on the next refresh and drift from upstream.

## How it's used here

The `web-page-builder` skill drives impeccable as its design-quality engine (the
`polish`, `audit`, `critique`, `bolder`, `quieter`, `typeset`, `layout`, `animate`,
`live`, … passes). You can also invoke it directly with `/impeccable <command> [target]`.
