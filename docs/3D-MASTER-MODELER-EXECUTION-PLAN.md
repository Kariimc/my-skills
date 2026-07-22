# 3D Master Modeler — Full-Skill Execution Plan

> Written 2026-07-22. Companion to `HARNESS-AGENT-ROADMAP.md` (item #6) and
> `RULE-ENFORCEMENT-STREAMLINE-PLAN.md` (the "skill as menu" failure is a
> freelancing variant). Grounded in the skill as it exists today: 1,170 lines,
> phases 0–5 plus verified templates A/E/F/G, a setup.sh auto-installer, and a
> Phase 5 verification loop that is the whole point of the skill.

---

## Part 1 — The sharpened prompt

Original ask: *"I built a 3d master modeler so the agent could build real AAA
cinema quality assets and scenes. The agent doesn't use the entire skill
comprehensively and that is a failure. The outputs it produces without using
the skill top to bottom is less than desired."* The context-rich version:

> **Context: `skills/3d-master-modeler/SKILL.md` is a 1,170-line staged
> pipeline — Phase 0 intake/routing, 1 blockout, 2 topology & mesh audit,
> 3 procedural PBR, 3b photo-real image textures, 4 lighting/camera with
> image-based environment lighting ("the biggest realism jump"), 5 a
> verification & self-correction loop — plus verified templates for the master
> bpy script, environment lighting with GitHub-mirrored HDRI fallbacks,
> cinematic polish (depth of field + finishing), and engine texture-bake sets.
> Every template is marked verified on this pipeline against Blender 5.x, and
> the ledgers carry its landmines (F-44, F-46, F-52…F-55) and its proven
> methods (P-13…P-20). The skill auto-installs its own dependencies on cloud
> boxes via a SessionStart hook.**
>
> **The failure: when this skill fires, agents sample it instead of executing
> it — they run the master template, skip the photo-real texture pass, skip
> environment lighting, skip the Phase 5 verification loop, and ship a
> first-render result that looks procedural and flat instead of AAA/cinema
> quality. PROGRESS.md already carries the proposed rule from a real incident:
> "when the user explicitly names a staged skill, execute every applicable
> phase and gate in order; do not treat the skill as a menu of optional
> highlights." Prose alone has not fixed it.**
>
> **Task: make partial execution structurally impossible while keeping the
> skill's knowledge intact. Design the smallest machinery such that: (1) every
> applicable phase must leave a named proof artifact (a render, an audit
> printout, a diff score) before the next phase is legal; (2) "done" is
> rejected automatically if any applicable phase has no artifact — with
> "not applicable" allowed only as an explicit, stated decision, never a
> silent skip; (3) the finish line is a measured quality bar (verification
> loop ran, scores recorded, final renders inspected), not the agent's
> self-assessment; (4) the skill file itself stays the knowledge base — the
> enforcement lives in a run-card and an orchestrator, not in more prose.
> Reuse the existing harness patterns and the deliverable-verifier concept.**

---

## Part 2 — Why the skill gets sampled instead of executed

1. **1,170 lines vs. a finite attention budget.** An agent under context
   pressure reads the operating rules, grabs Template A, and starts building.
   The phases that make the difference between "3D render" and "cinema" —
   3b (image textures), 4's environment lighting, 5 (the correction loop) —
   sit deepest in the file and get truncated first. This is the same decay
   mechanism as the rulebook problem, applied to one skill.
2. **The phases produce no required evidence.** Nothing distinguishes a run
   that did the mesh audit from one that didn't — so skipping is invisible,
   and invisible skips always happen. (Same lesson as apex: unchecked = drifts.)
3. **The agent grades its own render.** Phase 5 exists precisely because first
   renders are always flawed, but the loop costs time and the agent is the one
   deciding whether to pay it. Self-graded quality bars collapse under "looks
   fine to me."
4. **It's the freelancing pattern in miniature** (enforcement plan, diagnosis
   #6): the prompt said "use the skill," the agent substituted its own cheaper
   plan, and the deviation surfaced only at handover — as a flat, sub-AAA image.

## Part 3 — The fix: run-card + phase gates (skill stays, enforcement moves out)

**1. The run-card (the core piece).** Add `skills/3d-master-modeler/runcard.md`
— a short table the executing agent must copy into the working directory and
fill as it goes. One row per phase; each row demands a *named proof artifact*:

| Phase | Proof required |
|---|---|
| 0 intake | one-line routing decision (framework, budget, deliverable) |
| 1 blockout | blockout render file |
| 2 topology | mesh-audit printout (tri counts, non-manifold check) |
| 3 PBR | material list + which sockets set |
| 3b photo-real | texture sources + resolutions actually applied |
| 4 light/camera | HDRI/environment used + lighting render |
| 5 verify loop | ≥N loop iterations with the numeric score per pass |
| delivery | export files + sizes + format rationale |

A row may say `N/A — <reason>` (stated decision) but may never be blank.
**A blank row means the run is not done.** This is what turns "skipped
silently" into "visibly incomplete."

**2. The orchestrator walks the phases, not the agent's memory.** Build
`harness-3d` (roadmap #6) as the standard way this skill runs for any
non-trivial asset: each phase is a step; the next phase unlocks only when the
run-card row has its artifact; the Phase 5 loop is driven by the harness with
an explicit iteration count and exit threshold, so it cannot be waved off.

**3. Independent finish line.** The final gate is the `deliverable-verifier`
(roadmap #1): it opens the actual renders (hero/side/top) and the actual
export, checks them against the run-card claims, and runs the numeric diff
when a reference exists. AAA is a measured claim, not a mood.

**4. Hook wiring (one line each).** The `handover-check` Stop hook (enforcement
plan, build item #1) learns one 3D signature: if the session touched this
skill and no completed run-card exists in the output, the handover is flagged
and fixed in the same turn. This also promotes the PROGRESS.md proposed rule
("named staged skill = execute every phase and gate in order") from proposed
prose to enforced machinery.

**5. What does NOT change.** SKILL.md stays the single knowledge base — no
rewrite, no split, no added prose rules inside it. The only additions are the
run-card template, the harness wrapper, and the hook signature. (Ponytail:
enforcement is ~1 small file + 2 wiring edits, not a restructure.)

## Part 4 — Build order for this fix

| # | Item | Effort |
|---|---|---|
| 1 | `runcard.md` template in the skill folder + a "fill this as you go" line in SKILL.md's operating rules | tiny |
| 2 | `handover-check` 3D signature (no completed run-card ⇒ not done) | tiny, rides on enforcement-plan item #1 |
| 3 | `harness-3d` phase-gated wrapper with driven Phase-5 loop | medium — roadmap #6 |
| 4 | `deliverable-verifier` as the finish line | medium — roadmap #1, shared with everything else |

Item 1 alone already changes behavior (a visible empty row is much harder to
ship past than an invisible skip); items 2–4 make it impossible.
