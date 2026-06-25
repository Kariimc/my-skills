#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# install-global.sh — make this repo's skills/rules/commands/agents load in
# EVERY project, on EVERY Claude Code session.
#
# What it does (run it ONCE per machine):
#   1. Registers a global SessionStart hook in ~/.claude/settings.json that
#      points back at THIS clone's sync script.
#   2. Runs the sync immediately so everything is live right now.
#
# Re-running is safe: it replaces any previous my-skills hook instead of
# stacking duplicates. Works on macOS, Linux, and Windows (Git Bash).
# ─────────────────────────────────────────────────────────────────────────────

# Absolute path of the folder this script lives in = your local my-skills clone.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$REPO/.claude/hooks/session-start.sh"

if [ ! -f "$HOOK" ]; then
  echo "ERROR: could not find the sync hook at $HOOK" >&2
  echo "Are you running this from inside your my-skills clone?" >&2
  exit 1
fi

# Merge a SessionStart hook into the GLOBAL settings file using Node (which is
# always present, because Claude Code itself runs on Node). We pass this repo's
# path to the script as an argument so it always syncs FROM here, no matter
# which project you have open. Using an argument (not an inline env var) keeps
# the command portable to Windows shells.
REPO="$REPO" HOOK="$HOOK" node -e '
const fs = require("fs"), os = require("os"), path = require("path");
const dir = path.join(os.homedir(), ".claude");
fs.mkdirSync(dir, { recursive: true });
const file = path.join(dir, "settings.json");
let s = {};
try { s = JSON.parse(fs.readFileSync(file, "utf8")); } catch (e) {}
s.hooks = s.hooks || {};
let arr = Array.isArray(s.hooks.SessionStart) ? s.hooks.SessionStart : [];
// Drop any earlier my-skills hook so we never stack duplicates.
arr = arr.filter(g => !(g.hooks || []).some(h => String(h.command || "").includes("session-start.sh")));
const repo = process.env.REPO, hook = process.env.HOOK;
const command = `bash "${hook}" "${repo}"`;
arr.push({ hooks: [{ type: "command", command }] });
s.hooks.SessionStart = arr;
fs.writeFileSync(file, JSON.stringify(s, null, 2));
console.log("Wired global SessionStart hook -> " + repo);
'

# Run the sync once right now so you do not have to restart to see your skills.
bash "$HOOK" "$REPO" >/dev/null 2>&1 || true

echo "Done. All skills/rules/commands/agents are now synced to ~/.claude/"
echo "From now on they load automatically in every project, every session."
