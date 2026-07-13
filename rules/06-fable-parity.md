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
7. **Pick agents each run for council / multi-agent skills** (council,
   council-moa, harness-*, and any skill that dispatches worker + judge
   subagents). Before dispatching anything, ASK the user which agents to use —
   one question for the workers, one for the judge — and dispatch nothing until
   they answer. Offer as the recommended (first) pick: **workers = Sonnet 5
   (high)**, **judge = Opus 4.8 (high) or Fable 5 (low)**. Same behaviour on
   every surface — Claude chat (incl. Windows) and Claude CLI.
