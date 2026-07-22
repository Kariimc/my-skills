---
name: harness-3d
description: >-
  The 3D Harness — drives the 3d-master-modeler skill through EVERY phase with
  a gated run-card, so assets come out cinema/AAA quality instead of
  first-render flat. Each phase must leave its proof artifact before the next
  unlocks; the Phase-5 verification loop runs a driven iteration count with
  numeric scoring; the deliverable-verifier agent is the finish line. Use for
  any non-trivial 3D asset, scene, or animation request — "model X", "build a
  3D scene", "game asset", "cinematic render" — whenever quality matters more
  than a quick draft.
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# 3D Harness

`3d-master-modeler` holds the knowledge (1,170 lines, phases 0–5, verified
templates). This harness holds the **discipline**: it walks the phases in
order and makes silent skipping impossible. Built per
`docs/3D-MASTER-MODELER-EXECUTION-PLAN.md` — the skill is a staged pipeline,
never a menu.

## When to use
- Any non-trivial 3D asset/scene/animation where the output must look
  professional (cinema, AAA, portfolio, client-facing).

## When NOT to use
- A quick throwaway blockout or a one-line tweak to an existing scene → use
  the skill directly.
- Pure 2D/UI visual work → `harness-visual`.

## The pipeline

0. **Boot.** Confirm deps (`python3 -c "import bpy"` — setup.sh auto-installs
   on cloud). Copy `skills/3d-master-modeler/runcard.md` into the working
   directory. From here on, **the card is the state machine**: a phase is
   complete when its row holds a proof artifact; the next phase is illegal
   while the previous row is blank.
1. **Phases 0–4 (build).** Execute each phase of the skill in order — intake
   & routing, blockout, topology & mesh audit, procedural PBR, photo-real
   image textures (3b), lighting/camera with environment lighting. Fill each
   run-card row AS the phase completes with the named artifact (render file,
   audit printout, texture list, HDRI used). `N/A` requires a stated reason;
   3b and environment lighting are the #1 flat-output causes, so their N/A
   needs a real brief-based reason, never schedule pressure.
2. **Phase 5 (driven verification loop).** Minimum 2 iterations, harness-set,
   not agent-chosen. Each iteration: render hero/side/top → Read the images
   with your own eyes against the Phase-5 checklist → if a reference exists,
   score with `python3 skills/harness-visual/tool/imgdiff.py` → correct the
   worst finding → record the iteration + findings + score in the run-card.
   Two failed corrections of the same kind = switch method class (ledger
   F-52…F-55 name the known Blender 5.x traps — read them before "fixing").
3. **Delivery.** Export per the skill's verified format table (Draco glTF /
   Meshopt / USD as the target demands), record files + sizes + one-line
   rationale in the card.
4. **Finish line.** Dispatch the `deliverable-verifier` agent: it opens the
   actual exports and renders, cross-checks every run-card row's proof, and
   returns PASS/FAIL. FAIL loops back to the named gap. The deliverable ships
   with the completed run-card; the `runcard-guard` Stop hook refuses to end
   the session otherwise.

## Hard rules
- The run-card is filled phase-by-phase, never retroactively at the end.
- Scores and iteration counts are reported verbatim in the handover.
- Skill knowledge questions (API names, sockets, bake settings) are answered
  from the skill's templates and the ledgers — never re-derived by trial and
  error (two-strike rule).
