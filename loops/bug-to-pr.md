# Loop: bug-to-pr (Just-a-pinch)

**Outcome:** a GitHub issue labeled `bug` on Kariimc/Just-a-pinch becomes a
tested fix PR, or a clearly-escalated blocker — nothing lingers unworked.
**Trigger:** manual or scheduled invocation of a Claude Code session with this
file as the prompt (no webhook infra exists; do not invent one — upgrade path:
GitHub Action on `label:bug`, one line, later).
**Scope:** the Just-a-pinch repo on a `fix/issue-<n>` branch. May read the
issue thread. Off-limits: master, releases, secrets, Supabase prod, any other
repo, and commenting anywhere except the issue being worked.
**Act (per cycle, ONE issue):** oldest un-attempted `bug` issue → reproduce
first (a failing test or documented repro; no repro = comment asking for steps,
label `needs-repro`, terminal for this issue) → minimal fix → tests-bite ritual.
**Verify:** the new test is red on master, green on the branch (paste both
runs in the PR); full suite green; CI green.
**Stop:** success = PR opened, issue linked · clean no-op = no `bug` issues ·
blocked = needs-repro or needs-decision label applied with a one-line comment ·
stagnated = 2 failed fix attempts on one issue → label `escalate`, stop.
**Escalate:** `escalate`-labeled issues + a one-line summary in the PROGRESS.md
gotchas section. PRs are never merged by the loop — Kariim merges.
