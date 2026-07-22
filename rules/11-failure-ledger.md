# Failure Ledger — read before working, feed on every failure

`FAILURES.md` (repo root; live copy `~/.claude/FAILURES.md`) is the canonical
ledger of roads PROVEN dead (SYMPTOM → BANNED ROAD → THE ROAD THAT WORKS).
Duty 1: never repeat a banned road — `ledger-sentinel` injects matching
entries at prompt time, and a surfaced entry is binding, not advisory.
Duty 2: feed it — an approach that fails twice or burns 15+ minutes gets a new
`## F-NN` entry as part of the fix, both copies in the same pass, never
deferred. The entry IS part of the fix.

> ENFORCED-BY `hooks/ledger-sentinel.sh` (UserPromptSubmit) on the read side;
> the append duty stays yours — see `docs/RULES-ENFORCEMENT-MAP.md`.
