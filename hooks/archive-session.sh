#!/bin/bash
# archive-session.sh — Stop hook. Archives the live transcript off an EPHEMERAL box.
#
# Why this exists (the failure it closes):
#   The cloud Claude Code surface runs in a container that is wiped between
#   sessions. Measured 2026-07-29: every path under ~/.claude carried the
#   container-start timestamp and ~/.claude/projects/ held exactly ONE
#   transcript — the live session's own. No earlier cloud session survived
#   anywhere on disk.
#   So the 2026-07-09 plan (a daily scheduled job that runs sync-sessions) could
#   never have worked: a scheduled fire starts a FRESH session on a FRESH
#   container and finds nothing but its own near-empty transcript. It cannot
#   reach what was already wiped. Twenty days of cloud sessions were lost that
#   way before anyone checked.
#   A transcript can only be captured by the session that is producing it.
#
# Why a heartbeat and not a true session-end hook:
#   A cloud container is reclaimed on inactivity — the common ending is "the tab
#   was closed", with no clean shutdown and no last-gasp hook. Anything that
#   fires only at a graceful end would miss exactly the sessions that matter.
#   Stop fires after every assistant turn, so this throttles to one archive per
#   CLAUDE_SESSION_ARCHIVE_INTERVAL seconds (default 900). Worst case you lose
#   the last few minutes of a session, never the whole thing.
#
# Contract:
#   - NEVER blocks a stop and never speaks. Always exits 0, on every path.
#   - Silently inert anywhere but a remote box with the session git proxy, so
#     the laptop (whose transcripts persist and are handled by sync-sessions)
#     is untouched.
#   - Opt out for a session with CLAUDE_NO_SESSION_ARCHIVE=1.
#
# Never leaves anything stale or incorrect — the five ways it could, and the
# guard for each:
#   0. A path that is not a transcript. The destination is named from the
#      source's basename, so a stray path would file a non-session into
#      raw/inputs/ under a bogus name. Only ~/.claude/projects/*/*.jsonl is
#      accepted.
#   1. A torn read. The transcript is being appended to while we copy it, so the
#      last line can be half-written. Any trailing incomplete line is dropped,
#      so what lands is always valid JSONL.
#   2. A shrinking snapshot. Each snapshot must be a superset of the last; if
#      the source is somehow smaller than what is already archived, the copy is
#      abandoned rather than overwriting good history with less.
#   3. A stuck clone. An interrupted rebase would poison every later heartbeat
#      in the session, silently. The clone is reset to a clean state before use
#      and discarded entirely if it cannot be.
#   4. A stale "unavailable" verdict. Availability is re-probed cheaply every
#      heartbeat instead of being latched for the session, so a brain repo
#      attached mid-session starts archiving on the next beat.
#
# Known trade-off, stated so it is not a landmine: each snapshot is a new git
# blob of a growing file, so a heavy day adds a few MB to the brain repo. If
# that ever matters, raise the interval or run the repo's purge_history.py —
# do not "fix" it by force-pushing over published history.

# No `set -e`: a failure here must never cost the user their turn.
input="$(cat)"

[ "${CLAUDE_NO_SESSION_ARCHIVE:-}" = "1" ] && exit 0

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[ -d "$CLAUDE_DIR" ] || exit 0

# ── 1. Scope: only where a session git proxy exists (i.e. a remote box) ───────
# Capability probe, not a hostname guess. The remote environment rewrites
# https://github.com/ to a local authenticated proxy; the laptop has no such
# rewrite, so this hook is inert there by construction.
git config --global --get-regexp '^url\..*\.insteadof$' 2>/dev/null \
  | grep -q '127\.0\.0\.1' || exit 0

STAMP="$CLAUDE_DIR/.session-archive.stamp"
BRAIN="$CLAUDE_DIR/.brain-archive"
REMOTE="https://github.com/Kariimc/brain"
INTERVAL="${CLAUDE_SESSION_ARCHIVE_INTERVAL:-900}"

# Only ever touches this hook's own scratch clone, never a user path.
scrub_clone() { case "$BRAIN" in "$CLAUDE_DIR"/.brain-archive) rm -rf "$BRAIN" ;; esac; }

# ── 2. Throttle ──────────────────────────────────────────────────────────────
now="$(date +%s)"
if [ -f "$STAMP" ]; then
  last="$(cat "$STAMP" 2>/dev/null)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  [ "$(( now - last ))" -lt "$INTERVAL" ] && exit 0
fi

# Every path below this line has consumed its turn in the interval: stamp first,
# so a failure retries on the next heartbeat instead of on every single turn.
echo "$now" > "$STAMP"

# ── 3. Is the brain reachable from this session? (cheap, re-probed each beat) ─
# A full clone attempt would hang for its whole timeout in the common case where
# the repo simply is not attached to the session. ls-remote answers in ~1s. It is
# deliberately NOT latched: attach the repo mid-session and the next beat works.
timeout 20 git ls-remote --exit-code -q "$REMOTE" HEAD >/dev/null 2>&1 || exit 0

# ── 4. Locate the transcript ─────────────────────────────────────────────────
# Prefer the path Claude Code hands us; fall back to the newest transcript on
# disk so a change to the hook payload shape cannot silently disable archiving.
transcript="$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("transcript_path") or "")
except Exception:
    pass
' 2>/dev/null)"

if [ ! -f "$transcript" ]; then
  transcript="$(ls -t "$CLAUDE_DIR"/projects/*/*.jsonl 2>/dev/null | head -1)"
fi
[ -f "$transcript" ] || exit 0

# The destination is named from this file's basename, so anything outside the
# transcripts directory would file itself under a bogus session name. A real
# transcript always lives there; refusing everything else keeps raw/inputs/ free
# of entries that are not sessions. (One landed exactly this way during testing.)
case "$transcript" in
  "$CLAUDE_DIR"/projects/*/*.jsonl) ;;
  *) exit 0 ;;
esac

# ── 5. Clone, or bring the existing clone back to a known-clean state ────────
if [ -d "$BRAIN/.git" ]; then
  # An interrupted rebase/merge from a previous beat would make every later
  # beat fail silently. Clear it; if it will not clear, throw the clone away.
  git -C "$BRAIN" rebase --abort >/dev/null 2>&1
  git -C "$BRAIN" merge --abort  >/dev/null 2>&1
  # Verify it actually cleared. A leftover rebase/merge marker (or an
  # unreadable HEAD) would make every later beat fail silently, so the clone is
  # thrown away and rebuilt rather than trusted.
  if [ -e "$BRAIN/.git/rebase-merge" ] || [ -e "$BRAIN/.git/rebase-apply" ] \
     || [ -e "$BRAIN/.git/MERGE_HEAD" ] \
     || ! git -C "$BRAIN" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    scrub_clone
  fi
fi
if [ ! -d "$BRAIN/.git" ]; then
  scrub_clone
  timeout 120 git clone --depth 1 -q "$REMOTE" "$BRAIN" 2>/dev/null || { scrub_clone; exit 0; }
fi

# ── 6. Snapshot ──────────────────────────────────────────────────────────────
# One file per session, updated in place. Each snapshot is a strict superset of
# the last (transcripts are append-only), so this stays verbatim source material
# and never rewrites what came before. The name is derived from the transcript
# actually copied — never from the hook payload — so the filename can never
# disagree with the contents.
sid="$(basename "$transcript" .jsonl)"
dest="raw/inputs/$(date +%F)-code-cloud-${sid:0:8}.jsonl"

mkdir -p "$BRAIN/raw/inputs" || exit 0

# Copy, then drop a trailing half-written line (the file is being appended to
# as we read it). Refuse to shrink what is already archived.
TRANSCRIPT="$transcript" TARGET="$BRAIN/$dest" python3 - <<'PY' || exit 0
import os, sys

src, dst = os.environ["TRANSCRIPT"], os.environ["TARGET"]
try:
    data = open(src, "rb").read()
except OSError:
    sys.exit(1)

# Keep only whole lines: a torn final record is not valid JSONL.
cut = data.rfind(b"\n")
if cut == -1:
    sys.exit(1)
data = data[:cut + 1]

# A snapshot must never be smaller than the one already archived.
if os.path.exists(dst) and len(data) < os.path.getsize(dst):
    sys.exit(1)

tmp = dst + ".tmp"
with open(tmp, "wb") as f:
    f.write(data)
os.replace(tmp, dst)
PY

# ── 7. Commit and push ───────────────────────────────────────────────────────
cd "$BRAIN" || exit 0
git add "$dest" >/dev/null 2>&1
git diff --cached --quiet 2>/dev/null && exit 0   # nothing new since last beat

git -c user.email=kariimchiles@gmail.com \
    -c user.name="Kariim (via Claude Code cloud)" \
    commit -q -m "archive: code-cloud session ${sid:0:8} — snapshot $(date -u +%FT%TZ)" \
    >/dev/null 2>&1 || exit 0

if ! timeout 120 git push -q origin HEAD >/dev/null 2>&1; then
  # Another session pushed first. Rebase onto it and try once more; if that
  # fails too, leave the commit local — the next heartbeat retries from a
  # cleaned clone (step 5).
  timeout 120 git pull --rebase -q >/dev/null 2>&1 \
    && timeout 120 git push -q origin HEAD >/dev/null 2>&1
fi

exit 0
