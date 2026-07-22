# TIER4-EVALS-INSTALL — model-eval harness for my-skills
> Execute in the my-skills repo root. Author: Claude Fable 5 · 2026-07-06.
> Branch: `feat/tier4-evals`. One PR.
> Installs `datasets/gold-standards/` (3 tasks: prompt + Fable gold + rubric) and
> `bin/eval-models.sh` (runs any model list against the tasks, grades with Opus 4.8
> as judge, prints a parity scorecard). Purpose: every future model release gets
> measured against Kariim's real work in one command — the permanent asset.
> House style matches bin/eval-router.sh (paths, preflights, exit codes).

---

## FILE 1 — `datasets/gold-standards/README.md`
```markdown
# Gold Standards

Fable-5 reference answers on real tasks from this portfolio, captured 2026-07-06
while Fable was subscription-included. `bin/eval-models.sh` grades candidate
models against them; ≥8/10 on a task = "Fable parity" there.

Layout: one dir per task — `prompt.md` (sent verbatim to the candidate),
`gold.md` (Fable's reference), `rubric.md` (5 dimensions × 0–2, judge-facing).
Runs land in `runs/<date>/`, committed, so history shows model progress.
Grow the set from real PRs with executable done-bars; keep tasks ≤1 screen.
```

## FILE 2 — `datasets/gold-standards/b1-bug-diagnosis/prompt.md`
```markdown
In this Godot shooter, misses sometimes look like clean makes. shot.gd targets
`rim_pos + Vector3(randf_range(-0.35,0.35), 0, randf_range(-0.35,0.35))` on a
miss; rim radius is 0.23. Diagnose the root cause and give the fix, including
how you would verify it.
```

## FILE 3 — `datasets/gold-standards/b1-bug-diagnosis/gold.md`
```markdown
The miss offset is sampled per-axis from a square of half-width 0.35 centered
on the rim, so any sample landing within 0.23 m of center — roughly
π·0.23²/0.70² ≈ 34% of the square — produces a "miss" whose flight path passes
through the hoop: a visual swish scored as a miss. Root cause: the offset
sample space includes the rim disk.

Fix — sample in polar form with a floor outside the rim:
`angle = randf()*TAU; radius = randf_range(rim_radius + 0.05, 0.40);
offset = Vector3(cos(angle), 0, sin(angle)) * radius`

Verify: unit test asserting 10k sampled miss offsets all satisfy
`offset.length() > rim_radius` (red on old code, green on fix), plus one
visual run confirming misses now clank or rim out.
```

## FILE 4 — `datasets/gold-standards/b1-bug-diagnosis/rubric.md`
```markdown
Score 0–2 per dimension; quote the candidate's own words as evidence. Do not
reward content absent from the answer. Final line exactly: `TOTAL: <n>/10`
① Correctness — identifies that the offset space overlaps the rim disk.
② Root-cause depth — names the mechanism (per-axis square sampling vs radial
   geometry), not just "offset too small"; quantifying the overlap = full marks.
③ Scope discipline — fixes the sampling only; no outcome re-rolls, no physics
   rewrite, no adjacent refactors.
④ Verifiability — a concrete red-on-old/green-on-new test, not "test it".
⑤ Compression — nothing cuttable; penalize hedging and filler.
Typical weak answers: clamp one axis, enlarge the range (shrinks but keeps the
overlap), or re-roll outcomes — cap ① at 1 and ② at 0 for these.
```

## FILE 5 — `datasets/gold-standards/b2-code-review/prompt.md`
```markdown
Review this sync design and name the single most important issue, its blast
radius, and the fix: a SessionStart hook syncs a repo to ~/.claude/ with
`cp -r repo/skills/. ~/.claude/skills/` (same pattern for commands and agents);
rules are different — they are rebuilt from zero into CLAUDE.md each sync.
```

## FILE 6 — `datasets/gold-standards/b2-code-review/gold.md`
```markdown
`cp -r` is additive-only: anything deleted or renamed in the repo persists in
~/.claude/ forever — on every machine — and, for skills, keeps auto-triggering.
The repo silently stops being the source of truth at the first deletion.

Blast radius: all three copied categories (skills/commands/agents), every
machine, unbounded time; worst case is a removed-for-cause skill still firing
globally. The rules path is immune because rebuild-from-zero has correct
delete semantics — which is also the fix pattern.

Fix: mirror semantics for the other three (`rsync -a --delete`, or
delete-dir-then-copy), with the tradeoff stated: mirror erases anything that
exists only locally, so the first sync per machine should print its removals.

Verify: add a throwaway skill → sync → present; delete it from the repo →
sync → it must be gone from ~/.claude/skills/.
```

## FILE 7 — `datasets/gold-standards/b2-code-review/rubric.md`
```markdown
Score 0–2 per dimension; quote evidence; never reward absent content.
Final line exactly: `TOTAL: <n>/10`
① Correctness — spots the deletion asymmetry as THE issue.
② Root-cause depth — explains persistence-forever + still-auto-triggering, and
   notices the rules path already demonstrates the correct semantics.
③ Scope discipline — one issue as asked; no laundry list of nits (quoting,
   async, portability) diluting it.
④ Verifiability — the add/delete/sync round-trip check or equivalent.
⑤ Compression — tight; penalize restating the prompt.
Typical weak answers: lead with quoting/portability nits, or propose mirror
without naming the local-only-data tradeoff — cap ② at 1 for the latter.
```

## FILE 8 — `datasets/gold-standards/b3-skill-author/prompt.md`
```markdown
Write a Claude skill file (YAML frontmatter with name and a description ending
in a "Use when…" trigger) that blocks any edit until a 5-line written plan
exists — goal, unknowns, success criteria, step order, rollback. Include one
worked example and name the failure mode it prevents. Keep it executable-by-
reading, not an essay.
```

## FILE 9 — `datasets/gold-standards/b3-skill-author/gold.md`
```markdown
---
name: plan-gate
description: Blocks any edit, command, or build step until a written 5-line plan exists — goal, unknowns, success criteria, step order, rollback. Prevents mid-task scope drift and half-understood changes. Use when starting ANY non-trivial task — code change, refactor, doc, config, migration — before the first edit is made.
---

# Plan-Gate

No edits before a written plan. Five lines, always the same five:

1. **Goal** — one sentence, the outcome not the activity.
2. **Unknowns** — facts you don't have. If the code holds the answer, READ IT
   NOW. If only the user holds it, STOP and ask that one question.
3. **Success criteria** — the observable "done bar." A command whose output
   proves it.
4. **Step order** — numbered, smallest-change-first.
5. **Rollback** — the one-line undo if step N goes wrong.

Write it, then execute it. If reality diverges mid-task, STOP, amend the plan
(one line: what changed and why), then continue. Silent divergence is the
failure this skill exists to prevent.

## Worked example
> Task: "fix the miss-can-swish bug in shot.gd"
> 1. Goal: misses never pass through the rim cylinder.
> 2. Unknowns: rim radius constant location → read ball.gd → 0.23. None left.
> 3. Done bar: new test `miss_offset_outside_rim` red on old code, green on fix.
> 4. Steps: (1) polar offset radius ∈ [rim+0.05, 0.40]; (2) test; (3) run suite.
> 5. Rollback: revert the one function; no schema/save-data touched.

## Failure smell this prevents
Mid-task drift: "while I'm here I'll also refactor X." If X isn't in the plan,
it's a new task — note it, don't do it.
```

## FILE 10 — `datasets/gold-standards/b3-skill-author/rubric.md`
```markdown
Score 0–2 per dimension; quote evidence; never reward absent content.
Final line exactly: `TOTAL: <n>/10`
① Correctness — valid frontmatter (name + description ending in a "Use when…"
   trigger) and all five plan lines present.
② Root-cause depth — the unknowns line forks correctly: code-holds-answer →
   read now; user-holds-answer → stop and ask. Missing fork caps at 1.
③ Scope discipline — stays a plan gate; generic productivity advice or extra
   ceremonies = 0.
④ Verifiability — worked example's done bar is an observable red/green check.
⑤ Compression — executable-by-reading; essays and repeated ideas lose marks.
```

## FILE 11 — `bin/eval-models.sh`
```bash
#!/bin/bash
set -euo pipefail
# ─────────────────────────────────────────────────────────────────────────────
# eval-models.sh — grade candidate models against the Fable gold standards.
#
# WHAT IT DOES
#   For every task dir in datasets/gold-standards/ (prompt.md + gold.md +
#   rubric.md), sends prompt.md to each candidate model via the Claude Code
#   CLI, saves the answer under runs/<date>/, then has the JUDGE model score
#   candidate-vs-gold against rubric.md. Prints a task × model scorecard and
#   flags Fable parity (score >= PARITY, default 8).
#   Safety refusals (stop-and-refuse output) are labeled ROUTED and excluded
#   from scoring — a refusal is a routing fact, not a quality signal.
#
# USAGE
#   bash bin/eval-models.sh                          # defaults below
#   MODELS="claude-sonnet-5" bash bin/eval-models.sh
#   JUDGE=claude-opus-4-8 PARITY=8 bash bin/eval-models.sh
#   bash -n bin/eval-models.sh                       # syntax check
#
# EXIT CODES: 0 ran and scored · 2 setup error (no CLI / no dataset)
# NOTE: informational by default (no accuracy gate) — model comparison is a
#   measurement, not a regression test. Add a gate only if a floor emerges.
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GS_DIR="$REPO_ROOT/datasets/gold-standards"
MODELS="${MODELS:-claude-sonnet-5 claude-opus-4-8}"
JUDGE="${JUDGE:-claude-opus-4-8}"
PARITY="${PARITY:-8}"
RUN_DIR="$GS_DIR/runs/$(date +%Y-%m-%d)"

command -v claude >/dev/null 2>&1 || { echo "eval-models: claude CLI not on PATH" >&2; exit 2; }
ls -d "$GS_DIR"/*/prompt.md >/dev/null 2>&1 || { echo "eval-models: no task dirs under $GS_DIR" >&2; exit 2; }
mkdir -p "$RUN_DIR"

RESULTS_TSV="$(mktemp)"; trap 'rm -f "$RESULTS_TSV"' EXIT

looks_refused() {  # crude but safe: short output that opens by declining
  local f="$1"
  [ "$(wc -c < "$f")" -lt 400 ] && grep -qiE "can't help|cannot help|unable to (help|assist)|won't be able" "$f"
}

for task_dir in "$GS_DIR"/*/; do
  task="$(basename "$task_dir")"
  [ -f "$task_dir/prompt.md" ] && [ -f "$task_dir/gold.md" ] && [ -f "$task_dir/rubric.md" ] || continue
  for model in $MODELS; do
    ans="$RUN_DIR/$task.$model.md"
    echo "── $task × $model" >&2
    if ! claude -p "$(cat "$task_dir/prompt.md")" --model "$model" > "$ans" 2>/dev/null || [ ! -s "$ans" ]; then
      printf '%s\t%s\tERROR\n' "$task" "$model" >> "$RESULTS_TSV"; continue
    fi
    if looks_refused "$ans"; then
      printf '%s\t%s\tROUTED\n' "$task" "$model" >> "$RESULTS_TSV"; continue
    fi
    grade="$RUN_DIR/$task.$model.grade.md"
    claude -p "You are a strict grader. Score the CANDIDATE against the GOLD using the RUBRIC.
Score each dimension 0-2 quoting the candidate's own words as evidence. Do not
reward content absent from the candidate. End with exactly one line: TOTAL: <n>/10

RUBRIC:
$(cat "$task_dir/rubric.md")

GOLD:
$(cat "$task_dir/gold.md")

CANDIDATE:
$(cat "$ans")" --model "$JUDGE" > "$grade" 2>/dev/null || true
    score="$(grep -oE 'TOTAL: *[0-9]+/10' "$grade" | tail -n1 | grep -oE '[0-9]+' | head -n1 || true)"
    printf '%s\t%s\t%s\n' "$task" "$model" "${score:-UNGRADED}" >> "$RESULTS_TSV"
  done
done

awk -v parity="$PARITY" -F'\t' '
{ r[$1 FS $2] = $3; tasks[$1]=1; models[$2]=1 }
END {
  printf "\nGold-Standard Model Eval  (parity bar: >=%d/10)\n", parity
  printf "================================================\n"
  printf "%-22s", "task"
  for (m in models) printf " %-18s", m
  printf "\n"
  for (t in tasks) {
    printf "%-22s", t
    for (m in models) {
      v = r[t FS m]
      tag = (v+0 >= parity && v ~ /^[0-9]+$/) ? v"/10 PARITY" : (v ~ /^[0-9]+$/ ? v"/10" : v)
      printf " %-18s", tag
    }
    printf "\n"
  }
  printf "\nAnswers + judge transcripts: see runs/ dir. ROUTED = safety refusal (excluded). \n"
}' "$RESULTS_TSV"
echo "run dir: $RUN_DIR"
```

---

## VERIFY & SHIP
```bash
bash -n bin/eval-models.sh && chmod +x bin/eval-models.sh
```
```bash
ls datasets/gold-standards/*/{prompt,gold,rubric}.md | wc -l   # must print 9
```
```bash
bash bin/eval-models.sh    # full run (needs claude CLI auth; ~6 model calls + 6 gradings)
```
```bash
git add datasets/gold-standards bin/eval-models.sh && ls datasets/gold-standards/runs/
```
**Done bar:** syntax check clean · 9 dataset files · one full run committed under
`runs/<date>/` with a scorecard showing a numeric score or ROUTED per cell —
no ERROR/UNGRADED cells. Commit `feat: tier4 — gold-standard eval harness`,
push, open PR, paste the scorecard in the PR body, STOP.

**Scope record:** no CI gate added (measurement, not regression — gate only if
a floor emerges, one line via THRESHOLD-style env) · refusal detection is
deliberately crude-but-safe; upgrade path is reading the CLI's structured
output format, one line, later · dataset grows from Wave-1 PRs per W2.3.
