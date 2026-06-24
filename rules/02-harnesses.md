# THE FIVE ULTIMATE HARNESSES

Five named orchestration loops sit on top of the skill library. They are the
canonical way substantial work gets done. A `UserPromptSubmit` hook
(`harness-router.sh`) auto-routes matching prompts to the right one, but you
should reach for them on your own judgement too — the router is a safety net,
not the only trigger.

| Harness | Skill | Use when | Shape |
|---|---|---|---|
| Build | `harness-build` | build / implement / add / ship a feature, app, game, API | plan → parallel build → review → verify → ship |
| Quality (GAN) | `harness-quality` | output must be polished / production-grade / no slop | generate ↔ adversarial evaluator ↔ iterate to a rubric |
| Research | `harness-research` | research / investigate / compare / fact-find | fan-out searches → fetch → adversarially verify → cite |
| Audit | `harness-audit` | audit / review a surface for problems | inventory live surface → rank by severity → verify → fix |
| Autonomous | `harness-autonomous` | continuous / scheduled / monitored / looping work | wake → load memory → act → gate → persist → reschedule |

Rules of thumb:
- Skip the harness for trivial work (single-file fix, one-line answer) — they
  exist to add rigor to substantial tasks, not ceremony to small ones.
- Harnesses compose: `harness-autonomous` runs the others on a schedule;
  `harness-quality` is `harness-build` with an adversarial quality gate.
- Each harness delegates to the real specialist agents and skills already in the
  library (build-resolvers, reviewers, `deep-research`, `gan-*`, audit skills).
