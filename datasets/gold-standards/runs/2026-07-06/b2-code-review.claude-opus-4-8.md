**Deletions don't propagate for skills/commands/agents.** `cp -r repo/skills/. ~/.claude/skills/` is an overlay: it adds and overwrites, but never removes. A skill you delete or rename in the repo stays live in `~/.claude/skills/` forever. This is the exact asymmetry with rules — rules are rebuilt from zero, so a deleted rule actually disappears; skills/commands/agents leak.

**Blast radius:** every skill, command, and agent ever removed or renamed accumulates as an orphan on every synced machine. Renames are worst — old and new both exist, so colliding triggers fire two skills. For a *control-plane* repo this is a safety hole: a skill you pulled *because it was dangerous or buggy* keeps executing everywhere, and the repo silently stops being the source of truth for what's installed. It also can't self-heal — no sync will ever clean it; only manual `rm` on each machine does.

**Fix:** make the sync a mirror, not an overlay — match what rules already do. Either rebuild the dir from zero (`rm -rf ~/.claude/skills && cp -r`) or, better, `rsync -a --delete repo/skills/ ~/.claude/skills/` (same for commands and agents).

One caveat with `--delete`: it wipes anything in the destination not in the repo. If users keep local-only skills in `~/.claude/skills/`, scope the mirror to a repo-owned subdirectory or add an exclude list — otherwise you trade a leak for data loss.
