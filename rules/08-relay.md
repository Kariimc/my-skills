# Relay — cross-surface communication (fires every session)

At session start, read the Relay so this surface has global state and any
messages waiting for it:

- Fetch `https://raw.githubusercontent.com/Kariimc/relay/main/HANDOFF.md` (the
  single source of truth for global state).
- Fetch your surface's inbox at
  `https://raw.githubusercontent.com/Kariimc/relay/main/inbox/<surface>.md`.
  Surfaces: `code-local`, `code-cloud`, `cowork`. (steamdeck retired 2026-07 — its inbox is deleted from the relay repo.)
- If the repo is cloned locally, prefer `git pull` + reading the local files
  over the raw URLs.

Act on any inbox messages, then clear the handled entries (keep the header).

Before ending a session where state changed: update `HANDOFF.md`, append one
line to `log.md` (newest on top), then commit and push with message
`relay: <surface> — <summary>`. To message another surface, append a dated
entry to its `inbox/<surface>.md`. If you cannot push, output the exact git
commands as one paste-block for Riimos to run.

The relay repo is **public** — never put secrets in it. The `relay` skill has
the full protocol and the exact `HANDOFF.md` format.
