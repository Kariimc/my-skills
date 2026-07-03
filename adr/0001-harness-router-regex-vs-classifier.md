# 0001 — Harness router: hand-maintained regex vs. LLM classifier

- **Status:** Accepted
- **Date:** 2026-07-03
- **Deciders:** control-plane owner
- **Grounds:** `hooks/harness-router.sh`, `bin/eval-router.sh`,
  `datasets/harness-routing/cases.jsonl` (182 cases), `CLAUDE.md` (THE SIX
  ULTIMATE HARNESSES)

## Context

A `UserPromptSubmit` hook, `hooks/harness-router.sh`, reads every prompt and, on
a confident match, injects one short hint naming which of the six ultimate
harnesses likely fits (build / quality / research / audit / autonomous /
refactor). It is a **safety net**, not the only trigger — CLAUDE.md is explicit
that the model should also reach for harnesses on its own judgement.

The mechanism today is an ordered list of Python regexes (`harness-router.sh`
lines 62–111): most-specific class first, first match wins, at most one hint,
silent on anything ambiguous. It runs **on every single prompt**, synchronously,
inside the hook path — so its latency is paid by the user before the model even
starts. The file already fights two Windows-specific costs to stay fast: it
prefers a real Python over the WindowsApps shim (lines 20–32, ~1s/spawn saved,
per MEMORY) and forces UTF-8 stdout so arrows can't crash cp1252 consoles
(lines 42–48).

The router is now backed by a real regression harness: `bin/eval-router.sh`
feeds all 182 prompts in `datasets/harness-routing/cases.jsonl` through the
**real** hook as JSON-on-stdin and scores per-class precision/recall/F1 +
overall accuracy, failing below `THRESHOLD` (default 0.90). The dataset
deliberately includes a large negative class — 34 of 182 cases are `none`
("router must stay silent") — alongside the six harnesses (audit 30, autonomous
28, build 25, refactor 24, research 23, quality 18). So the accuracy question is
finally measurable, not vibes.

The open question: should routing stay regex, or move to an LLM classifier?

## Options

1. **Keep the hand-maintained regex (chosen).** A curated, ordered pattern list
   in the hook. Zero network, near-zero latency, fully deterministic, and every
   change is diffable and instantly gradeable against the 182-case eval.
   Cost: patterns are maintained by hand; novel phrasings that dodge the
   keywords route to `none` (silent) until someone adds a pattern.

2. **LLM classifier.** Call a model in the hook to label the prompt. Best
   recall on unseen phrasings and paraphrase. But it puts a model call *on the
   UserPromptSubmit critical path* (latency + a hard network/credential
   dependency before the user's turn even begins), is **non-deterministic** (the
   same prompt can route differently run to run, so the eval can't gate it the
   way it gates regex), costs tokens on every keystroke-turn, and can fail
   closed in a way that blocks or slows the prompt. A hint that is sometimes
   wrong and always slow is worse than a fast hint that is silent when unsure.

3. **Hybrid: regex first, model on the misses.** Regex handles the confident
   cases; when regex returns `none`, fall back to a classifier. Keeps the happy
   path fast, recovers some recall — but reintroduces the network/latency/
   nondeterminism dependency for exactly the ambiguous prompts, doubles the code
   paths to maintain and test, and the router is explicitly designed to be
   *silent* when unsure (a wrong hint is more expensive than no hint), which
   blunts the upside of the fallback.

## Decision

**Option 1 — keep the hand-maintained regex.** For a per-prompt hook whose
entire job is to emit an optional, conservative, one-line hint, the regex wins
on every axis that matters here: it is **fast** (no model call on the critical
path), **deterministic** (same prompt → same route, always), and now
**testable** — the 182-case `eval-router.sh` turns "is the router good?" into a
number with a CI-able threshold, which a nondeterministic classifier could not
satisfy. The router being silent on an unseen phrasing is an acceptable failure
mode by design (CLAUDE.md: the model reaches for harnesses itself; the router is
a net, not a gate). Recall gaps are fixed the cheap way: add a case to the
dataset, add a pattern, watch the score.

## Consequences

- **Good:** No latency, cost, or network/credential dependency added to the
  prompt path. Every routing change is a one-line diff graded by
  `eval-router.sh` before it ships. Behavior is reproducible in CI and on every
  machine, Windows console quirks already handled.
- **Cost / carried risk:** Coverage is only as good as the pattern list; new
  ways of phrasing a task route to `none` until a human adds a pattern. This is
  invisible unless the dataset grows to include the missed phrasings — so the
  dataset must be fed real-world misses, not just synthetic cases.
- **Maintenance signal:** The dataset + eval double as the health meter. Track
  two things: (a) how often a pattern edit is needed, and (b) the `none`-class
  recall (are real tasks silently going unrouted?).

## Revisit trigger

Reopen this decision if **any** of:

- Keeping the patterns current becomes a recurring chore — more than a couple of
  pattern edits per month just to track how tasks are phrased; **or**
- The `none` class on a *representative* dataset shows the router is silently
  missing a material share of real tasks (e.g. false-silent rate materially
  above the intentional-conservatism baseline the 0.90 threshold assumes); **or**
- A deterministic, local, sub-100ms classifier becomes available that
  `eval-router.sh` can gate exactly like the regex (removing the nondeterminism
  objection, not just the latency one).

Until then: **regex, graded by the 182-case eval.**
