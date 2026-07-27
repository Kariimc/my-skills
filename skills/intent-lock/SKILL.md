---
name: intent-lock
description: The four-question interview that runs BEFORE work begins on any task touching more than two files. Asks what finished looks like, what must not change, what counts as proof, and whether anything irreversible is expected - then writes the answers to INTENT.md in that project so every later check measures against the written record instead of a memory of the chat. Use before starting any multi-file change, feature, refactor, or migration, and whenever a task's finish line is not already written down.
---

# intent-lock

Four questions, asked once, written down. Everything downstream checks against
the file, never against what anyone remembers being said.

## When it fires

Before the first edit of any task that will touch **more than two files**.
Also fire it when a task is smaller than that but the finish line is genuinely
unclear.

**Do not fire it** for: a one- or two-file change with an obvious finish line,
a typo, a straightforward bug fix, active debugging, or a task where a current
`INTENT.md` already covers this work.

## Relationship to intent-driven-development

This skill is the **front door**, not a replacement. It is deliberately four
plain-language questions and one file.

Hand off to the repo's `intent-driven-development` skill — do not re-derive its
method here — the moment the work is **high-impact**: security, authentication,
persistent data, a migration, an external API, money, or anything cross-system.
That skill produces the full numbered `AC-NNN` acceptance brief. Run this
interview first, then hand its four answers to it as the starting context.

## The interview

Ask all four in **one message**, in plain words, numbered. Never more than four.
Never ask something the repo, `PROGRESS.md`, `HANDOFF.md`, a ticket, or an
existing `INTENT.md` already answers — recon first, then ask only what is left.
If recon answers a question outright, state the answer as an assumption instead
of asking it.

1. **What does finished look like?** What can you do, see, or click when this
   is done that you cannot do now?
2. **What must not change?** What is working today that would count as a
   failure if it moved?
3. **What will you accept as proof?** A passing test, a screenshot, a number, a
   real run — name the thing you want to see.
4. **Is anything irreversible expected?** A deploy, a migration, a deletion, a
   push to main, real money, a message to someone outside — yes or no, and
   which.

Then wait. Do not start the work while the questions are unanswered.

## Write the file

Write `INTENT.md` at the **project root** (not `~/.claude`, not a subfolder).
Exactly this shape:

```markdown
# INTENT — <task name>

Written: <YYYY-MM-DD>
Status: active

## Finished looks like
- <answer 1, one bullet per observable outcome>

## Must not change
- <answer 2, one bullet each>

## Proof I will accept
- <answer 3, one bullet each — each must be something a command or a screenshot can produce>

## Irreversible steps expected
- <answer 4; write "none" if none. Anything listed here needs a fresh yes at the moment it happens.>

## Out of scope
- <anything explicitly ruled out during the interview>
```

If `INTENT.md` already exists and is `Status: active`, do **not** overwrite it.
Read it, ask only what has changed, and append a `## Revision <n> — <date>`
section beneath.

## The rule this exists to enforce

Every later verification — the `verifier` agent, the verify gate, any "is it
done?" check — reads `INTENT.md` and measures against **that**. A conversation
drifts; a file does not. If the work no longer matches the file, the file is
what is right: either the work is wrong, or the file gets an explicit, dated
revision. Never quietly re-interpret it.

Mark `Status: done` only when every line under **Proof I will accept** has been
produced and pasted.
