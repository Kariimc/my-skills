# Ratchet check: `no-plaintext-secrets-in-brain.sh`

**Rationale.** On 2026-06-30 a real 40-character hex auth token
(`c9d2dcff…966db9`, the Higgsfield/Neon-Forge push credential) was committed in
plaintext to `.git/config` and copied into several handoff docs. The existing
`gate_secrets` in `bin/apex-gates.sh` only matches *prefixed* provider keys
(`AKIA…`, `ghp_…`, `sk-…`, `AIza…`, `xox…`, PEM blocks) — a **bare** high-entropy
hex token has no prefix, so it walked straight past the gate. This ratchet check
closes that specific gap: it greps every tracked (committed/staged) file for
(1) a word-bounded 40-hex token that is **not** an `0x…` EVM address, a periodic
filler vector, or a git-commit-SHA-in-context; (2) the same prefixed provider
secrets `gate_secrets` covers (so the coverage never regresses even if the two
drift); and (3) a credential field (`api_key`, `client_secret`, `token`,
`password`, …) assigned a 32+ char opaque **literal**, while excluding
`process.env`/`os.environ` lookups and obvious placeholders (`YOUR_…`,
`change-me`, `<…>`, `example`, `…-here`). It fails HARD (exit 1) and redacts any
matched value in its own output so the gate log never reprints the full secret.
Verified: passes clean against the full tracked tree, catches a planted bare
token / `ghp_` / `sk-` / hardcoded literal, and does **not** flag git SHAs, SRI
integrity hashes, EVM test addresses, env-var refs, or `CharField(...)` code.

## How it wires into the `extra` gate

**No manual wiring is required to activate it.** `gate_extra()` in
`bin/apex-gates.sh` auto-discovers every executable under `apex/checks/*.sh`,
runs each from the repo root, and treats any non-zero exit as a HARD failure:

```sh
gate_extra() {
  echo "› extra (ratchet checks)"
  for c in apex/checks/*.sh; do
    [ -f "$c" ] || continue
    bash "$c" >/tmp/apex-extra.out 2>&1 || {
      sed 's/^/    /' /tmp/apex-extra.out
      note_hard "ratchet check failed: $(basename "$c")"
    }
  done
}
```

Because `gate_extra` is already in the `all` run-list
(`for g in doctor hooklint secrets selfintegrity extra live`), the check fires at
**all three enforcement points automatically**: pre-commit (staged), pre-push
(full tree), and CI. Dropping this file into `apex/checks/` is the entire
install step.

### Contract this check honors (matches the ratchet scaffold)
- `#!/bin/bash` + `set -uo pipefail`; `cd "$(git rev-parse --show-toplevel)"`.
- Exit `0` = pass, non-zero = HARD failure.
- Self-contained: no args, no external deps beyond `git`, `grep`, `sed`.
- Passes `bash -n`.
- Skips itself, binaries, and hash-bearing lockfiles/fonts/media so its own
  pattern source and legitimate content-hashes never self-flag.

## Manual follow-ups for review (optional, out of scope of this file)

1. **Register the mistake in the ledger.** Add a row to
   `apex/MISTAKE-LEDGER.md` (next id is **9**) — or run
   `bin/apex-ratchet.sh "bare 40-hex auth token committed in plaintext (no
   prefix, missed by gate_secrets)"`, which appends the ledger row for you.
   Note: the ratchet would also scaffold a *placeholder* `apex/checks/*.sh`; if
   you run it, delete that stub — this hand-written check supersedes it. Adding
   the ledger row is documentation only and does not affect enforcement.
2. **Latent bug in `bin/apex-gates.sh` `gate_secrets` (line ~84).** Its
   `grep -nIEq "$pat"` passes a pattern that begins with `-----BEGIN…` **without**
   `-e`/`--`, so on this platform grep parses the leading dashes as options and
   errors (`rc=2`) — meaning the upstream secrets gate may silently match nothing
   for the PEM/prefixed classes. This ratchet check is unaffected (it uses
   `grep -e "$PAT"` throughout). Worth fixing `gate_secrets` to `grep -Ee "$pat"`
   in the same pass, but per instructions I did **not** touch that file.
