# FABLE-PARITY-INSTALL — add the Fable-parity mechanism to my-skills
> Execute top-to-bottom in the my-skills repo root. Author: Claude Fable 5 · 2026-07-06.
> What this installs: 4 skills + 1 always-on rule that encode Fable 5's working discipline
> (plan-gate, scope-fence, tests-bite, session-reflect) so ANY model — Sonnet 5, Opus 4.8,
> future releases — executes at Fable-grade rigor. The discipline survives the model.

## Rules for this task
- Branch: `feat/fable-parity-pack`. One PR. Conventional commits.
- Create the files EXACTLY as written below (they already match house format: frontmatter
  `name:` = folder name, description ends in a "Use when…" trigger).
- Do NOT rewrite or "improve" existing skills. Do NOT touch the harnesses. Surgical add only.
- Collision check already done against HEAD: no existing skill named plan-gate, scope-fence,
  tests-bite, or session-reflect. If that changed since 2026-07-06, STOP and report.

---

## FILE 1 — `skills/plan-gate/SKILL.md`

```markdown
---
name: plan-gate
description: Blocks any edit, command, or build step until a written 5-line plan exists — goal, unknowns, success criteria, step order, rollback. Prevents mid-task scope drift and half-understood changes. Use when starting ANY non-trivial task — code change, refactor, doc, config, migration — before the first edit is made.
---

# Plan-Gate

No edits before a written plan. Five lines, always the same five:

1. **Goal** — one sentence, the outcome not the activity.
2. **Unknowns** — facts you don't have. If the code holds the answer, READ IT NOW.
   If only the user holds it, STOP and ask that one question.
3. **Success criteria** — the observable "done bar." A command whose output proves it.
4. **Step order** — numbered, smallest-change-first.
5. **Rollback** — the one-line undo if step N goes wrong.

Write it, then execute it. If reality diverges from the plan mid-task, STOP,
amend the plan (one line: what changed and why), then continue. Silent divergence
is the failure this skill exists to prevent.

## Worked example — code task
> Task: "fix the miss-can-swish bug in shot.gd"
> 1. Goal: misses never pass through the rim cylinder.
> 2. Unknowns: rim radius constant location → read ball.gd → 0.23. None left.
> 3. Done bar: new test `miss_offset_outside_rim` red on old code, green on fix.
> 4. Steps: (1) polar offset radius ∈ [rim+0.05, 0.40]; (2) test; (3) run suite.
> 5. Rollback: revert the one function; no schema/save-data touched.

## Worked example — docs task
> Task: "write the README for Midnight-return-"
> 1. Goal: a stranger can open and run the project in <10 min.
> 2. Unknowns: Unity version → CLAUDE.md says 2023.2 LTS + HDRP 16. None left.
> 3. Done bar: README covers open/run/layout/state; no claim not verified in-repo.
> 4. Steps: skeleton from CLAUDE.md → verify each claim against Assets/ → prune.
> 5. Rollback: single new file; delete it.

## Failure smell this prevents
Mid-task drift: "while I'm here I'll also refactor X." If X isn't in the plan,
it's a new task — note it, don't do it.
```

## FILE 2 — `skills/scope-fence/SKILL.md`

```markdown
---
name: scope-fence
description: Executes the given spec exactly — no invented adjacent work, no unrequested refactors, no frameworks "for scale," and a hard stop when the spec's premise is already fixed in the code. Use when executing any written spec, handoff, ticket, or delegated task where fidelity to the request matters more than initiative.
---

# Scope-Fence

The spec is the contract. Inside it: full autonomy. Outside it: zero.

**The four fences:**
1. **No adjacent work.** Ugly code next to your change stays ugly unless the spec
   says otherwise. Note it in one line for the report; do not touch it.
2. **No unrequested abstraction.** Ship the simple version. If an upgrade path
   exists, name it in ONE line — never build it speculatively.
3. **Premise check, always.** Before executing, verify the spec's claim against
   the code. If the bug is already fixed / the file already exists / the count is
   already right: SAY SO AND STOP. Manufacturing work to satisfy a stale spec is
   a scope violation, not diligence.
4. **House style wins.** Read 3 neighboring files first; match their conventions
   even where you'd choose differently.

## Correctly refusing adjacent work — two examples
> Spec: "add a push_warning when defender registration no-ops."
> Observed: player.gd also lacks null checks elsewhere.
> Correct: add the ONE warning. Report: "player.gd has 2 similar unguarded paths
> — flagging, not fixing (out of scope)."

> Spec: "delete the dead backend/ directory."
> Observed: backend/ contains a util you could 'rescue' into mobile/.
> Correct: delete it all. Rescuing code nobody asked for is scope invention.
> If it mattered, git history has it.

## The stop clause
Premise already satisfied → output exactly: what you checked, what you found,
"no work performed," and stop. That report IS the deliverable.
```

## FILE 3 — `skills/tests-bite/SKILL.md`

```markdown
---
name: tests-bite
description: Enforces that every new test provably fails when the guard it covers is removed — the revert→red→restore→green ritual — so test suites catch real regressions instead of passing vacuously. Use when writing or reviewing ANY test, in any language, especially tests guarding money paths, data integrity, or security checks.
---

# Tests-Bite

A test that passes against broken code is worse than no test — it's false
confidence. Every test you write must be PROVEN to bite, once, before you ship it.

**The ritual (non-negotiable for money/data/security paths):**
1. Write the test against the FIXED code → green.
2. Revert the guard it covers (stash the fix / comment the check) → run → **must go RED**.
3. Restore the fix → green again.
4. Paste the red-run output in your PR/report. That paste is the proof; a claim
   without it doesn't count.

## pytest template
```python
def test_credit_never_negative(db):
    """BITE-PROOF: reverting the remaining>=amount guard in consume_ai_credit
    makes this fail (verified 2026-07-06, output in PR)."""
    seed_credits(db, user_id=U, amount=1)
    assert consume(db, U, 1) is True
    assert consume(db, U, 1) is False        # second consume must be rejected
    assert credits_of(db, U) == 0            # never driven negative
```

## jest template
```ts
test("replayed webhook is idempotent (BITE-PROOF: remove event-id dedupe → fails)", async () => {
  const evt = signedEvent({ id: "evt_1", type: "entitlement.granted" });
  await handle(evt);
  await handle(evt);                          // exact replay
  expect(await entitlementCount(user)).toBe(1);
});
```

**Scope note:** prove-the-bite once per guard, not per run — the docstring/name
records that it was done and when. For trivial pure-function tests the ritual is
optional; for anything touching money, auth, storage, or deletion it is mandatory.
```

## FILE 4 — `skills/session-reflect/SKILL.md`

```markdown
---
name: session-reflect
description: A three-phase end-of-session review that extracts durable facts, corrections, and reusable workflows from the session and writes them into PROGRESS.md — proposing (never auto-committing) any new standing rules. Use when a work session is ending, a task is handed off, or the user says "wrap up," "reflect," or "capture what we learned."
---

# Session-Reflect

Run at session end. Three phases, in order, output appended to the repo's
PROGRESS.md (house format: where-we-are / done / user-gated / gotchas).

**Phase 1 — Durable facts.** What did this session establish that a future
session must not rediscover? (Versions, paths, constants, environment quirks,
"X is actually Y.") → PROGRESS.md `## Machine gotchas` or `## Where we are`.

**Phase 2 — Corrections.** Every place the user corrected me, or reality
corrected the plan. Each correction is a candidate STANDING RULE — phrase it as
one imperative line. → List them under `## Proposed rules (user approval needed)`.
NEVER write directly into rules/ — the user promotes; I propose. One correction
appearing twice across sessions = escalate the proposal to the top of the list.

**Phase 3 — Workflows worth keeping.** Any sequence I'd repeat (a debug recipe,
a verification ritual, a data pull). If it's ≥3 steps and likely to recur,
propose it as a skill (`/new-skill` candidate) in one line: name + trigger.

**Output contract:** a single PROGRESS.md diff, nothing else. If nothing durable
emerged, write exactly one line saying so — an empty reflection honestly reported
beats invented lessons.
```

## FILE 5 — `rules/06-fable-parity.md`  *(fills the empty 06 slot; syncs into global CLAUDE.md)*

```markdown
# FABLE PARITY — EXECUTION DISCIPLINE (always on)

Quality comes from harness, not model size. On every non-trivial task:

1. **Plan before edit** (skill: plan-gate) — 5 lines: goal, unknowns, done bar,
   steps, rollback. Unknown only the user holds → one question, then wait.
2. **Spec is the fence** (skill: scope-fence) — no adjacent work, no speculative
   abstraction; premise already satisfied → report and stop.
3. **Tests must bite** (skill: tests-bite) — revert→red→restore→green proof for
   any guard on money, data, auth, or deletion. Paste the red run.
4. **Artifacts, not claims** — every "done" is backed by pasted command output.
5. **Reflect on exit** (skill: session-reflect) — durable facts and corrections
   land in PROGRESS.md; rule changes are PROPOSED, never self-applied.
6. **Model routing** — Sonnet-class executes; Opus-class judges, handles
   security-adjacent work, and runs >10-step autonomy; a Fable-class model, when
   available, is reserved for architecture/audit artifacts. A safety refusal is
   escalated verbatim — never rephrased around.
```

---

## VERIFY & SHIP (run in order; each block must succeed before the next)

```bash
bash bin/skill-doctor.sh
```

```bash
# README count fix (audit finding: hand-written counts drift — 411→ actual).
# Update the two counts in README.md to the live numbers:
echo "skills: $(ls skills | wc -l)  agents: $(ls agents/*.md | wc -l)"
```
Edit README.md so both stated counts match that output (the count-gate task
automates this later; until it lands, this manual sync is required in the same PR).

```bash
# Overlap check — the new triggers sit near strategic-compact and the harnesses.
# If /skill-audit flags a collision, NARROW the new skill's description; never
# touch the incumbent. Then regenerate:
cat skills/OVERLAP-REPORT.md | head -20
```

```bash
# Live-fire proof: sync, then in a fresh session give the model a small code task
# and confirm it emits the 5-line plan BEFORE its first edit. Paste that excerpt
# into the PR description as the acceptance evidence.
bash .claude/hooks/session-start.sh "$(pwd)"
```

**Done bar (all four):** skill-doctor clean · README counts match live numbers ·
overlap report regenerated with no unresolved collisions · fresh-session
transcript shows the plan-gate firing unprompted. Commit, push, open PR
`feat: fable-parity pack — 4 skills + rule 06`, report the four proofs, STOP.
