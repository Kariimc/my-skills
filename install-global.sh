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
# stacking duplicates. Works on macOS, Linux, and Windows (Git Bash) — it
# auto-finds Node or Python so you do not need either on your PATH.
# ─────────────────────────────────────────────────────────────────────────────

# Absolute path of the folder this script lives in = your local my-skills clone.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$REPO/.claude/hooks/session-start.sh"
CLAUDE_DIR="$HOME/.claude"

if [ ! -f "$HOOK" ]; then
  echo "ERROR: could not find the sync hook at $HOOK" >&2
  echo "Are you running this from inside your my-skills clone?" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# On Windows/Git Bash, native Node and Python understand C:/... paths but not
# the /c/... form bash uses. cygpath -m converts /c/... -> C:/... (forward
# slashes, which also stay safe inside a bash command). On macOS/Linux there is
# no cygpath, so paths pass through unchanged.
to_win() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
REPO_W="$(to_win "$REPO")"
HOOK_W="$(to_win "$HOOK")"
CLAUDE_DIR_W="$(to_win "$CLAUDE_DIR")"

# ── Find a runtime that can safely edit JSON: Node first, then Python ─────────
RT=""; RT_KIND=""
if command -v node >/dev/null 2>&1; then
  RT="node"; RT_KIND="node"
else
  for n in \
    "/c/Program Files/nodejs/node.exe" \
    "/c/Program Files (x86)/nodejs/node.exe" \
    "${LOCALAPPDATA:-}/Programs/nodejs/node.exe" \
    "$HOME/AppData/Roaming/nvm"/*/node.exe \
    "$HOME/AppData/Local/Volta/bin/node.exe" \
    "$HOME/.volta/bin/node"; do
    if [ -x "$n" ]; then RT="$n"; RT_KIND="node"; break; fi
  done
fi
if [ -z "$RT" ]; then
  for p in python3 python py; do
    if command -v "$p" >/dev/null 2>&1; then RT="$p"; RT_KIND="python"; break; fi
  done
fi

# ── Merge the SessionStart hook into ~/.claude/settings.json ─────────────────
# We pass the repo path to the script as an ARGUMENT so the hook always syncs
# FROM this clone, no matter which project is open. Paths are passed as argv
# (not env vars) so they survive Git Bash -> native-exe path handling.
if [ "$RT_KIND" = "node" ]; then
  "$RT" -e '
    const fs = require("fs"), path = require("path");
    const [repo, hook, claudeDir] = process.argv.slice(1);
    fs.mkdirSync(claudeDir, { recursive: true });
    const file = path.join(claudeDir, "settings.json");
    let s = {};
    try { const t = fs.readFileSync(file, "utf8"); s = JSON.parse(t); if (!s || typeof s !== "object") s = {}; } catch (e) { s = {}; }
    s.hooks = s.hooks || {};
    let arr = Array.isArray(s.hooks.SessionStart) ? s.hooks.SessionStart : [];
    arr = arr.filter(g => !(((g && g.hooks) || []).some(h => String((h && h.command) || "").includes("session-start.sh"))));
    arr.push({ hooks: [{ type: "command", command: `bash "${hook}" "${repo}"` }] });
    s.hooks.SessionStart = arr;
    fs.writeFileSync(file, JSON.stringify(s, null, 2) + "\n");
    console.log("Wired global SessionStart hook -> " + repo);
  ' "$REPO_W" "$HOOK_W" "$CLAUDE_DIR_W"
elif [ "$RT_KIND" = "python" ]; then
  "$RT" - "$REPO_W" "$HOOK_W" "$CLAUDE_DIR_W" <<'PY'
import json, os, sys
repo, hook, claude_dir = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(claude_dir, exist_ok=True)
f = os.path.join(claude_dir, "settings.json")
try:
    with open(f, encoding="utf-8") as fh:
        s = json.load(fh)
    if not isinstance(s, dict):
        s = {}
except Exception:
    s = {}
s.setdefault("hooks", {})
arr = s["hooks"].get("SessionStart")
if not isinstance(arr, list):
    arr = []
def has_old(g):
    hooks = g.get("hooks", []) if isinstance(g, dict) else []
    return any("session-start.sh" in (h.get("command", "") if isinstance(h, dict) else "") for h in hooks)
arr = [g for g in arr if not has_old(g)]
arr.append({"hooks": [{"type": "command", "command": 'bash "%s" "%s"' % (hook, repo)}]})
s["hooks"]["SessionStart"] = arr
with open(f, "w", encoding="utf-8") as fh:
    json.dump(s, fh, indent=2)
    fh.write("\n")
print("Wired global SessionStart hook -> " + repo)
PY
else
  # No Node or Python found. If there is no settings file yet, we can safely
  # write a fresh one in pure bash. If one already exists, we will not risk
  # clobbering it — print the exact line to add by hand.
  SETTINGS="$CLAUDE_DIR/settings.json"
  if [ ! -s "$SETTINGS" ]; then
    cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash \"$HOOK_W\" \"$REPO_W\"" } ] }
    ]
  }
}
EOF
    echo "Wired global SessionStart hook (basic) -> $REPO_W"
  else
    echo "Could not find Node or Python, and you already have a settings file." >&2
    echo "Open this file:  $SETTINGS" >&2
    echo "and add this command under hooks.SessionStart:" >&2
    echo "    bash \"$HOOK_W\" \"$REPO_W\"" >&2
    exit 1
  fi
fi

# ── Machine files: things that live OUTSIDE ~/.claude and are not synced ─────
# sk, verify, preflight and the global gitignore are real files on the machine,
# not build output, so the sync never touches them. Without this section they
# exist on exactly one laptop and are lost with it. Idempotent: identical files
# are left alone, and the PATH gains one entry no matter how often this runs.
install_machine_files() {
  local src="$REPO/machine"
  [ -d "$src" ] || { echo "  (no machine/ folder in this clone - skipping)"; return 0; }

  local bin="$HOME/bin"
  mkdir -p "$bin"

  # sk.cmd and verify.cmd MUST be CRLF or cmd.exe mis-parses them. .gitattributes
  # checks them out that way, but a clone made with odd settings might not, so
  # normalise on write rather than trusting the checkout.
  local f base dest
  for f in "$src"/*.cmd; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"; dest="$bin/$base"
    if [ -f "$dest" ] && cmp -s "$f" "$dest"; then
      echo "  $base: already identical - unchanged"
    else
      sed 's/\r*$/\r/' "$f" > "$dest"
      echo "  $base: written to $dest (CRLF)"
    fi
  done

  for f in "$src"/*.ps1; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    # add-bin-to-path.ps1 is this installer's own helper, not a user command.
    [ "$base" = "add-bin-to-path.ps1" ] && continue
    dest="$bin/$base"
    if [ -f "$dest" ] && cmp -s "$f" "$dest"; then
      echo "  $base: already identical - unchanged"
    else
      cp "$f" "$dest"
      echo "  $base: written to $dest"
    fi
  done

  # Global gitignore. Merge line-by-line so a machine's own entries survive.
  if [ -f "$src/gitignore_global" ]; then
    local gi="$HOME/.gitignore_global" added=0
    touch "$gi"
    while IFS= read -r line || [ -n "$line" ]; do
      [ -z "$line" ] && continue
      if ! grep -qxF "$line" "$gi"; then printf '%s\n' "$line" >> "$gi"; added=$((added+1)); fi
    done < "$src/gitignore_global"
    git config --global core.excludesFile "$(to_win "$gi")"
    if [ "$added" -eq 0 ]; then echo "  gitignore: all entries already present - unchanged"
    else echo "  gitignore: added $added entr(y/ies) to $gi"; fi
  fi

  # PATH. Windows only, and via a real script FILE - never a quoted multi-statement
  # command through a layered shell (that road is in the failure ledger).
  if [ -f "$src/add-bin-to-path.ps1" ]; then
    local ps=""
    for cand in "$SYSTEMROOT/System32/WindowsPowerShell/v1.0/powershell.exe" \
                "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"; do
      [ -x "$cand" ] && ps="$cand" && break
    done
    if [ -n "$ps" ]; then
      "$ps" -NoProfile -ExecutionPolicy RemoteSigned -File "$(to_win "$src/add-bin-to-path.ps1")"
    else
      echo "  PATH: not Windows (or no powershell.exe) - add $bin to your PATH by hand"
    fi
  fi
}

echo ""
echo "Installing machine files (sk, verify, preflight, global gitignore)..."
install_machine_files

# Run the sync once right now so you do not have to restart to see your skills.
bash "$HOOK" "$REPO" >/dev/null 2>&1 || true

echo ""
echo "Done. All skills/rules/commands/agents are now synced to ~/.claude/"
echo "From now on they load automatically in every project, every session."
echo "sk, verify and preflight are in ~/bin and on your PATH."
