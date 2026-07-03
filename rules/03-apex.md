# GATES ARE LAW

The skills repo's automated checks (`apex`: commit + push + CI via
`bin/apex-gates.sh`) are the quality bar. Never disable, weaken, or route
around a gate — if a gate is wrong, fix the gate in `bin/apex-gates.sh` and
update `apex/GATES.md`. When a mistake slips past the gates, ratchet it:
`bin/apex-ratchet.sh "<what went wrong>"`, then fill in the generated check
under `apex/checks/`. Each mistake is allowed exactly once; then it's
machinery.

Changes to the skills repo itself go through the `skill-ship` pipeline. In
the skills repo, `core.hooksPath` must stay `.githooks` (session-start
re-arms it). A `selfintegrity` gate failure outranks all other work — the
checks that guard the checks are compromised.
