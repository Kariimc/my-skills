`cp -r` is additive-only: anything deleted or renamed in the repo persists in
~/.claude/ forever — on every machine — and, for skills, keeps auto-triggering.
The repo silently stops being the source of truth at the first deletion.

Blast radius: all three copied categories (skills/commands/agents), every
machine, unbounded time; worst case is a removed-for-cause skill still firing
globally. The rules path is immune because rebuild-from-zero has correct
delete semantics — which is also the fix pattern.

Fix: mirror semantics for the other three (`rsync -a --delete`, or
delete-dir-then-copy), with the tradeoff stated: mirror erases anything that
exists only locally, so the first sync per machine should print its removals.

Verify: add a throwaway skill → sync → present; delete it from the repo →
sync → it must be gone from ~/.claude/skills/.
