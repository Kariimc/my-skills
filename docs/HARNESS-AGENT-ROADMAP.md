# Harness & Agent Roadmap

> Written 2026-07-22 from a full recon of this repo: FAILURES.md (58 entries),
> PLAYBOOK.md (20 entries), PROGRESS.md, HANDOFF.md, MY-SKILLS-AUDIT.md, the 6
> existing harness skills, the 68 agents, and the 3 loops. Every suggestion below
> cites the evidence that makes it worth building. Nothing here is generic advice.

---

## Part 1 — The sharpened prompt

The original ask was: *"Give me suggestions for harnesses and agents we should
build that would help everything we do."* Here is the context-rich version — use
it (or hand it to any agent) whenever this question comes up again:

> **You are working inside `Kariimc/my-skills`, the control-plane repo for all of
> Kariim's Claude surfaces (Claude Code local, Claude Code cloud, Cowork, chat).
> It already contains 424 skills, 68 agents, 6 orchestration harnesses
> (build, quality/GAN, research, audit, refactor, autonomous), 3 loops
> (bug-to-pr, overnight-brief, repo-hygiene), the apex gate suite, and a
> SessionStart sync that mirrors everything to `~/.claude/` on every machine.**
>
> **Before suggesting anything, read: FAILURES.md (banned roads — each entry is a
> failure class that already cost real time), PLAYBOOK.md (proven methods),
> PROGRESS.md and HANDOFF.md (live state), and MY-SKILLS-AUDIT.md (known
> structural weaknesses). The operating rules that matter most: verify the actual
> deliverable, never a proxy; never assert an absence without proving coverage;
> zero legwork lands on Kariim; visual work always ships with a clickable
> preview; the cloud box is wiped between sessions; every mistake gets ratcheted
> into a gate so it can only happen once.**
>
> **Task: propose new harnesses (multi-agent orchestration skills) and agents
> (subagent definitions in `agents/`) that would raise the floor across ALL work
> — not one project. For each proposal: (1) name it, (2) say exactly what it
> does end to end, (3) cite the specific failure-ledger entries, audit findings,
> or repeated manual rituals it eliminates, (4) name the existing skills/agents
> it reuses so nothing is rebuilt, (5) give the smallest first version worth
> shipping. Rank by how much recurring pain each removes, not by how impressive
> it sounds. Cap the list at ~8; mark the top 3 as "build first." Do not propose
> anything that duplicates an existing harness, skill, or gate — check first.**

---

## Part 2 — The roadmap (ranked, evidence-cited)

### BUILD FIRST

#### 1. `deliverable-verifier` agent — proof of delivery
- **What:** A read-mostly agent whose only job is to verify the *actual thing the
  user receives* before any "done" claim: open the exported file, run the built
  artifact, screenshot the live page with the session browser, run the numeric
  image diff against the reference. Returns PASS/FAIL + the evidence artifact.
  Wired as the final gate of every harness (build, quality, refactor, visual).
- **Why (evidence):** Hard rule #3 in the global CLAUDE.md exists because this
  failure recurred "across many sessions" — verifying a flattering proxy instead
  of the deliverable. F-46 (editing a generated file and calling it done), F-50
  (claiming a diagnosis without checking the writer), and the SHIFT-9 session's
  crop bug (wrong source dimensions shipped repeatedly) are all this one class.
- **Reuses:** `verification-before-completion` skill, `screen-eyes`, the
  reference-match ritual in PROGRESS.md (numeric image diff), Playwright/Chromium.
- **Smallest version:** one agent file + a checklist per artifact type (export /
  web page / render / script), each ending in a pasted command output or diff
  number. No new infra.

#### 2. `env-scout` agent + boot probe — the environment fact sheet
- **What:** One agent (or a plain script the SessionStart hook backgrounds) that
  fingerprints the box in ~30s: which interpreters and modules exist (attempt the
  import, don't guess), which hosts the proxy allows (the multi-host curl probe),
  which connectors/surfaces are live, disk allowance left. Writes the result as a
  dated "environment facts" block into PROGRESS.md and the relay so the *next*
  surface reads it cold.
- **Why (evidence):** An entire cluster of ledger entries is "wrong belief about
  the box": F-43 (absence asserted from a scope that couldn't cover it), F-45
  (egress is a GitHub+package allowlist, not "no downloads"), the bpy
  reinstall-without-proof incident (PROGRESS Phase 2 rule 1), and the approved
  2026-07-22 rules about proving dependency absence and recording environment
  facts the same session. This automates the proof so no agent starts cold again.
- **Reuses:** P-14/P-16 probes, the existing SessionStart hook chain, `relay`.
- **Smallest version:** a bash script in `bin/` + a hook line; the agent wrapper
  comes later if the script's output needs interpretation.

#### 3. `harness-visual` — the missing 7th harness
- **What:** Generate → render/preview → *machine-verify* → iterate, for anything
  visual: UIs, 3D renders, graphics. The generator builds; the evaluator does
  not just eyeball — it runs the pixel/numeric diff against the reference, checks
  native source dimensions first, and publishes a clickable pin-and-comment
  preview every round. Terminates on a measured threshold, not on vibes.
- **Why (evidence):** "Most of Kariim's work is visual" is written into the
  standing rules, and the visual failure entries are the densest cluster in the
  ledger (F-44 sky texture, F-46 compositor, F-52 UV islands, F-53 black metal
  bake, plus the crop/alignment errors from wrong dimensions). The existing
  quality/GAN harness scores rubrics; nothing today *measures pixels*.
- **Reuses:** `visual-prototype` (preview overlay), `gan-generator`/`gan-evaluator`,
  `screen-eyes`, the reference-match ritual, `hifi-design-quality`, `dataviz`.
- **Smallest version:** a harness SKILL.md that sequences existing pieces and
  adds one new script: `imgdiff` (already proven in the SHIFT-9 session) as the
  loop's exit gate.

### BUILD NEXT

#### 4. `ledger-sentinel` agent — the ledgers enforce themselves
- **What:** Fires at plan time (plan-gate / wargame moment): greps FAILURES.md
  and PLAYBOOK.md against the planned approach, surfaces any banned road or
  proven method that matches, and blocks silently repeating a dead road. Also
  owns the append duty: when a session hits the two-strike rule, it drafts the
  `F-NN` / `P-NN` entry so feeding the ledger stops depending on discipline.
- **Why (evidence):** F-49 is literally "banned shell method used again, twice,
  after it is already in this ledger." A ledger that relies on being remembered
  has already failed once; apex proved the fix is machinery, not memory.
- **Reuses:** `wargame`, `plan-gate`, the apex ratchet pattern.
- **Smallest version:** a keyword-index file generated from the ledger headers +
  a UserPromptSubmit/PreToolUse hook that injects matching entries into context.

#### 5. `scribe` agent — continuity that can't drift
- **What:** A session-end agent that reconciles every continuity surface from
  *actual state*: regenerates README counts from `ls | wc -l`, refreshes
  HANDOFF.md's verified-facts table, updates PROGRESS.md, pushes the relay line.
  Run also on a weekly schedule as a loop so drift never accumulates.
- **Why (evidence):** Audit finding #2 — count drift (411 vs 416) *in the repo
  whose flagship feature is fixing count drift* — plus HANDOFF.md's stale
  last-commit line, plus the standing rule that handoff upkeep is "a standing
  duty, never on request." Humans and ad-hoc agents demonstrably skip it.
- **Reuses:** `project-context-loader`, `session-reflect`, `relay`, apex checks
  (this is the natural ratchet check #2 the audit asked for).
- **Smallest version:** extend `bin/apex-gates.sh` to substitute real counts into
  README at commit time (drift becomes impossible), then add the agent for the
  prose surfaces.

#### 6. `harness-3d` — codify the Blender pipeline
- **What:** A dedicated 3D asset harness: procedural generate → headless render →
  vision check → bake → LOD chain → glTF/KTX2 export, with a `blender-reviewer`
  agent that carries the Blender 5.x landmine list (slotted actions, compositor
  rework, headless rigidbody, bake gotchas) so no session rediscovers them.
- **Why (evidence):** Eight playbook entries (P-13 through P-20) and six failure
  entries are Blender-specific — the single largest domain in both ledgers. The
  methods exist; they live as prose an agent must remember to read.
- **Reuses:** `3d-master-modeler` + its setup.sh auto-install, P-13..P-20,
  the asset fetchers (P-18), the new `harness-visual` exit gate.
- **Smallest version:** one SKILL.md sequencing the playbook entries + the
  reviewer agent file distilled from F-44/F-46/F-52..55.

### WORTH HAVING

#### 7. `skill-gardener` loop — stay under the collision ceiling
- **What:** A scheduled loop (monthly) that re-runs the overlap report, proposes
  tier moves (always-load vs on-demand), flags dead skills, and reconciles the
  finder index — outputting a confirm-each-change list, never auto-deleting.
- **Why (evidence):** Audit 4.1: 424 always-on description lines are "approaching
  the trigger-collision ceiling"; OVERLAP-REPORT.md already documents collisions.
  The tiered always-load.txt split exists but nothing maintains it.
- **Reuses:** `skill-audit`, `config-gc`, `context-budget`, `skill-ship`.

#### 8. `surface-router` rule/agent — right tool, right box
- **What:** At task intake, checks which surface actually holds the needed
  channel (laptop-only actions vs cloud-capable vs vision-in-only) using the
  env-scout fact sheet, and either does the work here or writes a precise relay
  inbox message — never a prompt for Kariim to ferry.
- **Why (evidence):** F-45 (the *other* F-45: writing prompts for another surface
  while holding working tools) and the screen-eyes "vision-IN only" fact that had
  to be learned the hard way. Cross-surface misrouting is a named, repeated cost.
- **Reuses:** `relay`, env-scout (#2), the PROGRESS environment-facts block.

---

## What NOT to build (checked, already covered)

- A generic code-review harness — `harness-quality`, `code-reviewer`, and the
  language reviewer bench (20+ agents) already cover it.
- A research harness — `harness-research` / `deep-research` exist.
- A PR babysitter — cloud sessions already have PR activity subscriptions plus
  the `bug-to-pr` loop; extend those before adding anything.
- More language reviewers/build-resolvers — the bench is the *strongest* part of
  the agent roster; the gaps are all in verification, continuity, and visual work.

## Suggested order

1. `deliverable-verifier` (top failure class, cheapest to ship)
2. `env-scout` (kills the wrong-belief-about-the-box cluster)
3. `harness-visual` (highest-volume work domain, measured exit gate)
4. `ledger-sentinel` → 5. `scribe` → 6. `harness-3d` → 7. `skill-gardener` → 8. `surface-router`
