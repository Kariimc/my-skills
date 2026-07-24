#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Global Claude config sync (SessionStart hook)
#
# This repo is the SOURCE OF TRUTH for your global Claude setup. On every
# session start this hook copies the repo's top-level folders into ~/.claude/,
# which is the directory Claude Code reads for EVERY project. That is what makes
# these skills, rules, and commands available globally — not just in this repo.
#
#   skills/    ->  ~/.claude/skills/    (auto-discovered skills, all projects)
#   rules/     ->  ~/.claude/CLAUDE.md  (global instructions, all projects)
#   commands/  ->  ~/.claude/commands/  (slash commands, all projects)
#   agents/    ->  ~/.claude/agents/    (subagents, all projects)
# ─────────────────────────────────────────────────────────────────────────────

# Run async so the session starts immediately; sync finishes in the background.
echo '{"async": true, "asyncTimeout": 60000}'

# Source repo to sync FROM. Priority:
#   1. first argument  ($1)            — used by the global installer
#   2. $CLAUDE_PROJECT_DIR             — set by Claude when this repo is open
#   3. current directory               — last-resort fallback
PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Grab the latest skills/rules before syncing them into ~/.claude/. Fast-forward
# only, so a pull-only clone can never hit a merge conflict or block the session.
if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$PROJECT_DIR" pull --ff-only >/dev/null 2>&1 || true
fi

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# ── Mirror helpers (repo is the SOURCE OF TRUTH) ─────────────────────────────
# The old sync used additive `cp -r`, so anything deleted or renamed in the repo
# lingered in ~/.claude/ forever (skills kept auto-triggering). These mirror the
# destination to the repo — deletions propagate. rsync isn't available on the
# Windows/git-bash host, so this is delete-then-copy. Both print what they remove
# so the first sync per machine (which may drop hand-dropped local-only entries)
# is auditable. A skill/command/agent that exists ONLY in ~/.claude and not in
# the repo is QUARANTINED to ~/.claude/.sync-trash/<timestamp>/ (never silently
# destroyed — F-41) — put it in the repo to keep it live.
SYNC_TRASH="$CLAUDE_DIR/.sync-trash/$(date +%Y%m%d-%H%M%S)"
quarantine() {  # move a doomed file into the dated trash dir. NEVER deletes on
                # failure: mv, then copy+remove fallback, then leave the file in
                # place with a loud error and rc 1 (F-41: no silent destruction).
  local f="$1" rel="$2"
  if mkdir -p "$SYNC_TRASH/$(dirname "$rel")" 2>/dev/null \
     && { mv -f "$f" "$SYNC_TRASH/$rel" 2>/dev/null \
          || { cp -p "$f" "$SYNC_TRASH/$rel" 2>/dev/null && rm -f "$f"; }; }; then
    return 0
  fi
  echo "[session-start] QUARANTINE FAILED for $rel — file left in place, NOT deleted" >&2
  return 1
}
mirror_tree() {  # $2 becomes an exact copy of the tree at $1
  local src="$1" dst="$2" removed="" qfail=0
  if [ -d "$dst" ]; then
    removed=$(comm -23 \
      <(cd "$dst" && find . -type f 2>/dev/null | sort) \
      <(cd "$src" && find . -type f 2>/dev/null | sort)) || true
    if [ -n "$removed" ]; then
      echo "[session-start] mirror $(basename "$dst"): quarantining entries gone from repo (recoverable in ~/.claude/.sync-trash):"
      echo "$removed" | sed 's|^\./|  - |'
      while IFS= read -r rel; do
        rel="${rel#./}"
        quarantine "$dst/$rel" "$(basename "$dst")/$rel" || qfail=1
      done <<< "$removed"
    fi
    if [ "$qfail" = "1" ]; then
      # A file could not be quarantined. Deleting the tree now would destroy it,
      # so fall back to an additive overlay for this session: stale-but-safe.
      echo "[session-start] mirror $(basename "$dst"): quarantine incomplete — skipping delete step, overlay copy only (a stale entry may linger until the next clean sync)" >&2
      mkdir -p "$dst"
      cp -r "$src/." "$dst/"
      return 0
    fi
    rm -rf "$dst"
  fi
  mkdir -p "$dst"
  cp -r "$src/." "$dst/"
}
mirror_md_files() {  # $2 := the non-README *.md files of $1 (per-file mirror)
  local src="$1" dst="$2" base=""
  mkdir -p "$dst"
  for existing in "$dst"/*.md; do
    [ -e "$existing" ] || continue
    base=$(basename "$existing")
    [ "$base" = "README.md" ] && continue
    if [ ! -f "$src/$base" ]; then
      echo "[session-start] mirror $(basename "$dst"): quarantining $base (gone from repo; recoverable in ~/.claude/.sync-trash)"
      quarantine "$existing" "$(basename "$dst")/$base" || true  # on failure the file stays; error already printed
    fi
  done
  for f in "$src"/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    cp "$f" "$dst/"
  done
}

# ── 1. Skills (TIERED MIRROR) ────────────────────────────────────────────────
# If always-load.txt lists a core set, only those skills load into ~/.claude/
# (the rest stay in the repo, one `pull-skill <name>` away). Built in a temp dir
# and atomically swapped so a mid-build failure never touches the live dir.
# Hard FLOOR: absent/empty/malformed list, or fewer than 5 resolved skills, or a
# missing `relay` sentinel => fall back to mirroring ALL skills. The live skills
# dir is NEVER emptied — a bad list can't wipe the guardrails fleet-wide.
if [ -d "$PROJECT_DIR/skills" ]; then
  CORE_LIST="$PROJECT_DIR/always-load.txt"
  if [ -f "$CORE_LIST" ]; then
    tmp="$CLAUDE_DIR/skills.tmp.$$"
    rm -rf "$tmp"; mkdir -p "$tmp"
    n=0
    while IFS= read -r name || [ -n "$name" ]; do
      name="$(printf '%s' "$name" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      case "$name" in ''|\#*) continue ;; esac
      if [ -d "$PROJECT_DIR/skills/$name" ] && cp -r "$PROJECT_DIR/skills/$name" "$tmp/" 2>/dev/null; then
        n=$((n+1))
      fi
    done < "$CORE_LIST"
    if [ "$n" -ge 5 ] && [ -d "$tmp/relay" ]; then
      rm -rf "$CLAUDE_DIR/skills"
      mv "$tmp" "$CLAUDE_DIR/skills"
      echo "[session-start] skills: tiered core loaded ($n); full library in repo — /pull-skill <name> to add one"
    else
      rm -rf "$tmp"
      mirror_tree "$PROJECT_DIR/skills" "$CLAUDE_DIR/skills"
      echo "[session-start] skills: core list empty/invalid ($n resolved) — mirrored ALL as safe fallback"
    fi
  else
    mirror_tree "$PROJECT_DIR/skills" "$CLAUDE_DIR/skills"
  fi
fi

# ── 2. Rules -> global CLAUDE.md ─────────────────────────────────────────────
# All rules/*.md (except README.md) are concatenated, sorted, into CLAUDE.md.
if [ -d "$PROJECT_DIR/rules" ] && compgen -G "$PROJECT_DIR/rules/*.md" > /dev/null; then
  : > "$CLAUDE_DIR/CLAUDE.md"
  for rule in "$PROJECT_DIR"/rules/*.md; do
    [ "$(basename "$rule")" = "README.md" ] && continue
    cat "$rule" >> "$CLAUDE_DIR/CLAUDE.md"
    printf '\n\n' >> "$CLAUDE_DIR/CLAUDE.md"
  done
fi

# ── 2b. Failure ledger -> ~/.claude/FAILURES.md ──────────────────────────────
# The ledger was local-only and unversioned: one disk from gone, invisible to
# the cloud surface, and open to two agents appending to it at once with no
# history. The repo copy is now the source of truth and this makes ~/.claude a
# generated mirror of it (guard-destructive.sh blocks direct writes there and
# names this path instead). Kept OUT of rules/ on purpose — it is ~28KB and does
# not belong concatenated into CLAUDE.md on every session.
if [ -f "$PROJECT_DIR/FAILURES.md" ]; then
  cp "$PROJECT_DIR/FAILURES.md" "$CLAUDE_DIR/FAILURES.md"
fi

# ── 2c. Playbook -> ~/.claude/PLAYBOOK.md ────────────────────────────────────
# Same reasoning as the failure ledger: the two copies drifted (a wrong P-05
# lived on in ~/.claude after the repo copy was corrected). Repo copy is the
# source of truth; ~/.claude is a generated mirror of it.
if [ -f "$PROJECT_DIR/PLAYBOOK.md" ]; then
  cp "$PROJECT_DIR/PLAYBOOK.md" "$CLAUDE_DIR/PLAYBOOK.md"
fi

# ── 3. Slash commands (MIRROR, per-file, README excluded) ────────────────────
# Each commands/*.md becomes /<name>; README.md is docs, so skip it.
if [ -d "$PROJECT_DIR/commands" ] && compgen -G "$PROJECT_DIR/commands/*.md" > /dev/null; then
  mirror_md_files "$PROJECT_DIR/commands" "$CLAUDE_DIR/commands"
fi

# ── 4. Subagents (MIRROR, per-file, README excluded) ─────────────────────────
# Each agents/*.md becomes a callable subagent; README.md is docs, so skip it.
if [ -d "$PROJECT_DIR/agents" ] && compgen -G "$PROJECT_DIR/agents/*.md" > /dev/null; then
  mirror_md_files "$PROJECT_DIR/agents" "$CLAUDE_DIR/agents"
fi

# ── 5. Hooks (global) ────────────────────────────────────────────────────────
# Top-level hooks/*.sh are synced to ~/.claude/hooks/ so they can be wired into
# global (user-level) settings and run in EVERY project — e.g. the harness
# router that auto-routes prompts to the right ultimate-harness skill.
if [ -d "$PROJECT_DIR/hooks" ] && compgen -G "$PROJECT_DIR/hooks/*.sh" > /dev/null; then
  mkdir -p "$CLAUDE_DIR/hooks"
  for hook in "$PROJECT_DIR"/hooks/*.sh; do
    cp "$hook" "$CLAUDE_DIR/hooks/"
    chmod +x "$CLAUDE_DIR/hooks/$(basename "$hook")"
  done
fi

# ── 6. Register the harness router in global settings (idempotent) ────────────
# Adds a UserPromptSubmit hook pointing at the synced router. Additive merge:
# never removes or overwrites existing hooks, and skips if already registered.
# Claude Code's Windows hook wrapper (cmd) cannot execute a bare .sh path:
# the .sh file association opens a detached git-bash window, so the hook's
# stdin/stdout never reach Claude Code and the hook is silently inert.
# Register "<bash.exe> <script>" using space-free 8.3 Windows paths instead;
# on unix the bare executable script is already correct.
reg_hook_cmd() {
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*)
      # Must be the Git-for-Windows bin/ wrapper: bare usr/bin/bash.exe exits
      # 127 under cmd because the msys environment is never bootstrapped.
      _rt="$(cygpath -d / 2>/dev/null || cygpath -w / 2>/dev/null)"
      _rt="${_rt//\\//}"; _rt="${_rt%/}"
      _rs="$(cygpath -m "$1" 2>/dev/null || printf '%s' "$1")"
      if [ -n "$_rt" ] && [ -x "$_rt/bin/bash.exe" ]; then
        printf '%s "%s"' "$_rt/bin/bash.exe" "$_rs"
      else
        printf '%s' "$1"
      fi
      ;;
    *) printf '%s' "$1" ;;
  esac
}

ROUTER_PATH="$CLAUDE_DIR/hooks/harness-router.sh"
if command -v python3 >/dev/null 2>&1 && [ -f "$ROUTER_PATH" ]; then
  SETTINGS_FILE="$CLAUDE_DIR/settings.json" ROUTER_CMD="$(reg_hook_cmd "$ROUTER_PATH")" python3 - <<'PY' || true
import json, os

path = os.environ["SETTINGS_FILE"]
cmd  = os.environ["ROUTER_CMD"]

try:
    with open(path, encoding="utf-8-sig") as f:
        settings = json.load(f)
    if not isinstance(settings, dict):
        raise SystemExit(0)  # never clobber an unrecognized file
except FileNotFoundError:
    settings = {}
except ValueError:
    raise SystemExit(0)  # unparseable: abort, never replace

hooks = settings.setdefault("hooks", {})
ups = hooks.setdefault("UserPromptSubmit", [])

# Already registered? (match on the router filename, path-independent)
already = any(
    "harness-router.sh" in (h.get("command", ""))
    for group in ups if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)

if not already:
    ups.append({"hooks": [{"type": "command", "command": cmd}]})
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
    print("[session-start] registered harness-router UserPromptSubmit hook")
PY
fi

# ── 6b. Register guard-destructive as a global PreToolUse hook (idempotent) ──
GUARD_PATH="$CLAUDE_DIR/hooks/guard-destructive.sh"
if command -v python3 >/dev/null 2>&1 && [ -f "$GUARD_PATH" ]; then
  chmod +x "$GUARD_PATH"
  SETTINGS_FILE="$CLAUDE_DIR/settings.json" GUARD_CMD="$(reg_hook_cmd "$GUARD_PATH")" python3 - <<'PY' || true
import json, os

path = os.environ["SETTINGS_FILE"]
cmd  = os.environ["GUARD_CMD"]

try:
    with open(path, encoding="utf-8-sig") as f:
        settings = json.load(f)
    if not isinstance(settings, dict):
        raise SystemExit(0)  # never clobber an unrecognized file
except FileNotFoundError:
    settings = {}
except ValueError:
    raise SystemExit(0)  # unparseable: abort, never replace

hooks = settings.setdefault("hooks", {})
ptu = hooks.setdefault("PreToolUse", [])

already = any(
    "guard-destructive.sh" in (h.get("command", ""))
    for group in ptu if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)

if not already:
    ptu.append({"hooks": [{"type": "command", "command": cmd}]})
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
    print("[session-start] registered guard-destructive PreToolUse hook")
PY
fi

# ── 6b2. Register the newer global hooks (idempotent, same pattern as 6a/6b) ──
# ledger-sentinel  → UserPromptSubmit (injects matching FAILURES/PLAYBOOK entries)
# runcard-guard    → Stop            (3D sessions must ship a completed run-card)
# env-scout        → SessionStart    (probed environment fact sheet into context)
for SPEC in "ledger-sentinel.sh:UserPromptSubmit" "runcard-guard.sh:Stop" "cant-guard.sh:Stop" "env-scout.sh:SessionStart"; do
  H_NAME="${SPEC%%:*}"; H_EVENT="${SPEC##*:}"
  H_PATH="$CLAUDE_DIR/hooks/$H_NAME"
  if command -v python3 >/dev/null 2>&1 && [ -f "$H_PATH" ]; then
    chmod +x "$H_PATH"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json" H_CMD="$(reg_hook_cmd "$H_PATH")" H_NAME="$H_NAME" H_EVENT="$H_EVENT" python3 - <<'PY' || true
import json, os

path  = os.environ["SETTINGS_FILE"]
cmd   = os.environ["H_CMD"]
name  = os.environ["H_NAME"]
event = os.environ["H_EVENT"]

try:
    with open(path, encoding="utf-8-sig") as f:
        settings = json.load(f)
    if not isinstance(settings, dict):
        raise SystemExit(0)  # never clobber an unrecognized file
except FileNotFoundError:
    settings = {}
except ValueError:
    raise SystemExit(0)  # unparseable: abort, never replace

hooks = settings.setdefault("hooks", {})
groups = hooks.setdefault(event, [])

already = any(
    name in (h.get("command", ""))
    for group in groups if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)

if not already:
    groups.append({"hooks": [{"type": "command", "command": cmd}]})
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
    print(f"[session-start] registered {name} {event} hook")
PY
  fi
done

# ── 6c. Self-heal Windows-inert hook commands (tamper protection) ──────────────
# If any agent or tool rewrites a known hook command back to a form that is
# silently inert under the Windows cmd hook wrapper (a bare .sh path, or
# "bash <script>" when bash is not on PATH), normalize it back to the
# executable "<bash.exe> <script>" form. Runs every session start, so the
# enforcement layer restores itself. No-op on unix and on healthy files.
HOOK_WRAP_TPL="$(reg_hook_cmd __HOOK__)"
if [ "$HOOK_WRAP_TPL" != "__HOOK__" ] && command -v python3 >/dev/null 2>&1 \
   && [ -f "$CLAUDE_DIR/settings.json" ]; then
  SETTINGS_FILE="$CLAUDE_DIR/settings.json" WRAP_TPL="$HOOK_WRAP_TPL" python3 - <<'PY' || true
import json, os, re

path = os.environ["SETTINGS_FILE"]
tpl  = os.environ["WRAP_TPL"]
KNOWN = {"harness-router.sh", "guard-destructive.sh", "guard-junk-files.sh",
         "guard-handoff.sh", "plain-words-guard.sh", "loose-ends-guard.sh",
         "guard-fabrication.sh", "mark-session-head.sh",
         "ledger-sentinel.sh", "runcard-guard.sh", "env-scout.sh", "cant-guard.sh",
         "selftest-guards.sh", "session-start.sh"}

try:
    with open(path, encoding="utf-8-sig") as f:
        settings = json.load(f)
except (FileNotFoundError, ValueError):
    raise SystemExit(0)
if not isinstance(settings, dict):
    raise SystemExit(0)

def winpath(p):
    p = p.replace(chr(92), "/")
    m = re.match(r"^/([A-Za-z])/(.*)$", p)
    if m:
        p = m.group(1).upper() + ":/" + m.group(2)
    return p

def heal(cmd):
    m = re.match(r'^\s*(\S+\.sh)\s*(.*)$', cmd) \
        or re.match(r'^\s*bash\s+"?([^"]+\.sh)"?\s*(.*)$', cmd)
    if not m:
        return cmd
    script, rest = m.group(1), m.group(2).strip()
    if script.rsplit("/", 1)[-1].rsplit(chr(92), 1)[-1] not in KNOWN:
        return cmd
    new = tpl.replace("__HOOK__", winpath(script))
    if rest:
        new += " " + rest
    return new

changed = 0
for groups in (settings.get("hooks") or {}).values():
    if not isinstance(groups, list):
        continue
    for group in groups:
        if not isinstance(group, dict):
            continue
        for h in group.get("hooks", []):
            if isinstance(h, dict) and isinstance(h.get("command"), str):
                new = heal(h["command"])
                if new != h["command"]:
                    h["command"] = new
                    changed += 1
if changed:
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(settings, f, indent=2)
        f.write(chr(10))
    os.replace(tmp, path)
    print("[session-start] healed %d Windows-inert hook command(s)" % changed)
PY
fi

# ── 7. Activate the control-plane pre-commit guard (self-scoping) ────────────
# Only repos that ship .githooks/pre-commit (i.e. this skills repo) get the
# guard; every other repo is untouched. Makes the guard survive fresh clones
# with no manual `git config` step.
if [ -f "$PROJECT_DIR/.githooks/pre-commit" ] \
   && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  chmod +x "$PROJECT_DIR"/.githooks/* 2>/dev/null || true
  [ -f "$PROJECT_DIR/bin/skill-doctor.sh" ] && chmod +x "$PROJECT_DIR/bin/skill-doctor.sh" 2>/dev/null || true
  git -C "$PROJECT_DIR" config core.hooksPath .githooks 2>/dev/null || true
fi

# ── 8. Launcher settings (preserved from previous setup) ─────────────────────
if [ -f "$PROJECT_DIR/.claude/launcher-settings.json" ]; then
  cp "$PROJECT_DIR/.claude/launcher-settings.json" "$CLAUDE_DIR/launcher-settings.json"
fi
