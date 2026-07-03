# Output contracts — the model-downgrade hardening convention

**Why.** Most skills here were written assuming a frontier model fills the gaps
(interpret intent, invent structure, self-verify). That assumption dies the day
you run them on a mid-tier model. A skill survives model downgrade when it is
*mechanical*: explicit numbered steps, at least one worked example, and a tight
**output contract** — the exact shape the skill must return, so a weaker
executor can be checked instead of trusted.

**The convention (for every substantive skill):**
1. **Numbered steps**, each with a concrete action — no "analyze appropriately".
2. **One worked example** — a real minimal input→output pair, not a placeholder.
3. **`## Output contract`** — the literal report shape, with hard rules for
   failure ("if gate X fails, report `BLOCKED at X: <evidence>` and stop").

**Exemplars already in the library** (copy their style):
- `skills/tdd-workflow/SKILL.md` — hard RED/GREEN gates + the Step-8 evidence
  report with a required markdown table schema.
- `skills/git-workflow/SKILL.md` — exact commands, decision tables, good/bad
  examples.
- The four harnesses now carry contracts: `harness-build` (SHIPPED/CHANGED/
  GATES/VERIFY/RISKS block), `harness-audit` (ranked evidence-cited findings
  table + VERIFIED/USER-GATED footer), `harness-quality` (rubric table +
  per-round verdict line), `harness-research` (ANSWER/SOURCES/CONFIDENCE/
  UNVERIFIED/MISSING).

**Testing a skill against a weaker model:** run `skills/skill-comply` with
`--gen-model haiku` and commit the report; a skill that fails compliance on
haiku needs more steps/examples/contract, not more prose.

**Ratchet direction:** when touching any heavily-used skill, add its contract
in the same change. New skills should not merge without one (see
`adr/0002-evals-in-ci.md` for where enforcement lives).
