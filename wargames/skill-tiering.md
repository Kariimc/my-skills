# Wargame — Skill Tiering (always-load core vs on-demand library)

**Mission:** Make only a curated ~29-skill core load into `~/.claude/skills`
every session, while keeping all ~400 skills in the `my-skills` repo ("just in
case"), with a one-command way to pull any other skill on demand. Cut per-session
context without losing any skill.

**Self-grade:** PASS (all 8 points hold after red-team patch below).

## Recon (read-only, done)
- `session-start.sh` §1 syncs skills via `mirror_tree`: it runs
  `rm -rf "$CLAUDE_DIR/skills"` then `cp -r "$src/." "$dst/"`. Destination becomes
  an exact copy of the repo's `skills/`.
- `set -euo pipefail` is on: any failed command aborts the hook.
- The hook runs on **every session start, async, on every surface**, and does a
  `git pull --ff-only` first — so a committed change propagates fleet-wide.
- Rules (`00-core`, `06-fable-parity`, `08-relay`, etc.) name the always-on
  skills; that set IS the core, derived not guessed.
- README/apex gates count **repo** skills (unchanged by this change).

## Design under test
1. `always-load.txt` at repo root: one core skill dir-name per line.
2. `session-start.sh` §1 changed: build the core set into a **temp dir**, verify
   it, then atomically replace `~/.claude/skills`. Repo `skills/` untouched.
3. `commands/pull-skill.md` (+ `bin/pull-skill.sh`): `pull-skill <name>` copies
   `skills/<name>` into `~/.claude/skills/`; `--all` restores the full set.

## Battle plan (move → expected → likely failure → counter-move / fork)

**M1. Write `always-load.txt` (29 core names).**
- Expected: every line matches an existing `skills/<name>/` dir.
- Likely failure: typo → a core guardrail silently never loads.
- Counter: validate each line against `ls skills/`; **ABORT** if any line has no
  matching dir. Fork: unmatched name → fix it, never ship a list with phantoms.

**M2. Rewrite §1 skills sync as safe-filtered.**
- Expected: after run, `~/.claude/skills` = exactly the core set; repo still has
  ~400; the removed non-core are gone from `~/.claude` only.
- Likely failure A (CATASTROPHIC): filter copies nothing → `~/.claude/skills`
  empty → **no skills load, including guardrails, on every surface.**
  - Counter: build into `~/.claude/skills.tmp.$$`, assert file/dir count > 0 AND
    a sentinel core skill (`relay`) present, THEN `rm -rf skills && mv tmp skills`.
    Never `rm -rf` the live dir before the replacement is verified.
- Likely failure B: one skill copy fails mid-loop, `set -e` aborts, half-built
  tree. Counter: temp-build + atomic swap makes a mid-loop abort leave the LIVE
  dir untouched (temp is discarded).
- Likely failure C: `always-load.txt` missing/empty/malformed on some machine →
  must not wipe skills. Counter (FLOOR): if the resolved core set is empty or
  `always-load.txt` is absent, **fall back to mirror-all** (today's behavior).
- Fork: resolved core count < 5 → treat as malformed → fall back to mirror-all.

**M3. Add `pull-skill` escape hatch.**
- Expected: `pull-skill youtube-research` puts it in `~/.claude/skills/`.
- Likely failure: next session-start mirror removes it (not in core). Acceptable
  = on-demand is per-session; to keep it, add to `always-load.txt`. Documented in
  the command.
- `RECON NEEDED: does Claude Code discover a newly-copied skill dir MID-session,
  or only at next session start?` Exact check: after `pull-skill`, see whether
  the skill is invocable without restart. If not, `pull-skill` preps the NEXT
  session (still correct, just note it). Design assumes next-session pickup so it
  is safe either way.

**M4. Ship via `skill-ship` (apex gates).**
- Expected: gates pass, pushed; other surfaces pick it up on their next start.
- Likely failure: `selfintegrity` or a count gate objects. Counter: skill-ship
  reconciles; a selfintegrity failure **outranks all** → ABORT and fix the gate,
  never route around it.

## Abort conditions
- Resolved core set would be empty or < 5 skills → abort, keep mirror-all.
- Any `always-load.txt` line has no matching skill dir → abort until fixed.
- Dry-run temp build produces 0 dirs, or is missing `relay`/`plan-gate`/
  `visual-prototype` → abort, do not touch live `~/.claude/skills`.
- `selfintegrity` gate red → abort everything else.

## Verification (what runs, when, pass looks like)
1. **Before any live change:** run the new filter into a TEMP dir. PASS =
   count == core count, and `relay` + `plan-gate` + `visual-prototype` +
   `screen-eyes` all present.
2. **After live sync:** `ls ~/.claude/skills | wc -l` == core count; repo
   `skills/` count unchanged (~400); a non-core (`youtube-research`) absent from
   `~/.claude/skills`.
3. **pull-skill:** `pull-skill youtube-research` → dir appears in `~/.claude/skills`.
4. **New session:** core loads; report confirms non-core not listed.

## Red-team (attack → patch, both on record)
- **Attack:** the mirror `rm -rf`s the live skills dir before copying. If the
  new filter loop copies nothing (bad glob, empty `always-load.txt`, CRLF line
  endings making every name "not found"), `~/.claude/skills` ends up empty and
  the guardrail skills that keep every agent in check are gone — fleet-wide,
  because the change is pushed and every surface pulls it. A silent control-plane
  outage.
- **Patch:** (a) temp-build + verify-non-empty + sentinel-present + atomic swap,
  never rm-before-verify; (b) hard FLOOR — empty/absent/malformed `always-load.txt`
  or < 5 resolved → fall back to today's mirror-all; (c) strip CRLF (`tr -d '\r'`)
  when reading `always-load.txt` so Windows line endings can't zero the match.
- Re-graded after patch: all 8 points hold.

## Log
See `wargames/LEDGER.md`.
