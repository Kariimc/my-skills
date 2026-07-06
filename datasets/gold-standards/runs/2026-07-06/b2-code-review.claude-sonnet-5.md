Confirmed against the actual hook (`.claude/hooks/session-start.sh:39`):

```
cp -r "$PROJECT_DIR/skills/." "$CLAUDE_DIR/skills/"
```

vs. rules, which do `: > CLAUDE.md` (truncate) then rebuild.

**The issue:** skills/commands/agents sync is additive-only — `cp -r` never deletes files in `~/.claude/skills/` that no longer exist in the repo. Rules get truncated-and-rebuilt every sync, so a deleted rule vanishes immediately. A deleted or renamed skill does not — the stale copy sits in `~/.claude/skills/` forever, silently diverging from the repo (the source of truth).

**Blast radius:** any skill/command/agent you delete or rename in the repo keeps running from the stale global copy on every future session, on every machine that syncs. Concretely: a skill you deprecated because it was wrong, insecure, or superseded keeps firing; a rename leaves two copies (old name still triggers, new name also triggers) with no error to flag it; `git log` and `ls skills/` in the repo say one thing, `~/.claude/skills/` says another, and nothing surfaces the drift until you notice an old behavior firing that "shouldn't exist anymore." Given `my-skills` is the control plane for every project's Claude setup, this is a correctness/security-relevant asymmetry hiding in the one mechanism meant to keep things in sync.

**Fix:** make skills/commands/agents mirror the repo the same way rules do — delete-then-copy, or a real mirror:

```bash
rm -rf "$CLAUDE_DIR/skills"; cp -r "$PROJECT_DIR/skills" "$CLAUDE_DIR/skills"
```

(same for commands/agents), or `rsync -a --delete` if available in the Git Bash environment. Either makes the sync idempotent and gives skills the same "rebuilt from zero" guarantee rules already have.

Want me to apply this to `.claude/hooks/session-start.sh` for skills/commands/agents?
