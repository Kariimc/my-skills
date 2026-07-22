# Run-card — copy this table into the working directory and fill it AS YOU GO

Every phase of SKILL.md must leave a row here with a named proof artifact.
A row may read `N/A — <stated reason>` (an explicit decision). A row may
NEVER be blank: **a blank row means the run is not done**, regardless of how
the final render looks to you. The deliverable is the asset + renders + this
completed card.

| Phase | Proof required | Artifact / value | Status |
|---|---|---|---|
| 0 — Intake & routing | One-line decision: framework, poly budget, deliverable format(s) | | ☐ |
| 1 — Blockout | Blockout render file (dimensionally checked against reference/native dimensions) | | ☐ |
| 2 — Topology & refinement | Mesh-audit printout: object + tri counts, non-manifold result | | ☐ |
| 3 — PBR materials | Material list + which Principled sockets were set per material | | ☐ |
| 3b — Photo-real textures | Texture sources + resolutions actually applied (or N/A + reason, e.g. stylized target) | | ☐ |
| 4 — Lighting & camera | Environment/HDRI used + lighting test render | | ☐ |
| 5 — Verification loop | Iteration count (≥2) + per-pass findings/score; final hero/side/top renders read with your own eyes | | ☐ |
| Delivery | Export file(s) + sizes + one-line format rationale | | ☐ |

Rules of the card:

1. Fill each row **when the phase completes**, not retroactively at the end —
   retro-filling defeats the audit and always misremembers.
2. Phase 5 is a loop, not a checkbox: record what each pass found and what was
   corrected. "First render was fine" is statistically false; if you believe
   it, the verification pass is where you prove it.
3. Skipping 3b or environment lighting is the #1 cause of flat, sub-cinema
   output. `N/A` on those rows needs a real reason (e.g. NPR/stylized brief),
   not schedule pressure.
4. Hand the completed card over with the deliverable. An incomplete card
   handed over as "done" is a rule violation, not a shortcut.
