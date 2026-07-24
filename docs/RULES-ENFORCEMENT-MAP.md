# Rules → Enforcement Map

> Implements the "rules-distill" item of `RULE-ENFORCEMENT-STREAMLINE-PLAN.md`
> conservatively: every operating rule is tagged with WHAT ENFORCES IT —
> a gate/hook (machine, cannot be skipped), a verifier agent (scored before
> shipping), or JUDGMENT (prose only, genuinely un-automatable). Deliberate
> deviation from the plan, flagged: the prose rulebook itself is NOT shrunk
> here — deleting Kariim's negotiated rule text needs his eyes on each cut.
> This map is the prerequisite: it shows exactly which rules are now safe to
> shrink to one line because machinery carries them.
>
> A rule tagged with machinery is a rule an agent can no longer silently
> break. A rule tagged JUDGMENT is where model quality still matters.

| Rule | Enforced by | Class |
|---|---|---|
| Zero legwork on Kariim (contract #3, law #4) | `hooks/loose-ends-guard.sh` (Stop) | HOOK |
| Plain words, no jargon walls (01-plain-talk) | `hooks/plain-words-guard.sh` (Stop) | HOOK |
| Done = 100%, no parked TODOs (law #15) | `hooks/guard-fabrication.sh` + `detect-fabrication.sh` (Stop + CI) | HOOK+GATE |
| Continuity docs updated, never on request (law #18) | `hooks/guard-handoff.sh` (Stop); `scribe` agent does the writing | HOOK+AGENT |
| No destructive commands without a yes (contract #6) | `hooks/guard-destructive.sh` (PreToolUse) | HOOK |
| No junk/backup/versioned files (law #7) | `hooks/guard-junk-files.sh` (PreToolUse) | HOOK |
| Skills/connectors before "can't" (09-consult-skills) | `hooks/cant-guard.sh` (Stop) — helpless reply without a library/connector search is blocked; env-scout prints the capability inventory each session | HOOK |
| Never repeat a banned road (11-failure-ledger) | `hooks/ledger-sentinel.sh` (UserPromptSubmit) — matching F/P entries injected at plan time | HOOK |
| Staged skill = every phase, never a menu (3D) | `hooks/runcard-guard.sh` (Stop) + `skills/3d-master-modeler/runcard.md` | HOOK |
| Harness routing / proportionality | `hooks/harness-router.sh` (UserPromptSubmit) | HOOK |
| Repo/commit hygiene, counts, secrets, gate integrity | apex suite (`bin/apex-gates.sh`, pre-commit/pre-push/CI) | GATE |
| Every mistake gated once (03-apex ratchet) | `bin/apex-ratchet.sh` → `apex/checks/` — behavioral lane included (see GATES.md) | GATE |
| Verify the actual deliverable, not a proxy (hard rule #3) | `deliverable-verifier` agent — finish line of every harness | AGENT |
| Fidelity: build exactly the ask, flag deviations first (law #16) | `agent-evaluator` fidelity-first axis + `skills/AGENT-CONTRACT.md` in all 6 harnesses | AGENT |
| Proof, not reassurance (contract #5) | `deliverable-verifier` + evaluator evidence axis; fabrication guard for code | AGENT+HOOK |
| Never assert an absence without coverage (10-repo-topology) | JUDGMENT — worker contract restates it; scribe names scope in docs | JUDGMENT |
| Recon before questions (contract #1) | JUDGMENT | JUDGMENT |
| Two-strike method cap (law #17) | JUDGMENT — sentinel surfaces the ledger; the cap itself is a call | JUDGMENT |
| Ask before merging to master (05-github-workflow) | JUDGMENT + branch protection via CI gate on master | JUDGMENT+GATE |
| Preview anything visual (boot rule #4) | JUDGMENT today — `harness-visual` makes it structural inside the harness; a preview-check hook is the natural next ratchet | JUDGMENT→HOOK |
| Interview before building / clarity gate (Major) | JUDGMENT | JUDGMENT |

**Reading this table:** the next distill pass shrinks every HOOK/GATE-tagged
rule's prose to one line + a pointer here (machinery is the rule), and leaves
JUDGMENT rows as full prose. That pass touches Kariim's rule text, so it ships
as its own reviewed change, not silently.
