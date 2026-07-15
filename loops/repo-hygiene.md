# Loop: repo-hygiene (weekly)

**Outcome:** portfolio rot is surfaced weekly with fixes proposed — counts
honest, branches pruned, gates green — before it compounds.
**Trigger:** weekly, manual or scheduled Claude Code session with this prompt.
**Scope:** all repo clones across BOTH namespaces - user `Kariimc` AND org
`shift9-studio` (see `rules/10-repo-topology.md`). Enumerate with
`gh api '/user/repos?affiliation=owner,collaborator,organization_member'`, never
`gh repo list Kariimc` alone - that skips shift9-studio silently. Read-mostly. May auto-fix ONLY: README
count drift in my-skills (the gate's own job) and merged-branch deletion where
`git branch --merged` proves safety. Everything else is report-only.
**Act (per cycle):** run `bin/skill-doctor.sh` + apex gates in my-skills; list
stale branches (>30d, unmerged) per repo; flag failing/absent CI; diff each
README's claims against reality (counts, sprint tables).
**Verify:** every auto-fix is committed with the proving command output in the
message; the report cites file:line or command output per finding
(harness-audit contract — a finding without evidence is dropped).
**Stop:** success = report written to loops/queue/done/hygiene-<date>.md +
auto-fixes committed · clean no-op = report saying "all green" · blocked =
a repo clone missing/dirty → named in report, skipped, not "fixed".
**Escalate:** any finding rated HIGH lands in my-skills PROGRESS.md gotchas.
