#!/bin/bash
# bootstrap.sh — install the whole control plane on a machine that has NO clone.
#
# Why this exists:
#   install-global.sh assumes you are already standing inside a my-skills clone.
#   That is true on the laptop and false everywhere else. A cloud session working
#   on some other repo has no clone, no git auth for one, and a ~/.claude that is
#   wiped between sessions — so it starts with ZERO rules, ZERO guard hooks and
#   ZERO skills, and nothing in the session ever says so out loud.
#
#   This fetches the repo over plain HTTPS (public, no auth, works on an
#   allowlist box where only GitHub and PyPI answer) and then hands off to
#   install-global.sh, which is the proven installer.
#
# Use it as the ONE line in a cloud environment's setup script:
#
#   curl -fsSL https://raw.githubusercontent.com/Kariimc/my-skills/master/bootstrap.sh | bash
#
# Re-running is safe: it replaces the copy under $MY_SKILLS_DIR and install-global
# replaces its own hook registration rather than stacking duplicates.
#
# Env knobs:
#   MY_SKILLS_REF  branch or tag to install (default: master)
#   MY_SKILLS_DIR  where the copy lands    (default: ~/.my-skills)

set -euo pipefail

REF="${MY_SKILLS_REF:-master}"
DEST="${MY_SKILLS_DIR:-$HOME/.my-skills}"
URL="https://codeload.github.com/Kariimc/my-skills/tar.gz/refs/heads/$REF"

command -v curl >/dev/null 2>&1 || { echo "bootstrap: curl is required" >&2; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "bootstrap: tar is required"  >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "bootstrap: fetching my-skills@$REF"
curl -fsSL -m 300 "$URL" -o "$TMP/ms.tgz"
tar xzf "$TMP/ms.tgz" -C "$TMP"

# GitHub names the top directory <repo>-<ref>, and a ref containing "/" changes
# that shape — find it instead of guessing.
SRC="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d -name 'my-skills-*' | head -1)"
[ -n "$SRC" ] && [ -f "$SRC/install-global.sh" ] || {
  echo "bootstrap: archive did not contain a my-skills tree" >&2; exit 1; }

# Swap the copy into place. Only ever replaces $DEST, which this script owns.
rm -rf "$DEST.new"
mv "$SRC" "$DEST.new"
rm -rf "$DEST"
mv "$DEST.new" "$DEST"

chmod +x "$DEST"/install-global.sh "$DEST"/bin/*.sh "$DEST"/hooks/*.sh \
         "$DEST"/.claude/hooks/*.sh 2>/dev/null || true

echo "bootstrap: installing from $DEST"
MY_SKILLS_BOOTSTRAPPING=1 bash "$DEST/install-global.sh"

# Freshness stamp lives OUTSIDE $DEST, which this script replaces wholesale.
# session-start.sh reads it to decide when a tarball install has gone stale
# enough to re-fetch. Keeping it inside $DEST would wipe it on every run, so
# every session would re-download.
mkdir -p "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
date +%s > "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.bootstrap-fetched"

# Prove it, rather than announcing it. A silent no-op here is the exact failure
# this script exists to end.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
rules_bytes=0
[ -f "$CLAUDE_DIR/CLAUDE.md" ] && rules_bytes=$(wc -c < "$CLAUDE_DIR/CLAUDE.md")
skills=$(ls "$CLAUDE_DIR/skills" 2>/dev/null | wc -l)
hooks=$(ls "$CLAUDE_DIR/hooks"/*.sh 2>/dev/null | wc -l)
echo "bootstrap: CLAUDE.md ${rules_bytes} bytes | ${skills} skills | ${hooks} hooks"
[ "$rules_bytes" -gt 1000 ] || { echo "bootstrap: FAILED — rules did not land" >&2; exit 1; }
