# Rules

Markdown files here are concatenated (sorted by filename) into your **global**
`~/.claude/CLAUDE.md` on every session start. That file is loaded as
instructions in **every** project you open — so these are your always-on rules.

The set is deliberately Karpathy-shaped: one core loop (understand → smallest
change → verify → distill), a short leash with diff-level transparency, and
orchestration only where a simple loop genuinely can't do the job.

| File | Purpose |
|---|---|
| `00-contract.md` | The Standing Contract: the always-on chat-surface version of the operating law — recon before questions, answer first, zero legwork, decided = authorized, proof not reassurance, two strikes kills the method. Sorts first; the full law below outranks it. |
| `00-core.md` | The core loop: understand first, smallest change, prove it, distill. Short leash; autonomy scales with verification. Preview gate for brand-new builds. |
| `00-idp-operating-law.md` | The full operating law: router, clarity/prototype gates, the 19 numbered rules, violation protocol. |
| `01-plain-talk.md` | Plain everyday language by default; explain every technical term in the same breath. |
| `02-harnesses.md` | Orchestration inverted: default simple; six harness skills only when a task exceeds one context. Complexity must pay rent. |
| `03-apex.md` | Gates are law: never bypass, fix the gate instead; ratchet each escaped mistake into a permanent check. |
| `04-response-mode.md` | Output style: learning mode in my-coding-journey only; everywhere else write like a good commit message — outcome first, show the diff, evidence over vibes. |
| `05-github-workflow.md` | Autonomous git/GitHub; small single-purpose commits; the one gate is merging to master. |
| `06-fable-parity.md` | Execution discipline: plan before edit, spec is the fence, tests must bite, artifacts not claims, reflect on exit, model routing. |
| `07-progress-file.md` | Read/maintain PROGRESS.md as the session handoff in any repo. |
| `08-relay.md` | Read/write the Kariimc/relay cross-surface handoff system every session: global HANDOFF.md state, per-surface inboxes, append-only log. |
| `09-consult-skills.md` | Check the skills library before saying "can't" — search first, then name exactly what is missing. |
| `10-repo-topology.md` | Repos span TWO namespaces (user `Kariimc` + org `shift9-studio`) and are not all public. Never assert an absence, status, or completion without proving scope was exhaustive. |
| `11-failure-ledger.md` | Read `FAILURES.md` before any work; feed it a new entry whenever an approach fails twice or burns 15+ minutes. |
| `12-playbook.md` | Read `PLAYBOOK.md` before any work; feed it a WHEN→DO→PROOF entry when a non-obvious method wins. |
| `13-loop-select.md` | Offer a project loop once at session start (via `loopy`); never block on the offer. |
| `14-surface-router.md` | Do the work where the tools are: check the probed env fact sheet, act on this surface when it holds the channel, relay a complete message when it doesn't. |

Learning-mode teaching rules (explain-like-I'm-five, step-by-step, 🎓 recaps)
live in `C:\Dev\my-coding-journey\CLAUDE.md` — they load only there.

## How to use
- **Add a rule set:** drop a new `NN-name.md` file here. Use a numeric prefix to
  control ordering (e.g. `00-base.md`, `10-style.md`). It goes global on the
  next session, or run `/sync-skills` to apply now.
- **Edit a rule:** change the file and re-sync. The whole `~/.claude/CLAUDE.md`
  is rebuilt from this folder each time, so there are no stale leftovers.

> Keep rules lean. Everything here is prepended to every conversation in every
> project, so it costs context on each turn.
