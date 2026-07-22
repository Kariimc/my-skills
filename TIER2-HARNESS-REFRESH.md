# TIER2-HARNESS-REFRESH — surgical upgrades to the six harness skills
> Execute in the my-skills repo root. Author: Claude Fable 5 · 2026-07-06.
> Branch: `feat/harness-refresh-tier2`. One PR. These are EXACT in-place edits —
> apply with str-replace fidelity. Do NOT rewrite, reflow, or "improve" anything
> beyond these blocks (scope-fence applies; the harnesses were reviewed in full
> and are otherwise correct as-is).
> Verified against HEAD 2026-07-06 — if any old_str fails to match, STOP and report;
> do not fuzzy-match.

---

## EDIT SET 1 — Subagent protocol block (identical 6× insertion)

**Why:** every harness dispatches subagents (Task tool); none defines what to do
when a subagent returns a safety refusal (Sonnet 5 cyber safeguards return
`stop_reason: "refusal"` as an HTTP-200 success) or when revisions stall.
Insert this block into EACH of the six files, immediately BEFORE the `## Related`
heading:

```markdown
## Subagent protocol (all dispatches)
- **Refusals escalate, never re-route.** A subagent safety refusal is returned
  verbatim to the operator/user; NEVER rephrase, split, or retry the request to
  get around it. Log it as `BLOCKED-SAFETY: <task>` and continue other lanes.
- **Artifacts, not claims.** A subagent's "done" counts only with pasted command
  output / diff / URL. No artifact → treat as not done, one revise cycle.
- **Two revisions, then up.** A subtask failing its gate twice escalates to the
  operator with the failing evidence — never a third silent retry.
```

Files (apply identically): `skills/harness-build/SKILL.md`,
`skills/harness-quality/SKILL.md`, `skills/harness-research/SKILL.md`,
`skills/harness-audit/SKILL.md`, `skills/harness-autonomous/SKILL.md`,
`skills/harness-refactor/SKILL.md`.

---

## EDIT SET 2 — `skills/harness-autonomous/SKILL.md`: add the missing output contract

**Why:** the only harness with no output contract, and the one that runs
unattended — a wake that silently does nothing is invisible today.

Insert immediately BEFORE the new `## Subagent protocol` block (i.e. what was
before `## Related`):

```markdown
## Output contract

Every wake writes exactly one report line to the run log (file-based memory),
even when nothing happened — silence is indistinguishable from a crash:

`WAKE <iso-ts>: picked=<task|none> did=<one line> gate=<pass/fail+evidence> next=<iso-ts> state=<progress|stalled(k)|done>`

Worked example:
`WAKE 2026-07-07T08:00: picked=brief did=wrote PROGRESS summary, 3 repos gate=pass(file exists, 41 lines) next=2026-07-08T08:00 state=progress`

Hard rules: `stalled(k)` at k≥3 triggers the recover step, k≥5 notifies the
user and pauses the schedule — an autonomous loop that can only fail loudly.
`done` requires the explicit termination condition, quoted.
```

---

## EDIT SET 3 — `skills/harness-refactor/SKILL.md`: add the missing output contract

Insert immediately BEFORE the new `## Subagent protocol` block:

```markdown
## Output contract

"Behavior unchanged" is evidenced, never asserted:

```
BASELINE: <test command + count green before any change>
STEPS:    <n> transformations, each named (extract/inline/dedupe/delete) + LOC delta
VERIFY:   <same test command + count green after — identical count or explained>
REVERTED: <steps rolled back mid-run, or "none">
SMELL:    <the targeted smell> → <gone|reduced, with the measurement>
```

Worked example:
`BASELINE: pytest -q → 47 passed · STEPS: 4 (extract crowd_bowl, extract spawner, dedupe texture-load, delete dead GameState wire) −212 LOC · VERIFY: pytest -q → 47 passed · REVERTED: none · SMELL: main.gd god-object → 430→61 lines`
```

---

## VERIFY & SHIP

```bash
bash bin/skill-doctor.sh
```

```bash
# Contracts present in all six + refusal rule countable:
grep -L "Subagent protocol" skills/harness-*/SKILL.md   # MUST print nothing
grep -c "Refusals escalate" skills/harness-*/SKILL.md    # each line ends :1
```

```bash
bash .claude/hooks/session-start.sh "$(pwd)"   # sync, then confirm in ~/.claude/skills/
```

**Done bar (all three):** skill-doctor clean · both greps as specified · synced
copies match repo. Commit `feat: harness refresh — subagent refusal protocol + missing output contracts`,
push, open PR, report the grep outputs, STOP.

**Explicitly NOT done (scope record):** no rewriting of the four existing output
contracts (already correct), no model-routing duplication into harness bodies
(rules/06-fable-parity.md covers it globally — installed via FABLE-PARITY-INSTALL.md),
no changes to the loops, examples, or routing tables.
