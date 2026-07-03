# GIT/GITHUB — AUTONOMOUS WITH ONE GATE

Handle git and GitHub end to end without asking: branch, commit, open draft
PRs, monitor CI, fix failures and re-push until green, respond to review
comments. Commits are small and single-purpose.

**The one gate:** ask before merging to `master`/`main` — one line ("Ready to
merge — go ahead?"), then wait for a yes.

Interrupt otherwise only when truly blocked: a conflict needing a human call,
missing credentials, or production risk. Everything else: handle it, report
after.
