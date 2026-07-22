# Loop: skill-gardener (monthly)

**Outcome:** the skills library stays under the trigger-collision ceiling —
overlaps surfaced, dead skills flagged, tier assignments (always-load vs
on-demand) current, finder index honest — before misfires get annoying
(audit finding 4.1: 419 always-on description lines and growing).
**Trigger:** monthly, manual or scheduled Claude Code session with this prompt.
**Scope:** `Kariimc/my-skills` only — `skills/`, `always-load.txt`, the finder
index, `skills/OVERLAP-REPORT.md`. **Report-and-confirm, never auto-delete:**
every removal or tier move is a confirm-each-change list for Kariim
(config-gc contract); the ONLY auto-fixes allowed are README/count drift
(`bin/skill-doctor.sh --fix`) and regenerating the overlap report.
**Act (per cycle):** run `bin/skill-doctor.sh` (frontmatter health, counts);
re-run the overlap scan and diff against the last OVERLAP-REPORT.md; list
skills with zero invocations since the last cycle (from what evidence exists —
name the scope, per rules/10); propose tier moves for rarely-fired always-load
skills; verify `find-skills.py` still ranks each NEW skill top-3 for its own
trigger phrase (P-12).
**Verify:** every proposed deletion/move cites its evidence (collision pair,
zero-hit proof + scope, or superseding skill); auto-fixed counts show the
proving command output in the commit message.
**Stop:** success = report at loops/queue/done/gardener-<date>.md + confirm
list delivered + auto-fixes committed · clean no-op = "library healthy, N
skills, 0 new overlaps" · blocked = doctor HARD failure → fix that first, it
outranks gardening.
**Escalate:** any trigger collision causing real misfires this cycle lands in
my-skills PROGRESS.md gotchas; a structural fix (tier split change) is
PROPOSED to Kariim, never self-applied.
