# Golden examples — the user's ideal output, curated from real artifacts

Item #8 of the durable-leverage list. Few-shot references that make any model
perform above its weight: each entry is a REAL artifact from this machine
(nothing fabricated), with why it clears the bar. Standards it encodes:
`rules/00-core.md` (evidence over vibes, smallest change),
`rules/04-response-mode.md` (commit-message density),
`brain/wiki/working-preferences.md` (taste).

## 1. Commit message — `b737883` (this repo)
> *Wave B: runnable evals, validated routing dataset, secrets-gate fixes* — body
> lists each artifact with its proof inline: "182/182 (100%)", "grep parsed as
> options (rc=2) … Added -e. Proven: ghp_ token now rc=0 (was rc=2/inert)".

**Why it's good:** every claim carries its evidence in the same line; a reader
can audit it without checking out the diff. Read it: `git show --stat b737883`.

## 2. ADR — `adr/0001-harness-router-regex-vs-classifier.md`
**Why:** decision actually made (not a survey), grounded in file:line, ends
with a revisit trigger — the Agetnic-OS 5-part shape at its tightest.

## 3. Debugging writeup — `C:/Dev/brain/wiki/worked-examples.md` case 1
> "A doubled header, not a wrong header, is the tell."

**Why:** symptom → approach → the one non-obvious insight → subtractive fix.
The insight is quotable and transfers beyond the incident.

## 4. Skill with hard gates — `skills/tdd-workflow/SKILL.md`
**Why:** RED/GREEN gates with validity criteria + a required evidence-report
table. A mid-tier model can execute it mechanically; a reviewer can check it.

## 5. Ratchet check — `apex/checks/no-plaintext-secrets-in-brain.sh`
**Why:** the header explains the exact mistake it prevents; design contract
states why it's tight not broad; redacts its own output; verified against
planted fixtures AND the clean tree before landing.

## 6. Deep-map — `ARCHITECTURE.md` (this repo)
**Why:** live-verified counts ("verified via find, not trusting README"),
invariants as a numbered list, an honest gotchas section. Describes what IS,
not what was intended.

## 7. Eval dataset provenance — `datasets/harness-routing/README.md`
**Why:** records generator, date, method ("labels computed from a verbatim
port, then validated end-to-end through the real hook") — the difference
between a dataset and a pile of JSON.

## 8. Output contract — `skills/harness-build/SKILL.md` §Output contract
**Why:** SHIPPED/CHANGED/GATES/VERIFY/RISKS forces evidence into the report
shape itself; the failure path (`BLOCKED at <gate>`) is specified, so a weaker
model can't improvise past a failed gate.

## 9. PR body — PR #20 (rework/karpathy-rules)
> "Adversarial 3-lens workflow … 17 findings, 0 blockers. All SHOULD_FIX
> applied" + behavior changes called out ("could have disabled husky/lefthook
> hooks elsewhere").

**Why:** states what changed, what was reviewed, and the one latent hazard the
review caught — a reviewer knows exactly what to double-check.
`gh pr view 20` to read.

## 10. Handoff — `PROGRESS.md`
**Why:** next actions ranked, machine gotchas that would cost a fresh session
an hour each, and the standing rule "code beats the file."

**Using these:** when asking any model for an artifact of type N, paste entry
N's source (or its excerpt) as the example. When something you produce is
better than the current exemplar, replace the entry — this corpus is a ratchet.
