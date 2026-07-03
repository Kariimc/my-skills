---
name: windows-env-repair
description: >
  Repair a broken Windows dev environment — OneDrive-redirected user folders,
  lost/relocated project paths, broken git links, and out-of-sync global config.
  Use when files moved into OneDrive, a project's git remote or working dir
  broke, or the machine drifted from its source-of-truth config repo.
---

STATUS: candidate -- pending Riimos sign-off

# windows-env-repair

Scaffolded by sync-sessions: this task recurred across 3+ sessions
(OneDrive folder repair, HoopClone path/git recovery, global Claude config
setup). Draft only — flesh out and sign off before deploying.

## Likely steps (from the source sessions)
1. Diagnose what moved: check whether user-shell folders point into
   `...\OneDrive\...` instead of `%USERPROFILE%`.
2. Back up every registry key before touching it (e.g. `C:\OneDriveFixBackup`).
3. Move files back with `robocopy /MOVE` (copies + verifies before removing
   source) — never plain delete.
4. Rewrite User Shell Folder registry redirects back to `%USERPROFILE%\<Folder>`.
5. Re-establish git around the *real* working copy (the one actually open), not
   the stale remote.
6. For config drift, reinstall from the source-of-truth repo (`C:\Dev\my-skills`)
   and run its verification checks.
7. Leave deletion of leftover OneDrive folders as a manual step if any is the
   live working directory.

See brain wiki: windows-onedrive-folder-repair, windows-claude-config-setup,
hoopclone-project.
