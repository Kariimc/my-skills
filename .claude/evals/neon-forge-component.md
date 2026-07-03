# EVAL: neon-forge-component

Acceptance rubric for **one new Neon Forge UI component** — a demo + registry
entry + copyable snippet added to the bespoke dark-mode React workbench at
`C:/Dev/neon-forge-ui` (React 19 + TanStack Start, Tailwind v4, `motion/react`,
deployed as a Cloudflare Worker on Higgsfield).

- **Type:** product / quality eval — a GAN-style scored rubric (weighted 1-10
  dimensions), because component quality is a taste-and-correctness judgment that
  unit tests alone cannot capture. Model-graded, with hard code-graded gates that
  can veto any score.
- **System under test:** the `neon-forge-ui` skill's 4-file add flow (demo in
  `demos2.tsx`, entry in `components-registry-v2.ts` → `NEW_COMPONENTS`,
  registration in `component-card.tsx`, then verify).
- **Ground truth read to build this:** `skills/neon-forge-ui/SKILL.md` (the 8
  design rules, SSR-safety, the quality gate, the 4-file flow) and
  `C:/Dev/brain/wiki/neon-forge-ui-project.md` (stack, the `vite dev` 500 gotcha,
  wrangler-only local preview, deploy semantics).

---

## Hard gates (code-graded — any failure caps the total at 0; do not score)

These are non-negotiable correctness gates. If **any** fails, the component is a
**REJECT** regardless of how good it looks — record the gate that failed and stop.

- **G1 — typecheck:** `cd app && bun run typecheck` passes (no TS errors).
- **G2 — build:** `cd app && bun run build` passes; both client and SSR Worker
  bundles emit.
- **G3 — renders live:** served via the **wrangler** path (never `vite dev`,
  which 500s on this stack), the demo renders at `http://localhost:8787` with a
  real HTTP 200 and the demo is visible.
  ```bash
  cd app && bun run build && bun x wrangler dev --port 8787 --local   # press b
  ```
- **G4 — unique slug, registered:** the slug is kebab-case and **grep-confirmed
  absent** from both registry files before adding, then added to `NEW_COMPONENTS`
  in `components-registry-v2.ts`, and the demo is wired into the `LiveDemo`
  `demos` record in `component-card.tsx`.
  ```bash
  grep -hoE 'slug: "[^"]+"' app/src/lib/components-registry.ts app/src/lib/components-registry-v2.ts | sort | uniq -d   # must be empty
  ```
- **G5 — no regression:** total component count is exactly `prior + 1`; every
  pre-existing slug still renders (the grid shows all prior components). No
  existing demo/slug broke.

Only if **G1–G5 all pass** do you score the seven dimensions below.

---

## Scored dimensions (each 1-10)

Score against the live component, then feed failures back to the generator.
Instructed like a GAN evaluator: **refute, don't praise** — dock points for
generic output and for any of the 8 design rules being merely "technically not
broken."

### S1 — Dark-only palette discipline (weight 1.5)
Page `#050608`, surface `#0B0D12`; no light mode anywhere. No white/near-white
fills sneaking in. **10** = reads as native to the dark workbench; **≤4** = any
light-mode assumption or off-palette background.

### S2 — Single accent via prop, no rainbow (weight 1.5)
Uses the `accent: string` prop for its color; **never hardcodes** `#4D7CFF` /
`#39D353` (or any fixed hue) in the demo. One accent max — **no AI
purple/rainbow/multi-stop gradients**. **10** = fully accent-driven, restrained;
**1** = hardcoded color or a rainbow gradient (this is the single most common
slop tell — score it harshly).

### S3 — Motion correctness (`motion/react`, physics not state) (weight 2.0)
Continuous/animated values use `useMotionValue` + `useSpring` (or transforms),
**never `useState` for a continuous value**. All physics via `motion/react` —
**never** `framer-motion`, `gsap`, or `three.js`. No duplicate `style` props
(MotionValues + CSS merged into ONE `style` object; not cast
`as React.CSSProperties` when it holds MotionValues). **10** = idiomatic spring
physics, one style object; **≤3** = `useState` drives a continuous value, wrong
motion lib, or duplicate style props. Highest weight — motion is the library's
whole point.

### S4 — Distinctiveness (no generic components) (weight 2.0)
The component is visually distinctive and demonstrates a **concrete, specific
interaction** — not a generic button/card that any starter kit ships. Apply the
two-second test: if a stranger would glance and say "an AI made this," it fails.
**10** = a memorable, specific interaction; **≤4** = generic, could be from any
component library. Highest weight — distinctiveness is the stated bar.

### S5 — Copyable snippet is real, standalone, runnable (weight 1.5)
The registry `snippet` is **standalone, real, working TSX** a user can paste and
run: it includes its own minimal imports (from `motion/react`, not
`framer-motion`), is not pseudocode, and matches what the live demo actually
does. **10** = paste-and-run correct with minimal imports; **≤4** = pseudocode,
missing imports, wrong import source, or drifts from the demo.

### S6 — SSR-safety + cleanup (weight 1.5)
No `window` / `document` / `localStorage` / `navigator` touched at module top
level or during render — only inside effects/handlers, or guarded with
`typeof window !== "undefined"`. All intervals / timeouts / rAF / listeners are
cleaned up on unmount. **10** = provably SSR-safe and leak-free; **≤3** = any
unguarded browser global at module/render scope (would break the Worker SSR
build) or a missing cleanup.

### S7 — Reduced-motion safety (weight 1.5)
The interaction respects `prefers-reduced-motion`: heavy/looping/auto-playing
motion is stilled or damped for users who opt out (via `useReducedMotion` from
`motion/react` — already an available import per the vendored `motion/react`
API — or a `prefers-reduced-motion` guard), without breaking the component's
function. **10** = motion gracefully reduced, component still works; **≤4** =
unconditional looping/large motion with no opt-out. (Purely
hover/pointer-triggered, non-looping effects may score up to 7 without an
explicit guard, since they aren't autoplaying vestibular triggers — but any
continuous/auto motion with no guard is capped at 4.)

---

## Scoring math & thresholds

- **Weights** sum to **11.5**. Weighted score = Σ(dimension × weight).
- **Normalized score (0–10)** = weighted total ÷ 11.5. Report this number.

Thresholds (consistent with the repo's GAN harness default of 7.0):

| Band | Normalized | Action |
|---|---|---|
| **Ship** | ≥ **8.0** | Accept — deliver the component. |
| **Revise** | **6.0 – 7.99** | **Below threshold — iterate.** Feed the lowest-scoring dimensions back to the generator and regenerate. |
| **Reject** | < 6.0, **or** any hard gate G1–G5 failed, **or** any single dimension ≤ 3 | Do not ship. Rework from the failing dimension. |

**Revise threshold = 8.0.** A component must clear 8.0 normalized *and* pass all
hard gates to ship. Note the two floor rules that override the average: (a) a
failed hard gate is an automatic reject even at a high average, and (b) any
single scored dimension at **≤ 3** is an automatic reject — a fatal flaw in one
dimension (e.g. a hardcoded rainbow gradient, or `useState` driving continuous
motion) cannot be averaged away by strong scores elsewhere.

**Loop:** max **3** generate→evaluate iterations (mirrors the skill's VRD loop).
If it can't clear 8.0 after 3, stop and surface the specific blocking dimensions
for human review rather than looping forever.

---

## How to run

No committed runner yet (see `README.md` for the CI-wiring plan). To evaluate one
candidate:

1. **Build the candidate** via the skill's 4-file flow, then run the hard gates:
   ```bash
   cd C:/Dev/neon-forge-ui/app
   bun run typecheck && bun run build            # G1, G2
   grep -hoE 'slug: "[^"]+"' src/lib/components-registry.ts src/lib/components-registry-v2.ts \
     | sort | uniq -d                            # G4: must print nothing
   bun x wrangler dev --port 8787 --local        # G3/G5: open :8787, confirm 200 + all components render
   ```
2. If any gate fails → **REJECT**, record which gate, stop.
3. If all gates pass → score S1–S7 against the **live** component at
   `http://localhost:8787` (a model grader / `gan-evaluator` subagent instructed
   to refute, reading this rubric). Compute the normalized score.
4. Apply the threshold table. On **Revise**, hand the lowest dimensions back to
   the generator and repeat (≤ 3 iterations).

Log each iteration's per-dimension scores and the normalized total to
`neon-forge-component.log` beside this file (append-only), per the
`.claude/evals/<feature>.log` convention.
