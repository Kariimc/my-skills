---
name: harness-visual
description: >-
  The Visual Harness — generate → preview → MEASURE → iterate for anything
  visual: UIs, 3D renders, graphics, mockups. Every round publishes a clickable
  preview and, when a reference exists, scores the output with a numeric image
  diff; the loop exits on a measured threshold, never on "looks fine". Use when
  the user wants visual work matched to a reference or held to cinema/production
  quality — "match this image", "make it look like X", "AAA quality render",
  "pixel-faithful", or any visual deliverable where eyeballing has failed before.
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# Visual Harness

The missing exit gate for visual work: quality is a **number**, not a mood.
Built from the reference-match ritual that fixed the SHIFT-9 crop bug, and from
the ledger's visual failure cluster (wrong native dimensions, flat first
renders shipped as final).

## When to use
- Matching a reference image/screenshot ("make it look like this").
- Cinema/AAA/production-quality renders or UI where slop is unacceptable.
- Any visual deliverable that previously came back "close but wrong".

## When NOT to use
- Non-visual work → `harness-build` / `harness-quality`.
- Full 3D asset pipeline end to end → `harness-3d` (it embeds this loop as its
  verification phase).

## The loop

1. **Intake — dimensions before anything.** If a reference exists, inspect its
   NATIVE dimensions first (`python3 -c "from PIL import Image; print(Image.open('ref.png').size)"`)
   and set the render/viewport to match. A preview that *looked* 1366 wide was
   actually 1408 — that one wrong number caused every downstream crop error.
   Write the target: dimensions, threshold (default RMSE ≤ 12), max rounds
   (default 5).
2. **Generate.** Build the render/UI/graphic (via `3d-master-modeler`,
   `visual-prototype`, or direct code as fits the medium).
3. **Preview — every round, not just the last.** Publish a clickable preview
   (`visual-prototype` overlay or an Artifact) so Kariim can pin comments.
   Never ask for blind approval.
4. **Measure.** With a reference: `python3 skills/harness-visual/tool/imgdiff.py candidate.png ref.png --threshold 12`
   — it checks dimensions first, then per-channel RMSE, and prints PASS/FAIL.
   Without a reference: Read the output image with your own eyes against the
   brief's checklist (composition, lighting, materials, text legibility) and
   record concrete findings — "pass" requires naming what was checked.
5. **Iterate.** Each FAIL names the largest-error region; correct THAT, re-run
   steps 2–4. Two failed rounds on the same method class = switch method
   (two-strike rule), not a third tweak.
6. **Exit gate.** Loop ends only on: measured PASS, or max rounds reached with
   the best score reported honestly as "did not converge — best RMSE N".
   Then dispatch the `deliverable-verifier` agent on the final artifacts
   (hero/side/top renders or the live page — the real deliverable, not a
   flattering angle). Its PASS is the finish line.

## Hard rules
- No round without a preview; no exit without a measurement; no "done" without
  the verifier's PASS.
- Scores are reported verbatim — a near-miss is a near-miss, never rounded up
  to done.
