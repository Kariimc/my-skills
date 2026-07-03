#!/bin/bash
set -uo pipefail
# Ratchet gate #9 — prevents recurrence of:
#   A bare high-entropy token (bare 40-hex bearer/API token) or a hardcoded
#   opaque provider secret committed in plaintext to a tracked file. This is the
#   leak class that ACTUALLY happened: a 40-char hex auth token lived in
#   .git/config and handoff docs while gate_secrets only matched *prefixed* keys
#   (AKIA…, ghp_…, sk-…) and sailed right past a naked hex token. This check
#   closes that gap for good, for every tracked file in the brain/control-plane.
#
# Runs from repo root via apex-gates.sh gate_extra. Exit 0 = pass, non-zero = HARD.
#
# Design contract (why it is tight, not broad):
#   A secrets gate must flag REAL committed secret material, never the mere
#   MENTION of a credential. Broad "keyword=value" matching flags legitimate
#   code (`password = CharField(...)`, `apiKey: process.env.X`, `SECRET_KEY=
#   change-me`) and would HARD-block every commit. So this matches only
#   high-entropy secret SHAPES, and excludes env-var lookups and placeholders.
#   Verified to pass clean against the full tracked tree at author time.
#
# Performance:
#   Detection uses `git grep` (one process over the whole tracked tree, ~3s),
#   NOT a per-file shell loop (which forks once per file and takes minutes on
#   Git Bash). Per-line filtering runs only on the few lines that actually hit.

cd "$(git rev-parse --show-toplevel)" || exit 1

SELF="apex/checks/no-plaintext-secrets-in-brain.sh"

# ── Rule patterns ────────────────────────────────────────────────────────────
H='[0-9a-fA-F]'
# (1) Bare high-entropy token: 40 hex chars, word-bounded, not 0x-prefixed. The
#     char class is assembled at runtime so THIS file's source carries no literal
#     40-hex string that would flag itself.
PAT_HEX40="(^|[^0-9a-fA-Fx])${H}{40}([^0-9a-fA-F]|\$)"
# (2) Prefixed provider secrets (mirror of gate_secrets — proven zero-FP set).
PAT_PREFIXED='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[0-9A-Za-z-]{10,}|gh[pousr]_[0-9A-Za-z]{36,}|sk-[A-Za-z0-9]{32,}'
# (3) Hardcoded opaque assignment: an auth/secret/token/key field set to a 32+
#     char quoted LITERAL. Env lookups + placeholders are filtered out per line.
KEYWORD='(authorization|auth[_-]?token|api[_-]?key|secret[_-]?key|access[_-]?token|client[_-]?secret|password|passwd|token)'
VALUE="['\"][A-Za-z0-9_./+=~-]{32,}['\"]"
PAT_ASSIGN="${KEYWORD}[\"' ]*[:=][\"' ]*${VALUE}"

# A PAT_ASSIGN / PAT_HEX40 hit is a FALSE POSITIVE when the line is really an
# env-var reference, an interpolation, or a documentation placeholder.
NOT_A_SECRET='process\.env|os\.environ|import\.meta\.env|System\.getenv|getenv\(|ENV\[|\$\{|\$\(|YOUR[_-]|<[A-Za-z]|change[_-]?me|example|placeholder|redacted|your[_-]|[_-]here|xxxxx|dummy|sample|\bfake\b|\btest|\.\.\.|insert[_-]|replace[_-]'
# A bare 40-hex run is ALSO a public git commit SHA / SRI hash — benign when the
# line names it as one.
GIT_SHA_CONTEXT='\b(sha|sha1|commit|revision|rev|head|checkout|digest|integrity|blob|tree|parent|pin(ned)?|gitsha|content[_-]?hash)\b|github\.com/[^ ]+/(commit|tree|blob)/'

# ── Pathspecs: exclude self, binaries, and hash-bearing lockfiles/fonts/media
#    (they carry legitimate 40-hex content-hashes and would false-positive). git
#    grep's -I already skips binary blobs; these excludes catch text lockfiles.
EXCLUDES=(
  ":(exclude)$SELF"
  ':(exclude)*.lock' ':(exclude)*package-lock.json' ':(exclude)*yarn.lock'
  ':(exclude)*pnpm-lock.yaml' ':(exclude)*Cargo.lock' ':(exclude)*go.sum'
  ':(exclude)*.min.js' ':(exclude)*.min.css' ':(exclude)*.map'
  ':(exclude)*.svg' ':(exclude)*.woff' ':(exclude)*.woff2' ':(exclude)*.ttf'
  ':(exclude)*.eot' ':(exclude)*.otf'
)

HITS=0
report() { # $1=reason  $2=file  $3=already-redacted preview line
  echo "ratchet[no-plaintext-secrets-in-brain]: $1 in $2"
  [ -n "${3:-}" ] && echo "    $3"
  HITS=$((HITS+1))
}
# Redact a line past the first 12 value chars so the gate log never reprints the
# full secret.
redact() { LC_ALL=C sed -E 's/([A-Za-z0-9_./+=~-]{12})[A-Za-z0-9_./+=~-]{8,}/\1…REDACTED/g' | cut -c1-100; }

# Reject periodic filler/test vectors (0000…, 1234567890…, deadbeef…).
looks_like_filler() { # $1 = the 40-hex run
  case "$1" in
    0000000000000000000000000000000000000000) return 0 ;;
    ffffffffffffffffffffffffffffffffffffffff|FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0 ;;
    1234567890123456789012345678901234567890) return 0 ;;
    deadbeef*|DEADBEEF*|abcdef0123456789*|0123456789abcdef*) return 0 ;;
  esac
  return 1
}

# ── Detection: one `git grep` per rule over the whole tracked tree. -n gives
#    file:line:content. -I skips binaries, -E extended regex, -e guards patterns
#    that begin with '-' (PAT_PREFIXED starts with '-----'; without -e grep
#    parses it as options and silently matches nothing — a real trap).

# (2) Prefixed provider secrets — every hit is real.
while IFS= read -r rec; do
  [ -n "$rec" ] || continue
  file="${rec%%:*}"; rest="${rec#*:}"; content="${rest#*:}"
  report "prefixed provider secret" "$file" "$(printf '%s' "$content" | redact)"
done < <(git grep -nIE -e "$PAT_PREFIXED" -- . "${EXCLUDES[@]}" 2>/dev/null)

# (1) Bare 40-hex token — drop filler vectors and git-SHA/SRI context lines.
while IFS= read -r rec; do
  [ -n "$rec" ] || continue
  file="${rec%%:*}"; rest="${rec#*:}"; content="${rest#*:}"
  tok="$(printf '%s' "$content" | LC_ALL=C grep -aoE -e "(^|[^0-9a-fA-Fx])$H{40}" | LC_ALL=C grep -aoE -e "$H{40}" | head -1)"
  [ -n "$tok" ] || continue
  looks_like_filler "$tok" && continue
  printf '%s' "$content" | LC_ALL=C grep -qiE -e "$GIT_SHA_CONTEXT" && continue
  report "high-entropy 40-hex token" "$file" "$(printf '%s' "$content" | redact)"
done < <(git grep -nIE -e "$PAT_HEX40" -- . "${EXCLUDES[@]}" 2>/dev/null)

# (3) Hardcoded opaque credential literal — drop env refs and placeholders.
while IFS= read -r rec; do
  [ -n "$rec" ] || continue
  file="${rec%%:*}"; rest="${rec#*:}"; content="${rest#*:}"
  printf '%s' "$content" | LC_ALL=C grep -qiE -e "$NOT_A_SECRET" && continue
  report "hardcoded credential literal" "$file" "$(printf '%s' "$content" | redact)"
done < <(git grep -nIiE -e "$PAT_ASSIGN" -- . "${EXCLUDES[@]}" 2>/dev/null)

if [ "$HITS" -gt 0 ]; then
  echo "ratchet[no-plaintext-secrets-in-brain]: $HITS finding(s) — tracked file(s) contain plaintext secret material."
  echo "  Rotate the exposed credential (treat it as burned), remove it from the file,"
  echo "  and source it from an env var or a gitignored secret file instead."
  exit 1
fi

exit 0
