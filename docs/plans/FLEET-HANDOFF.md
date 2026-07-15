# FLEET HANDOFF — Sonnet 5 Workers · Opus 4.8 Manager
> Status note, 2026-07-14: historical July 6 plan/audit. Current live state is 419 skills and 67 agents on origin/master; old 416/68 or 411/67 counts below are preserved as historical evidence, not current truth.
> **Mission:** execute the entire Fable-window plan (the 50-item list) plus the 10-task repo remediation, at Fable-5 output quality — enforced by harness, not hoped for.
> **Author:** Claude Fable 5 · 2026-07-06 · **Owner:** Kariim
> **Companion file (REQUIRED in workspace):** `CLAUDE-CODE-HANDOFF.md` — full specs for repo Tasks 1–10. This file orchestrates; that file details.

---

# PART 0 — FLEET CONFIGURATION

| Role | Model | String | Why |
|---|---|---|---|
| **Manager / Judge** | Claude Opus 4.8 | `claude-opus-4-8` | Dispatch, adversarial review, merge gatekeeping, escalation. Higher-accuracy model judges; cheaper model executes. |
| **Workers (N=2–4)** | Claude Sonnet 5 | `claude-sonnet-5` | Most agentic Sonnet; near-Opus agentic coding at $2/$10 intro pricing (thru Aug 31). Finishes multi-step tasks and self-checks output. |

**Sonnet 5 operating facts every agent config must respect (verified from launch docs, 2026-06-30):**
- **Adaptive thinking is ON by default.** Manual `budget_tokens` thinking returns a 400. Use the `effort` parameter: `high` for build tasks, default for chores.
- **Do NOT set `temperature` / `top_p` / `top_k`** — non-default values return a 400. Steer with prompts only.
- **New tokenizer ≈ +30% tokens for the same text.** Revisit any `max_tokens` sized for Sonnet 4.6; budget-per-task estimates below already account for it.
- **1M context default; 128k max output.** Whole-repo loading is fine — don't build chunking pipelines.
- **Cyber safeguards ON by default** — security-adjacent requests can return `stop_reason: "refusal"` as a *successful* HTTP 200. Workers must detect this and escalate to Manager, never retry-loop a refusal. (This is why list-item #50 routes around Sonnet — see the Disposition Ledger.)
- Prefill is a 400; use structured outputs / system-prompt instructions.

**Workspace prerequisites (Manager verifies before Wave 1):**
- Fresh clones of all repos across BOTH namespaces - user `Kariimc` AND org `shift9-studio` - one directory each. Enumerate with `gh api '/user/repos?affiliation=owner,collaborator,organization_member'`; `gh repo list Kariimc` silently omits shift9-studio. See `rules/10-repo-topology.md`.
- `my-skills` synced (`bash install-global.sh` already run on the host) — the six harnesses, apex gates, and `bin/eval-router.sh` are the quality infrastructure this fleet reuses. **Do not invent new process where a harness exists.**
- Both handoff files present. `PROGRESS.md` convention live (my-skills `rules/07-progress-file.md`).

---

# PART 1 — TOPOLOGY & PROTOCOL

## 1.1 Structure
```
                    ┌─────────────────────────┐
                    │  MANAGER (Opus 4.8)      │
                    │  dispatch · judge ·      │
                    │  merge-gate · escalate   │
                    └────┬───────┬───────┬─────┘
                         │       │       │
                   Worker A   Worker B   Worker C     (Sonnet 5, Claude Code)
                   lane:      lane:      lane:
                   repo #1    repo #2    my-skills
```

## 1.2 Lane rule (hard)
**One repo = one worker at a time.** No two agents ever hold the same repo. The Manager owns lane assignment. Cross-repo tasks (e.g. LFS on two repos) run sequentially inside one lane or as two lanes touching different repos.

## 1.3 Dispatch protocol (Manager → Worker)
Every dispatch is a single message containing: (1) the task ID from this file, (2) the full spec section pasted inline (never "see the doc" — workers get zero ambiguity), (3) the Universal Quality Contract (Part 2, pasted verbatim), (4) the branch name, (5) the token/time budget. Worker acknowledges by restating the Done bar in one line, then executes.

## 1.4 Return protocol (Worker → Manager)
Worker returns exactly: branch pushed · Done-bar evidence (command output, test results — **artifacts, not claims**) · assumptions logged · any refusal/blocker verbatim. Nothing merges on a worker's say-so.

## 1.5 Judging protocol (Manager) — the Fable-parity mechanism
The Manager runs the **GAN loop from `harness-quality`** on every returned task:
1. **Verify the Done bar mechanically.** Run the stated commands yourself. A claim without reproduced output = automatic REJECT.
2. **Adversarial pass.** Actively try to break it: revert the guard a test covers (test must go red), replay the webhook, feed the edge case. For the three GATED-quality checks: *tests-bite*, *no-scope-invention*, *no-placeholder-assets*.
3. **Verdict:** `ACCEPT` (merge PR) · `REVISE` (return with the specific failure — max 2 revise cycles, then escalate) · `ESCALATE` (to Kariim, with the one-line decision needed).
4. **Ledger every verdict** in `FLEET-LOG.md` at workspace root: task, worker, cycles, verdict, tokens.

## 1.6 Escalation triggers (Manager → Kariim, immediately, never buried)
- Any 🛑 gate in the specs (there are exactly 3 — Part 4 ledger).
- Any `stop_reason: "refusal"` from a worker (cyber safeguards) — Manager either takes the task itself (Opus 4.8) or hands it to Kariim; never asks the worker to rephrase around a safety refusal.
- A task that fails 2 revise cycles.
- Any discovery that contradicts these specs (specs were written 2026-07-06 against repo HEAD; code wins over doc).

---

# PART 2 — UNIVERSAL QUALITY CONTRACT (paste into every worker dispatch, verbatim)

> You are a Sonnet 5 worker executing a spec authored by Fable 5. Fable-level quality is achieved by obeying this contract, not by improvising brilliance.
>
> 1. **PLAN-GATE.** Before any edit: write a 5-line plan — goal, unknowns, success criteria, step order, rollback. If an unknown is a fact only the code holds, read the code first. If it's a fact only Kariim holds, STOP and return the question.
> 2. **SCOPE-FENCE.** Execute the spec exactly. Do not invent adjacent work, do not refactor what you weren't asked to touch, do not add frameworks "for scale." If the spec's premise is already fixed in the code, say so and stop — don't manufacture the work.
> 3. **TESTS MUST BITE.** Every test you write must fail when the guard it covers is reverted. Prove it once (revert → red → restore → green) and include that output in your return.
> 4. **REAL ASSETS, REAL OUTPUT.** Never placeholders, never stubbed "TODO" paths in shipped code, never claimed-but-not-run commands. Every claim in your return is backed by pasted command output.
> 5. **HOUSE STYLE.** Match the repo's existing conventions (read 3 neighboring files first). Conventional commits. One PR per task. CI green before you return.
> 6. **HANDOFF.** Update the repo's `PROGRESS.md` (my-skills format: where-we-are / done / user-gated / gotchas). Your session must be resumable by a stranger.
> 7. **HONESTY.** A blocker reported early is a success; a bluffed completion is the only failure. If you hit a safety refusal, return it verbatim — do not rephrase around it.

---

# PART 3 — EXECUTION WAVES

## WAVE 0 — Unblock (Manager + Kariim, ~30 min, before any worker starts)
- **W0.1** ✅ ANSWERED 2026-07-06: **Mirror (A)** — repo is source of truth; deleted there = deleted everywhere. Task 4 is unblocked; the hook must still print removals on first sync.
- **W0.2** ✅ ANSWERED 2026-07-06: **Deep clean, preview-gated** — run `git lfs migrate import` prep, show Kariim the before/after size table, wait for one-word "go" before force-push.
- **W0.3** Manager verifies workspace prerequisites (Part 0) and opens `FLEET-LOG.md`.

## WAVE 1 — Repo remediation (3 parallel lanes; specs live in `CLAUDE-CODE-HANDOFF.md`, dispatch them inline per §1.3)
| Lane | Worker tasks (in order) | Est. effort |
|---|---|---|
| **A — Just-a-pinch** | Task 1 (money/data tests: credit-race, dual-write, webhooks) → Task 2 (prune backend, move refs) | Largest; effort=high |
| **B — small wins** | Task 3 (Faceless-Tech CI) → Task 7 (Midnight-return README+tests+CI) → Task 10 (Omni-3d/Sub-Scraper, conditional — check activity first, SKIP if parked) | Medium |
| **C — control plane & game** | Task 5 (README count gate) → Task 4 (sync fix, after W0.1 answer) → Task 6 (Hoopclone bugs + main.gd split + smoke test) → Task 9 additive LFS (gated purge only after W0.2) | Medium-high |

Lane C runs my-skills tasks **first** so every later worker session benefits from the fixed sync. Manager judges each task per §1.5 before the lane advances.

## WAVE 2 — Distillation, loops, evals (the durable-leverage tier; my full specs below — these do NOT live in the companion file)

### W2.1 — Skill distillation pack (`my-skills`, one worker)   [list items #9, #10, #12, #13]
Create four skills, house-format (`skills/<name>/SKILL.md`, frontmatter `name:` = folder, description ends in a sharp "Use when…" trigger):
- **`plan-gate`** — encodes Contract rule 1 as a standalone always-appropriate skill: no edits before a written plan (goal, unknowns, success criteria, step order, rollback). Body includes 2 worked examples (one code task, one docs task) and the failure smell it prevents (mid-task scope drift).
- **`scope-fence`** — Contract rule 2 as a skill: executes specs without invention; includes the "premise already fixed → stop" clause and 2 examples of correctly refusing adjacent work.
- **`tests-bite`** — Contract rule 3: the revert-prove-restore ritual, with a template snippet for pytest and jest.
- **`session-reflect`** — end-of-session 3-phase review: extract durable facts → corrections → workflows; writes candidates to `PROGRESS.md` §gotchas and proposes (never auto-commits) rule additions to `rules/`.
Then run **`/skill-audit`** and update `OVERLAP-REPORT.md` if the new skills collide with existing triggers (they will — `strategic-compact` and the harness skills are adjacent; resolve by narrowing the new descriptions, not deleting incumbents).
**Done bar:** 4 skills pass skill-doctor; counts auto-update via the Task-5 gate; overlap report regenerated; one Sonnet 5 session with the skills loaded demonstrably plan-gates before an edit (paste the transcript excerpt).

### W2.2 — Harness scaffolding refresh (`my-skills`, same worker, after W2.1)   [items #11, #14]
Review the six harness skills (`harness-build`, `-quality`, `-research`, `-audit`, `-autonomous`, `-refactor`) against this fleet's actual protocol. Apply **surgical** upgrades only: add the Return-protocol artifact rule (§1.4) and refusal-escalation rule (§1.6) where the harness dispatches subagents. Add a standing rule to `rules/` codifying model routing: *Sonnet 5 default for execution ≤ Opus-judged; Opus 4.8 for judging, security-adjacent, and >10-step autonomous; Fable-class when available for architecture/audit artifacts.* (This is item #15's routing playbook, landed as a rule instead of a doc — it's then enforced everywhere automatically.)
**Done bar:** diffs are minimal and reviewed by Manager against "surgical" (any wholesale rewrite = REVISE); rules sync into `~/.claude/CLAUDE.md` cleanly.

### W2.3 — Verification & eval harness (items #18, #26, #27)
- Extend `bin/eval-router.sh`'s pattern into `bin/eval-models.sh`: run a fixed task set (use `datasets/harness-routing` + 5 real tasks sampled from Wave 1 PRs) against `claude-sonnet-5` and `claude-opus-4-8`, score with the Manager as grader, emit a one-page comparison. **Purpose:** every future model release gets evaluated against Kariim's real work in an afternoon (the permanent asset). Exclude any run that returned a safeguard refusal from scoring — label it ROUTED instead.
- **Done bar:** `bash bin/eval-models.sh` produces the comparison table from a clean checkout; results committed under `datasets/`.

### W2.4 — Loops (items #16, #17, #22, #25) — DESIGN ONLY this wave
Author `loops/` in my-skills: three loop specs in the trigger→act→verify→stop format (use the loop-library conventions if present): **(a)** overnight-brief loop — end-of-day task file → autonomous run → morning PROGRESS report; **(b)** bug-to-PR loop for Just-a-pinch (issue label → reproduce → fix → PR); **(c)** weekly repo-hygiene loop (stale branches, dep bumps, count gates). Wire **(a)** to the existing-but-never-fired XAVIER scheduled task: fix the trigger, run `morning-briefing.ps1` once manually, verify the 08:00 fire next morning (this closes PROGRESS.md item 22).
**Done bar:** 3 loop specs merged; XAVIER has fired at least once on schedule with evidence.

## WAVE 3 — Conditional & product (only after Waves 1–2 accepted)
- **W3.1** (item #39) Landing page for **Just a Pinch** — one static page, real app screenshots from the repo's `docs/`, deployed to the existing `deploy-pages.yml` target. No new framework.
- **W3.2** (items #32/#33) One deep-research report: competitor scan for Just a Pinch's recipe-organizer niche (Manager-executed on Opus — research quality is judge-tier work).
- **W3.3** (items #44/#45) Personal-systems bootstrap — ONLY items Kariim names; do not speculatively build household tooling.

---

# PART 4 — THE 50-ITEM DISPOSITION LEDGER (every item accounted for — "exactly as specified" includes the SKIPs)

| # | Item | Disposition |
|---|---|---|
| 1 | Architecture audit, main repo | ✅ **DONE** (Fable, this session: `MY-SKILLS-AUDIT.md`) |
| 2 | Master roadmap doc | ✅ DONE-IN-PARTS (audits §roadmaps) + W2.2 routing rule |
| 3 | Migration plans | ✅ DONE (LFS + sync plans in audits) → executed Wave 1 |
| 4 | Tech-debt report | ✅ DONE (`PORTFOLIO-AUDIT.md` §0 table) |
| 5 | Performance audit | ✅ FOLDED into per-repo audits (no standalone perf hotspot found worth a doc) |
| 6 | Deep PR review | ✅ SUPERSEDED — no large open PRs existed; audit covered HEAD |
| 7 | Test strategy + suites | 🔨 **EXECUTE** — Wave 1 Task 1 (JaP), Task 6c, Task 7 |
| 8 | Document undocumented systems | 🔨 EXECUTE — Wave 1 Task 7 (Midnight README); others already documented |
| 9 | Skills encoding Fable's rigor | 🔨 EXECUTE — W2.1 (`plan-gate`, `scope-fence`, `tests-bite`) |
| 10 | Fable rewrites existing skills | 🔨 EXECUTE (scoped) — W2.2 surgical harness refresh. Full 416-skill rewrite = REJECTED as scope inflation; the ratchet handles the tail. |
| 11 | Rewrite agent scaffolding | 🔨 EXECUTE — W2.2 |
| 12 | Session-reflection skill | 🔨 EXECUTE — W2.1 (`session-reflect`) |
| 13 | Standing-rule capture | 🔨 EXECUTE — W2.1 (inside `session-reflect`) + W2.2 rule |
| 14 | Prompt/spec templates | ✅ DONE — this file's dispatch format + Quality Contract ARE the templates |
| 15 | Model-routing playbook | 🔨 EXECUTE — W2.2 (landed as a rule, not a doc) |
| 16 | First real loops | 🔨 EXECUTE — W2.4 |
| 17 | Overnight-work pipeline | 🔨 EXECUTE — W2.4(a) + XAVIER fix |
| 18 | Verification harness | 🔨 EXECUTE — W2.3 (+ Manager GAN protocol is the runtime half) |
| 19 | Content-distribution agent | ⏸️ USER-GATED — needs platform accounts/keys only Kariim holds; spec on request |
| 20 | Cross-platform analytics dashboard | ⏸️ USER-GATED — same (which platforms? which metrics?) |
| 21 | Headless publishing (no-API platforms) | ⏭️ SKIP — no Medium/blog pipeline exists in the portfolio; build when one does |
| 22 | Bug-to-PR pipeline | 🔨 EXECUTE — W2.4(b) |
| 23 | Knowledge-base audit/rebuild | ✅ MOSTLY DONE (brain: 16 wiki artifacts, per PROGRESS.md); remainder is the encrypted-remote step = USER-GATED (adr/0003) |
| 24 | Parallel multi-workstream practice | 🔨 EXECUTE — Wave 1 IS this (3 lanes); the habit transfers |
| 25 | Overnight test/benchmark harness | 🔨 EXECUTE — W2.4(a)+W2.3 combined |
| 26 | Side-by-side model evals on real work | 🔨 EXECUTE — W2.3 (Sonnet 5 vs Opus 4.8; Fable window closes tomorrow — Sonnet/Opus comparison is the durable one) |
| 27 | Eval harness as permanent asset | 🔨 EXECUTE — W2.3 |
| 28 | Unknowns-surfacing discipline | 🧍 HUMAN HABIT — encoded in Contract rule 1; the practice is Kariim's |
| 29 | Whole-repo feeding + analysis | ✅ DONE (this session, all 12 repos) |
| 30 | Gnarly overnight refactor | 🔨 EXECUTE — Task 6b (main.gd split) is the instance |
| 31 | Infrastructure-as-code generation | ⏭️ SKIP — no cloud infra in portfolio; homelab = safeguard-refusal territory (see #50) |
| 32 | Deep-research report stack | 🔨 EXECUTE — W3.2 (Opus-executed) |
| 33 | Document-heavy analysis | ⏸️ USER-GATED — no documents queued; on demand |
| 34 | Assessment/scoring system | ⏭️ SKIP — was a community example, no matching need |
| 35 | CRM/internal-tool rebuild | ⏭️ SKIP — no CRM exists |
| 36 | CI/CD for every project | 🔨 EXECUTE — Tasks 3, 7 close the gaps (JaP/Hoopclone/Learning/Omni/Sub already have CI) |
| 37 | Native mobile app in one prompt | ✅ SUPERSEDED — Just a Pinch already exists and ships; energy goes to its tests, not a new app |
| 38 | App from screenshots | ⏭️ SKIP — demo-class |
| 39 | Landing page | 🔨 EXECUTE — W3.1 |
| 40 | Niche SaaS around an annoyance | ⏸️ USER-GATED — idea selection is Kariim's; fleet builds on a one-line pick |
| 41 | App-builder meta-tool | ⏭️ SKIP — demo-class |
| 42 | Game prototypes / systems layer | 🔨 EXECUTE — Task 6 + Sprint-5 plan in `HOOPCLONE-AUDIT.md` §5 (the systems layer, per spec — not throwaway clones) |
| 43 | CAD/engineering | ⏭️ SKIP — not relevant to this portfolio |
| 44 | Personal ops profile/planner | ⏸️ USER-GATED — W3.3, only named items |
| 45 | Email filters / bill tracker | ⏸️ USER-GATED — W3.3 |
| 46 | Wall dashboard | ⏸️ USER-GATED — W3.3 |
| 47 | One-shot game clones | ⏭️ **SKIP — flagged low-value in the source plan. Do not build.** |
| 48 | Novelty one-shots | ⏭️ **SKIP — same.** |
| 49 | Route-everything-through-flagship | ⏭️ SKIP (anti-pattern) — the W2.2 routing rule is its replacement |
| 50 | Security/homelab tooling | ⚠️ **ROUTE, don't build via workers** — Sonnet 5 ships cyber safeguards ON by default; expect `refusal` stop-reasons on hardening/firewall/VLAN tasks. Protocol §1.6: worker returns the refusal verbatim → Manager (Opus) takes it or hands to Kariim. Never prompt-around a refusal. |

**Tally: 12 done/superseded · 20 execute · 9 user-gated · 8 skip · 1 route.** Every item has a disposition; nothing is silently dropped.

---

# PART 5 — HUMAN LEDGER (everything only Kariim can do, complete)
1. ~~W0.1~~ ✅ Answered: Mirror.
2. **W0.2 residual** — one-word "go" after seeing the LFS size preview (the only step left in this gate).
3. ~~Task 8~~ ❌ DROPPED by owner decision 2026-07-06: Bball stays exactly as-is. Do not banner it, do not archive it, do not touch it.
4. Pick or defer the USER-GATED items: #19, #20, #33, #40, #44–46, and the brain encrypted-remote (#23).
5. Advisor interview (~15 min) — pre-existing PROGRESS.md item; unrelated to fleet but still open.
6. Budget note: Sonnet 5 intro pricing ends **Aug 31**; Waves 1–2 comfortably fit before then. Fable window ends **Jul 7** — nothing in this fleet requires Fable; it was consumed producing the specs.

---

# PART 6 — KICKOFF (paste-ready)

**Manager boot prompt (Opus 4.8, Claude Code, workspace root):**
```
You are the Fleet Manager (Opus 4.8). Load FLEET-HANDOFF.md and CLAUDE-CODE-HANDOFF.md
from this directory. Execute Part 3 starting at Wave 0. You dispatch Sonnet 5 workers
per §1.3 (spec inline + Quality Contract verbatim), judge per §1.5 with mechanical
verification and an adversarial pass, and escalate per §1.6. Open FLEET-LOG.md now.
The two Wave-0 human answers are: MIRROR and PURGE-AFTER-PREVIEW. Task 8 (Bball) is dropped by owner decision — skip it entirely.
Begin.
```

**Worker dispatch template (Manager fills brackets):**
```
You are a Sonnet 5 worker. Task [ID]: [full spec pasted inline].
Branch: [name]. Budget: [tokens/time].
[UNIVERSAL QUALITY CONTRACT — Part 2, verbatim]
Restate the Done bar in one line, then execute.
```
