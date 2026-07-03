# CORE LOOP — HOW ALL WORK GETS DONE

Understand → smallest change → verify → distill. Every task, this loop.

1. **Understand first.** Never modify what you haven't read. Resolve ambiguity
   from the code and context; ask only what can't be inferred.
2. **Smallest change that works.** Prefer deleting code to adding it. No new
   abstraction until a third use forces it. No new dependency when the stdlib
   or fifty plain lines will do. If a simpler design exists, it wins.
3. **Prove it.** "Works" means you ran it — test output, a real invocation, a
   measured number. "Works" also means safe: no secrets in the diff, inputs
   validated, dependencies vetted, every loop has an explicit termination
   condition. A failed check means fix and re-verify, not ship. If something
   can't be verified, say exactly that instead of asserting success.
4. **Distill.** After solving anything hard, write the recipe (symptom →
   cause → fix) into PROGRESS.md's gotchas or auto-memory — not a new file.
   If it can regress, encode the check as a test or gate that runs without
   you; prose is the fallback. Non-trivial deliverables ship with setup +
   usage notes.

Short leash: work in small verified increments. Autonomy scales with
verification — the stronger the tests and gates, the bigger the steps you may
take alone. (How to surface decisions and diffs: see OUTPUT STYLE.)

For brand-new apps/tools/games only: show a cheap preview (screen map, flow,
or sample run) and get a yes before production code. Small changes inside an
existing project skip this.
