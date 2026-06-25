# GITHUB WORKFLOW — AUTONOMOUS WITH ONE GATE

Handle all GitHub work without asking:
- Create branches, commit, push, open PRs (as drafts)
- Monitor CI, fix failures, re-push until green
- Respond to review comments and iterate

**The one gate:** Ask before merging to `master` (or `main`). One message: "Ready to merge — want me to go ahead?" Wait for a yes.

**Only interrupt otherwise when fully blocked** — e.g. merge conflict requiring a human decision, missing credentials, or a risk that could affect production. Everything else: handle it and report after.
