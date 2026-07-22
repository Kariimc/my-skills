# Rule Enforcement & Process Streamlining Plan

> Written 2026-07-22. Companion to `docs/HARNESS-AGENT-ROADMAP.md`. Grounded in
> the same recon: FAILURES.md, PLAYBOOK.md, PROGRESS.md, HANDOFF.md,
> MY-SKILLS-AUDIT.md, the apex gate suite, and the live rule set in `rules/`.

---

## Part 1 — The sharpened prompt

The original ask: *"We have agents that blatantly don't follow the rules and we
want to streamline all our processes while maintaining extremely high quality
outputs and deliverables."* The context-rich version, reusable anywhere:

> **Context: `Kariimc/my-skills` is the control plane for every Claude surface
> Kariim uses. The rule set is large (a multi-part global CLAUDE.md: standing
> contract, IDP operating law, execution-first mode, Fable-parity discipline,
> plain-language rules, plus 419 skill trigger lines) and violations still
> recur — the failure ledger itself records agents breaking rules that were
> already written down (F-48: walls of text after being told in writing not to;
> F-49: a banned shell method reused twice after it was already in the ledger;
> F-40: writing directly to a generated file; F-47: serialising waits instead of
> taking an offered approval). Meanwhile the apex commit gates — the one place
> where rules are MACHINERY instead of prose — have a near-perfect record.**
>
> **Task: design the smallest system that makes rule-following structural
> instead of willpower-based, and simultaneously REDUCES total process. For
> every existing rule, decide: can it be enforced by a gate or hook (machine
> checks it, agent cannot skip it), verified by a subagent (an evaluator scores
> the output before it ships), or must it stay prose (pure judgment calls)?
> Propose the concrete hooks/gates/agents to build, what prose gets deleted or
> shrunk as a result, and the single standard pipeline every task should flow
> through. Constraints: quality bar cannot drop (proof-backed deliverables,
> previews for visual work, zero legwork on Kariim); process must shrink, not
> grow (no new ritual without deleting an old one); every proposal cites the
> violation class it eliminates; and each mistake class gets ratcheted so it can
> only ever happen once — the apex pattern, extended from commits to behavior.**

---

## Part 2 — Diagnosis: why agents break rules that are written down

1. **Prose decays; gates don't.** The rules say "full force turn 1 through 100 —
   never decays," but that is an instruction to a model whose attention *does*
   decay over long context. Evidence: violations cluster late in long sessions
   (F-48, F-49). The apex gates never decay because a shell script has no
   attention span. The lesson is already proven in-repo: **every rule that stays
   prose-only will eventually be violated; every rule that became machinery
   stopped being violated.**
2. **The rulebook is big enough to conflict with itself.** Standing contract,
   operating law, execution-first mode, proportionality override, plus 419
   trigger lines — agents resolve tensions silently and pick the convenient
   reading. A rule an agent must *interpret* is a rule an agent can *dodge*.
3. **Enforcement is post-hoc and human.** Today the compliance checker is
   Kariim noticing a violation and flagging it — which is exactly the legwork
   the rules ban. There is no automatic check between "agent finishes" and
   "Kariim reads."
4. **Subagents start cold.** Harness workers get a task prompt, not the
   contract. A dispatched worker never saw "zero legwork" or "proof, not
   reassurance" unless the dispatching prompt happened to restate it.
5. **"The model is poisoned / blatantly lies" — what's actually happening.**
   No model is poisoned; what looks like lying is a model asserting a confident
   guess when it should say "unverified" — and the likelihood of that goes UP
   with long contexts, big rulebooks, and pressure to sound done. It affects
   *every* model tier (Opus included), which is exactly why the fix cannot be
   "use a better model" or "write the rule again, louder." The fix is
   model-agnostic machinery: no claim reaches Kariim without the verify station
   having checked the real artifact, regardless of which model produced it.
   Design assumption going forward: **any model, on any day, can drop any
   prose rule — so no prose rule may be load-bearing for quality.**
6. **Freelancing: agents substitute their own plan for the prompt.** The most
   time-expensive violation in practice: the agent treats the prompt as a
   suggestion, silently "improves" on it, makes executive decisions it was
   never given, and Kariim pays the correction cost afterward. Root cause:
   models are trained to reward initiative, and ambiguity gets resolved in the
   agent's favor invisibly — the deviation is only discovered at handover.
   Rule 16 (fidelity) and the `scope-fence` skill already say this in prose;
   prose demonstrably doesn't hold. The fix is a **spec-fidelity gate**:
   - At plan time (Major work): the agent must echo the literal ask and list
     any intended deviation as its own line — an unflagged deviation is an
     automatic fail, before any work happens.
   - At handover: the evaluator's FIRST scored axis is fidelity — "everything
     asked for present? anything present that was NOT asked for?" A deliverable
     that does extra, different, or 'better' things than the ask is rejected
     the same as an incomplete one. Initiative is only legal as a flagged
     question BEFORE building, never as a silent substitution.

## Part 3 — The fix: an enforcement pyramid (machinery first, prose last)

**Tier 1 — Gates (cannot proceed; already proven by apex).** Keep and extend.
The ratchet gets a new lane: *behavioral* mistakes also become checks, not just
repo-state mistakes.

**Tier 2 — Hooks (automatic, every turn, no memory required).** The big build:

- **`handover-check` (Stop hook) — the compliance moment that's missing.**
  Before a reply reaches Kariim, scan the draft for the violation signatures:
  numbered manual steps / "you should run…" (legwork), "done/fixed/works"
  with no pasted evidence nearby (proof rule), file paths & jargon in the
  chat reply (plain-language rule), visual deliverable with no preview link
  (preview rule). Flag → agent fixes in the same turn, silently, per the
  violation protocol. *Eliminates: F-48 class, proxy-"done" claims, legwork.*
- **`ledger-sentinel` (UserPromptSubmit/PreToolUse hook)** — inject matching
  FAILURES/PLAYBOOK entries into context at plan time; a banned road that is
  *in front of* the agent cannot be "forgotten." *(Roadmap item #4.)*
  *Eliminates: F-49 class.*
- **Router hardening (UserPromptSubmit)** — the proportionality table already
  exists as prose; encode it so the hook states the task class and the exact
  ritual set that applies. Over-process and under-process both drop.

**Tier 3 — Verifier subagents (quality floor while streamlining).**

- **Contract preamble for every dispatched worker:** a short standard block
  (zero legwork, proof not reassurance, scope fence, plain output) prepended by
  the harnesses to every subagent prompt. One file, reused everywhere.
- **Evaluator gate:** no harness accepts a worker's output until
  `agent-evaluator` (already in `agents/`) scores it against the rubric —
  and the `deliverable-verifier` (roadmap #1) confirms the real artifact.
  This is what lets processes get *simpler* without quality dropping: the
  check moves from "many rituals during the work" to "one hard gate at the end."

**Tier 4 — Prose (smallest possible).** Run a `rules-distill` + `config-gc`
pass over the global rule set: every rule gets tagged either
`ENFORCED-BY: <gate/hook/agent>` or `JUDGMENT` (genuinely un-automatable).
Enforced rules shrink to one line each — the machinery is the rule. Judgment
rules stay, but the total prose an agent must hold drops sharply. **Rule of
exchange: no new ritual ships without deleting or automating an old one.**

## Part 4 — The one pipeline (streamlined, quality-locked)

Every non-trivial task flows through the same five stations — no per-task
process invention:

```
intake (router classifies)
  → plan (plan-gate/wargame — Major only; sentinel injects ledger hits)
  → build (harness or direct loop; workers carry the contract preamble)
  → verify (deliverable-verifier + evaluator — the ONE hard quality gate)
  → scribe (handoff/relay/counts reconciled automatically — roadmap #5)
```

Trivial tasks skip straight from intake to done. Everything Kariim receives has
passed `verify`; everything a future session needs has been written by `scribe`;
nothing depends on an agent remembering a rule mid-task.

## Part 5 — Build order (merged with the roadmap)

| # | Item | Kills | Effort |
|---|---|---|---|
| 1 | `handover-check` Stop hook | legwork, proofless "done", jargon replies, missing previews | small — one hook + signature list |
| 2 | `ledger-sentinel` hook | repeating banned roads (F-49 class) | small — index + inject |
| 3 | Contract preamble + evaluator gate in the 6 harnesses (fidelity is the first scored axis; deviation echo required at plan time) | cold subagents, unscored output, freelancing / silent executive decisions | small — one shared block + one gate step |
| 4 | `deliverable-verifier` agent | proxy verification (hard rule #3 class) | medium — roadmap #1 |
| 5 | Rules-distill pass: tag every rule ENFORCED-BY/JUDGMENT, shrink prose | rulebook bloat, silent conflict-dodging | medium, one session |
| 6 | Behavioral ratchet lane in apex | any future violation recurring | small — extend existing ratchet |
| 7 | `scribe` agent/loop | continuity drift | medium — roadmap #5 |

Each of 1–3 is a single-session build reusing existing pieces. After #5, the
prose rulebook should be roughly half its current size while enforcement is
strictly stronger — that is the streamlining, and the verify station is why
quality cannot regress while it happens.
