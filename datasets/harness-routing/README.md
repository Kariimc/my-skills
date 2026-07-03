# harness-routing eval

A behavioral regression eval for the harness router hook
(`hooks/harness-router.sh`). It pins, in executable form, exactly which of the
six ultimate harnesses each kind of prompt routes to — and which prompts route
to nothing at all.

- **Dataset:** [`cases.jsonl`](./cases.jsonl) — 182 labeled prompts.
- **Runner:** [`run-eval.sh`](./run-eval.sh) — feeds every case through the
  real router and diffs the result against the label.

## What it guards

`harness-router.sh` is a `UserPromptSubmit` hook. On each prompt it runs an
ordered set of regex branches (autonomous → audit → research → quality →
refactor → build) and, on the first confident match, injects one routing hint
naming a harness skill. On no match it stays silent.

That routing table is load-bearing: it is how substantial work reaches the right
harness without the user naming it. A careless edit to any regex — tightening a
word boundary, reordering a branch, adding an alternative — can silently
re-route whole classes of prompts or start matching casual chat. This eval
turns every such change into a **precise, per-case failure** instead of a
behavior drift nobody notices until a prompt routes wrong in the wild.

It specifically locks down:

- **Clear hits** for each harness (e.g. `audit the auth flow…` → `harness-audit`).
- **The `none` case** — small talk, trivial one-liners, and out-of-scope asks
  (`what time is it?`, `fix the typo in the README`) must route to nothing.
- **Near-misses / adversarial pairs** where intent and keywords pull apart, and
  the *actual regex behavior* is the source of truth. Examples baked in:
  - `audit the project for dead code` → `harness-audit`, **not** refactor —
    the `audit` branch is checked before `refactor`, so it wins.
  - `remove dead code from the handlers` → `harness-refactor` — same topic, no
    `audit` keyword, so it falls through to the refactor branch.
  - `build a beautiful landing page` → `harness-quality`, **not** build —
    `beautiful` is checked before the build branch.
  - `build a tool to monitor uptime` → `harness-autonomous`, **not** build —
    the bare word `monitor` matches the autonomous branch, which is checked
    first. But `build a dashboard that monitors uptime` → `harness-build`,
    because `monitors` (plural) does **not** match `\bmonitor\b`, so autonomous
    misses and it falls through — a word-boundary trap the dataset pins on
    purpose.
  - `compare a few charting libraries and pick one to build with` →
    `harness-research` — `compare` outranks the build words.
  - `polish the landing page` → `none`, but `the final result must be polished`
    → `harness-quality` — the pattern is `\bpolished?\b`, which does not fire on
    the bare stem "polish"/"polishing" as they appear here.
  - `ship it` → `none`, but `ship a new settings page` → `harness-build` — the
    build branch requires `ship (a|an|the)`.
  - `add pagination` → `none`, but `add a dark mode feature` → `harness-build` —
    the `add …` pattern requires a trailing feature/endpoint/page/screen/command.

Some labels intentionally capture **known over-matches** — cases where the
router fires on a keyword the user didn't mean structurally
(`update the inventory count for SKU 42` → `harness-audit`;
`add a recurring subscription plan` → `harness-autonomous`;
`design a watch face UI` → `harness-autonomous`). These are labeled to match
real behavior, not wished behavior. If the router is later made smarter about
them, update the label in the same change — the eval failing is the signal to do
so, and the diff shows exactly which prompts moved.

## Label distribution

| expected label      | count |
|---------------------|-------|
| `none`              | 34    |
| `harness-audit`     | 30    |
| `harness-autonomous`| 28    |
| `harness-build`     | 25    |
| `harness-refactor`  | 24    |
| `harness-research`  | 23    |
| `harness-quality`   | 18    |
| **total**           | **182** |

## How to run

From the repo root (Git Bash / any POSIX `bash`; needs `python` or `python3` on
PATH — the same interpreters the router itself uses):

```bash
bash datasets/harness-routing/run-eval.sh
```

Expected output when the router matches the dataset:

```
harness-routing eval: 182/182 passed, 0 failed
All cases route as expected. Router behavior matches the dataset.
```

Exit codes: `0` = all cases match, `1` = at least one mismatch (each printed as
`expected=… actual=… :: <prompt>`), `2` = setup error (router or cases missing,
no python).

The runner does **not** re-implement the routing regexes. It pipes each case's
`{"prompt": …}` payload into `hooks/harness-router.sh` exactly as the live
`UserPromptSubmit` hook does, then reads back the harness named in the hint line
(or `none` when the hook is silent). So a green run means the real hook, not a
copy of it, agrees with every label.

## Provenance

- **Generated:** 2026-07-03.
- **Generator:** `scratchpad/gen_cases.py` (not committed — a one-shot builder).
  Every `expected` label was **computed** by an in-file port of
  `harness-router.sh`'s routing function with the regexes copied verbatim and in
  the same branch order, then **independently validated** by running the whole
  dataset through the real shell hook via `run-eval.sh` (100% agreement at
  authoring time). No label was hand-typed, so the dataset could not drift from
  the router's actual behavior at creation.
- **Source of truth:** `hooks/harness-router.sh`. If that file's regexes change,
  this dataset is expected to fail until the labels are re-derived from the new
  behavior — that failure is the whole point.

## Maintenance

1. Change a regex in `hooks/harness-router.sh`.
2. Run `bash datasets/harness-routing/run-eval.sh`.
3. For each mismatch, decide: was the re-route intended?
   - **Yes** → update that case's `expected` in `cases.jsonl` to the new route.
   - **No** → the edit was wrong; fix the regex.
4. Add new cases for any behavior the change introduced (new keyword, new branch).
