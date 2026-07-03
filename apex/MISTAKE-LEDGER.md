# Mistake ledger

Every entry is a mistake that is now **permanently gated** — it can happen at
most once. New entries are added by `bin/apex-ratchet.sh`. Append-only.

| # | Mistake | Gate |
|---|---|---|
| 1 | README skill counts drifted (claimed 386 / 52, actual 393) | `gate_doctor` (auto-heals counts) |
| 2 | ~20% of skills (79) had no "Use when" trigger, so they never auto-fired | `gate_doctor` (triage report + flag) |
| 3 | A skill folder name not matching its frontmatter `name:` | `gate_doctor` (HARD) |
| 4 | A hook with a heredoc that ate stdin (router routed nothing) | `gate_hooklint` (syntax + live stdin test) |
| 5 | Uncertainty whether a change actually synced to ~/.claude and fired | `gate_live` |
| 6 | Credential-shaped strings reaching a commit | `gate_secrets` |
| 7 | The guards themselves being deleted, gutted, or un-wired | `gate_selfintegrity` |
| 8 | A regression landing on `master` with local hooks bypassed | `.github/workflows/apex.yml` (CI mirror) |
| 9 | A bare high-entropy token (40-hex, no prefix) committed in plaintext — `gate_secrets` only matched *prefixed* keys and its PEM pattern started with `-----`, which grep parsed as options (rc=2), leaving it silently inert on Windows | `apex/checks/no-plaintext-secrets-in-brain.sh` (bare-token + literal-assignment shapes) **+** fixed `gate_secrets` to pass `-e` |

> Gates 1–8 were the mistakes of the first month. Everything after this line is a
> mistake the ratchet caught once and will never allow again.
