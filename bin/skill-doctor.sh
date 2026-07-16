#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# skill-doctor — control-plane integrity checker for the my-skills repo.
#
# The single engine behind the `skill-ship` skill and the pre-commit guard.
# Catches the failure class that caused a month of drift: stale counts, skills
# that can't auto-fire (no trigger), and invalid/mismatched frontmatter.
#
# Usage:
#   skill-doctor.sh            # check mode: report; exit 1 on HARD failures
#   skill-doctor.sh --fix      # fix safe drift (README counts) + write triage report
#
# HARD (block a commit): missing SKILL.md, missing `name:`, name != folder.
# SOFT (warn only):       missing a "Use when" trigger, stale counts.
# ─────────────────────────────────────────────────────────────────────────────

FIX=0
STAGED=0
for a in "$@"; do
  case "$a" in
    --fix)    FIX=1 ;;
    --staged) STAGED=1 ;;
  esac
done

# Locate repo root: the dir that has both skills/ and rules/.
ROOT="${SKILL_DOCTOR_ROOT:-}"
if [ -z "$ROOT" ]; then
  d="$PWD"
  while [ "$d" != "/" ]; do
    if [ -d "$d/skills" ] && [ -d "$d/rules" ]; then ROOT="$d"; break; fi
    d="$(dirname "$d")"
  done
fi
if [ -z "$ROOT" ] || [ ! -d "$ROOT/skills" ]; then
  echo "skill-doctor: not inside a skills control repo — nothing to do."
  exit 0
fi
cd "$ROOT"

# Extract the raw description value from a SKILL.md (handles plain, quoted, and
# block `>`/`|` scalars): everything from `description:` up to the next
# top-level frontmatter key or the closing `---`.
extract_desc() {
  awk '
    NR==1 && $0=="---" {infm=1; next}
    infm && /^---[[:space:]]*$/ {exit}
    infm && /^description[[:space:]]*:/ {
      cap=1; line=$0; sub(/^description[[:space:]]*:[[:space:]]*/,"",line); print line; next
    }
    infm && cap && /^[A-Za-z0-9_-]+[[:space:]]*:/ {cap=0}
    infm && cap {print}
  ' "$1"
}

# Descriptions intentionally tuned long for trigger precision — exempt from the
# SOFT length warning (still subject to the HARD 1024 ceiling).
long_desc_ok=" docx xlsx claude-api "

hard=0
soft=0
triageless=()

# ── 1 & 2: per-skill frontmatter validation ─────────────────────────────────
# --staged scopes this scan to skill folders with staged changes (pre-commit
# speed: ~2000 process spawns → a handful). Untouched skills were validated when
# last committed, and the pre-push `doctor` gate re-runs the FULL scan — so
# coverage at push time is unchanged. Windows process spawns cost ~100ms each;
# this is the difference between 3 minutes and 2 seconds per commit.
if [ "$STAGED" = "1" ]; then
  mapfile -t scan_dirs < <(git diff --cached --name-only -- skills/ | awk -F/ 'NF>=2 && $2!="" {print "skills/" $2 "/"}' | sort -u)
else
  scan_dirs=(skills/*/)
fi
for dir in ${scan_dirs[@]+"${scan_dirs[@]}"}; do
  [ -d "$dir" ] || continue
  folder="$(basename "$dir")"
  f="${dir}SKILL.md"
  if [ ! -f "$f" ]; then
    echo "HARD  $folder — missing SKILL.md"; hard=$((hard+1)); continue
  fi
  name="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d "\"'" | sed 's/[[:space:]]*$//')"
  if [ -z "$name" ]; then
    echo "HARD  $folder — no 'name:' in frontmatter"; hard=$((hard+1))
  elif [ "$name" != "$folder" ]; then
    echo "HARD  $folder — name mismatch (frontmatter name='$name')"; hard=$((hard+1))
  fi
  # Trigger check — scoped to the DESCRIPTION, not the whole file. The
  # description is the only text Claude loads for auto-invocation matching, so a
  # skill with "When to Activate" in its body but a trigger-less description will
  # not fire reliably. Accept the full family of trigger phrasings.
  desc="$(extract_desc "$f")"
  if ! printf '%s' "$desc" | grep -qiE 'use (when|whenever|this|it|for|to|after|before|only|specifically)|trigger|activate|invoke when|(when|whenever) (the user|you)'; then
    triageless+=("$folder"); soft=$((soft+1))
  fi
  # Description length — Claude Code rejects/truncates descriptions over 1024
  # chars, which silently breaks auto-invocation. HARD over 1024, SOFT over 700.
  oneline="$(printf '%s' "$desc" | tr '\n' ' ' | sed -E 's/^[[:space:]]*[>|][+-]?[0-9]*[[:space:]]*//; s/[[:space:]]+/ /g; s/^ //; s/ $//')"
  dlen=${#oneline}
  if [ "$dlen" -gt 1024 ]; then
    echo "HARD  $folder — description ${dlen} chars (>1024; Claude Code will reject/truncate it)"; hard=$((hard+1))
  elif [ "$dlen" -gt 700 ] && [ "${long_desc_ok#* $folder }" = "$long_desc_ok" ]; then
    echo "SOFT  $folder — description ${dlen} chars (>700; trim for reliable matching)"; soft=$((soft+1))
  fi
done

# ── 3: count reconciliation (root README.md only — catalog has per-category) ──
actual_skills=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
actual_agents=$(find agents -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')

count_drift=0
if [ -f README.md ]; then
  claimed=$(grep -oE '[0-9]+ skills' README.md | grep -oE '[0-9]+' | sort -u | tr '\n' ' ')
  for c in $claimed; do
    [ "$c" != "$actual_skills" ] && count_drift=1
  done
  if [ "$count_drift" = "1" ]; then
    echo "SOFT  README.md skill count drift — claims [$claimed], actual $actual_skills"
    soft=$((soft+1))
    if [ "$FIX" = "1" ]; then
      sed -i -E "s/[0-9]+ skills/${actual_skills} skills/g; s/[0-9]+ (specialist )?subagents/${actual_agents} \1subagents/g" README.md
      echo "FIX   README.md counts -> ${actual_skills} skills, ${actual_agents} subagents"
    fi
  fi
fi

# ── 4: triage report for trigger-less skills ────────────────────────────────
# Never regenerate from a --staged (partial) scan - it would clobber the full
# list with only the staged subset. Full runs (pre-push doctor gate, apex.sh, manual) keep it fresh.
if [ "$FIX" = "1" ] && [ "$STAGED" = "0" ]; then
  report="skills/TRIGGERLESS-REPORT.md"
  {
    echo "# Trigger-less skills — triage"
    echo
    echo "> Auto-generated by \`bin/skill-doctor.sh --fix\`. These skills have no"
    echo "> clear \"Use when …\" trigger in their description, so auto-invocation is"
    echo "> unreliable. Each needs a one-line \"Use when the user wants to …\" clause"
    echo "> appended to its \`description:\`. Not a HARD failure — they still work when"
    echo "> called by name."
    echo
    echo "Count: ${#triageless[@]} of ${actual_skills} skills."
    echo
    if [ "${#triageless[@]}" -gt 0 ]; then
      printf '%s\n' "${triageless[@]}" | sort | sed 's/^/- [ ] /'
    else
      echo "_None — every skill has a trigger._"
    fi
  } > "$report"
  echo "FIX   wrote $report (${#triageless[@]} skills to triage)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo "─────────────────────────────────────────────"
echo "skill-doctor: ${actual_skills} skills, ${actual_agents} agents | HARD=$hard SOFT=$soft"
if [ "$hard" -gt 0 ]; then
  echo "✗ HARD failures present — fix before committing."
  exit 1
fi
echo "✓ no blocking issues."
exit 0
