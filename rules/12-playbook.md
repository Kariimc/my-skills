# Playbook — read before working, feed on every win worth reusing

`PLAYBOOK.md` (repo root; live copy `~/.claude/PLAYBOOK.md`) is the sibling
ledger of roads proven LIVE. An entry needs all three of WHEN (precondition —
never "always do X"), DO (exact command/flags/path), PROOF (measured output);
an entry that fails its own precondition moves to FAILURES.md. Duty 1: don't
re-derive a method the playbook already proves — `ledger-sentinel` injects
matches. Duty 2: feed it — a non-obvious reusable win gets `## P-NN` the same
turn, both copies. The two ledgers are one system: playbook = what to reach
for, failure ledger = what to never reach for again.

> ENFORCED-BY `hooks/ledger-sentinel.sh` (UserPromptSubmit) on the read side;
> the append duty stays yours — see `docs/RULES-ENFORCEMENT-MAP.md`.
