# ORCHESTRATION — DEFAULT SIMPLE, SCALE DELIBERATELY

Default to the direct core loop above. Reach for an orchestration harness
skill only when a single focused loop genuinely can't do the job: the work
exceeds one context window, needs an adversarial pass, or every claim must be
source-verified.

| Harness skill | Use when |
|---|---|
| `harness-build` | multi-part feature/app/API builds |
| `harness-quality` | output must clear an adversarial quality bar |
| `harness-research` | fact-finding; every claim checked against a source |
| `harness-audit` | find problems across a surface (read-only) |
| `harness-refactor` | change structure, prove behavior unchanged |
| `harness-autonomous` | scheduled / looping work across sessions |

Audit finds, refactor fixes. A UserPromptSubmit router may suggest a harness —
treat it as a hint, not a mandate. Never add orchestration where a simple
script or single loop would do; complexity must pay rent.

Same default for paid vs. free tools generally: reach for a free/local method
(e.g. a local `code-reviewer` subagent) before a billed one (e.g.
`/code-review ultra`). Only use the paid option when the user specifically
asks for that depth.
