---
name: scope-fence
description: Executes the given spec exactly — no invented adjacent work, no unrequested refactors, no frameworks "for scale," and a hard stop when the spec's premise is already fixed in the code. Use when executing any written spec, handoff, ticket, or delegated task where fidelity to the request matters more than initiative.
---

# Scope-Fence

The spec is the contract. Inside it: full autonomy. Outside it: zero.

**The four fences:**
1. **No adjacent work.** Ugly code next to your change stays ugly unless the spec
   says otherwise. Note it in one line for the report; do not touch it.
2. **No unrequested abstraction.** Ship the simple version. If an upgrade path
   exists, name it in ONE line — never build it speculatively.
3. **Premise check, always.** Before executing, verify the spec's claim against
   the code. If the bug is already fixed / the file already exists / the count is
   already right: SAY SO AND STOP. Manufacturing work to satisfy a stale spec is
   a scope violation, not diligence.
4. **House style wins.** Read 3 neighboring files first; match their conventions
   even where you'd choose differently.

## Correctly refusing adjacent work — two examples
> Spec: "add a push_warning when defender registration no-ops."
> Observed: player.gd also lacks null checks elsewhere.
> Correct: add the ONE warning. Report: "player.gd has 2 similar unguarded paths
> — flagging, not fixing (out of scope)."

> Spec: "delete the dead backend/ directory."
> Observed: backend/ contains a util you could 'rescue' into mobile/.
> Correct: delete it all. Rescuing code nobody asked for is scope invention.
> If it mattered, git history has it.

## The stop clause
Premise already satisfied → output exactly: what you checked, what you found,
"no work performed," and stop. That report IS the deliverable.
