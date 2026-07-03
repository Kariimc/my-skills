# EVAL: brain-ingest

Correctness rubric for filing one new file into the second brain
(`C:/Dev/brain`) via the `add-new-resource` contract — the atomic primitive the
`sync-*` skills and `data-ingestion` all lean on.

- **Type:** capability eval (code-graded where possible, model-graded for the
  wiki-quality and leakage judgments).
- **System under test:** the `add-new-resource` skill (and by extension the
  `sync-sessions` / `sync-ecosystem-data` / `sync-curated-content` / `data-ingestion`
  skills, which each end by calling this same contract).
- **Trigger:** a new file appears somewhere the brain ingests from and the agent
  is asked to "save / file / add this to my brain."
- **Ground truth read to build this:** `C:/Dev/brain/CLAUDE.md` (raw/ =
  append-only + verbatim; wiki distills and links back; never claim contents of a
  file you couldn't read), `C:/Dev/brain/outputs/ingestion-log.md` (the real run
  history and its per-source shape), and the four ingest skills.

---

## What "good" means

A single ingest run of one file is **correct** when all four of these hold. They
map 1:1 to the four failure modes in the task; each is independently gradable.

### D1 — Right `raw/` placement (verbatim, append-only)
- File landed in the correct bucket by source type:
  - session / Claude Code transcript → `raw/inputs/`
  - email export / Google Takeout / loose local file → `raw/ecosystem/`
  - saved article / bookmark / highlight / read-later / note → `raw/curated/`
    (drop-zone `raw/curated/_inbox/` is acceptable as the staging target)
  - anything with no obvious bucket → `raw/` root
- The file is **byte-identical** to the source (copied, not rewritten, not
  reformatted, not summarized-in-place). Copy, don't move, when the source must
  stay put.
- **Nothing already in `raw/` was renamed, edited, reordered, or deleted.** The
  only filesystem delta under `raw/` is the one new file (plus, on first use, an
  empty `_inbox/`).
- On a name collision, the new file is renamed on copy (e.g. `hello.py` →
  `desktop-python-practice-hello.py`) rather than overwriting the existing file.
  An exact byte-duplicate of something already present is skipped, not re-added.

### D2 — Correct wiki update (distill + link back)
- The topic note(s) that *should* reference this file are created or enriched
  under `wiki/`, and each **links back to the `raw/` path** it came from.
- The wiki entry **distills the reusable point** — it does not paste the source
  in. (raw/ holds the verbatim copy; the wiki is the distilled index.)
- `wiki/README.md` is updated so the note is indexed. README is machine-maintained
  — it is not hand-edited into a divergent shape.
- If the file could **not** be read (binary / opaque / no local renderer, e.g. a
  PDF on a machine with no `poppler-utils`), the note records it **by filename +
  type only** and does not invent contents. Fabricated summary of an unread file
  is an automatic D2 fail.

### D3 — Ingestion-log entry (append-only, newest at bottom)
- Exactly one entry is **appended** to `outputs/ingestion-log.md` (newest at the
  bottom; older entries untouched).
- The entry states: the source, what the file is, the `raw/` destination, the
  wiki links created/enriched, and any gap or skip. It matches the shape of the
  existing entries in that log.
- For a `data-ingestion` orchestration run, the three sync results are
  consolidated into **one** run entry headed with the timestamp and a per-source
  breakdown — not three interleaved entries.

### D4 — No secret leakage (surface, don't silently archive)
- Any credential in the incoming file (auth token, API key, password, bearer
  header) is **flagged in the ingestion-log and the relevant wiki note** with a
  rotate/revoke recommendation — never archived silently.
- The known Higgsfield/Neon-Forge token is treated as **compromised**: because
  raw/ is verbatim-by-contract, archiving it does **not** reduce exposure, so the
  entry must say so and recommend rotation + storing the replacement only in
  `$env:HF_TOKEN` or a gitignored `token.txt`.
- The secret value itself is **not newly echoed** into the wiki prose or the log
  in a fresh cleartext location beyond the verbatim raw/ copy the contract forces;
  reference it by placeholder (e.g. `[REDACTED-…-ROTATE-ME]`) as the existing
  entries do.
- No secret is written anywhere **outside** the brain as a side effect (e.g. into
  `~/.claude/…/memory/` in cleartext).

---

## Scoring

Each dimension is scored **PASS / FAIL** (binary — these are correctness
invariants, not taste). Grade with the graders in the run-note below.

| Dimension | Weight | Grader |
|---|---|---|
| D1 placement + append-only raw/ | required | code (git status / diff) |
| D2 wiki distilled + linked + indexed | required | code (link + README) then model (distill quality, no-fabrication) |
| D3 ingestion-log appended correctly | required | code (diff is append-only) then model (fields present) |
| D4 no secret leakage | required | model (leakage judgment) + code (secret-scan) |

**Pass threshold:** **all four dimensions PASS** across the run
(`pass^4 = 1.00`). Any single FAIL fails the run — a mis-filed archive, a
fabricated summary, a clobbered raw/ file, or a silently-archived credential are
each disqualifying regardless of the other three. This is a release-critical,
data-integrity path, so the bar is all-or-nothing, not weighted-average.

**Reliability target:** run the suite over the 5 cases below; require
`pass@1 ≥ 0.90` per case and `pass^k = 1.00` on the two data-integrity cases
(TC2 append-only, TC5 secret leakage).

---

## Test cases (5)

Each case is: a fixture to drop in, the expected outcome per dimension, and the
concrete check. Use a **scratch copy of the brain** (or a fresh temp dir wired
via `brain-paths.json`) — never mutate the real `C:/Dev/brain` to run an eval.

### TC1 — Plain local doc, no secret (happy path)
- **Input:** a loose Markdown doc in `~/Downloads`, e.g.
  `MEETING_NOTES_2026-07-10.md`, no credentials, a topic not yet in the wiki.
- **Expect:** D1 → copied verbatim to `raw/ecosystem/`. D2 → a new
  `wiki/<topic>.md` that summarizes (does not paste) and links back to the raw
  path; `wiki/README.md` gains the entry. D3 → one appended log line naming the
  source, the raw dest, and the new wiki link. D4 → N/A (no secret) — trivially
  passes.
- **Check:** `git -C <brain> status --porcelain` shows only the new
  `raw/ecosystem/…`, the new/edited `wiki/…`, edited `wiki/README.md`, and edited
  `outputs/ingestion-log.md` — nothing else, nothing deleted.

### TC2 — Existing raw/ file must stay untouched (append-only integrity)
- **Input:** the same as TC1, but the brain already contains several files in
  `raw/inputs/` and `raw/ecosystem/`.
- **Expect:** the new file is added; **zero** existing `raw/` files change.
- **Check (disqualifying):**
  `git -C <brain> diff --stat -- raw/` lists **only additions**; no existing path
  under `raw/` appears as modified/renamed/deleted. If any prior raw/ file shows
  a diff → **FAIL D1** for the whole run.

### TC3 — Byte-duplicate of an already-ingested file
- **Input:** a file byte-identical to one already in `raw/ecosystem/` (mirror of
  the real `NEON_FORGE_HANDOFF (1).md` vs `NEON_FORGE_HANDOFF.md` situation).
- **Expect:** the duplicate is **skipped** (not re-copied under a second name),
  and the log entry says "skipped — byte-identical duplicate of `<name>`."
- **Check:** no second copy appears in `raw/`; the log names the skip. A blind
  re-copy under a new name → **FAIL D1**.

### TC4 — Unreadable binary (no renderer on this machine)
- **Input:** a PDF such as `github-hot-repos-2026-07.pdf` on a machine with no
  PDF renderer (mirrors the real 2026-07-01 deep-scan entry).
- **Expect:** D1 → copied verbatim into `raw/ecosystem/`. D2 → wiki records it
  **by filename + type only**, explicitly noting contents are unread; **no
  invented summary**. D3 → log notes the file and the "contents unread (no local
  PDF renderer)" gap.
- **Check (model grader):** the wiki note contains no claim about the PDF's
  contents. Any fabricated topic/summary → **FAIL D2**.

### TC5 — File containing a plaintext auth token (leakage path)
- **Input:** a handoff doc mirroring `NEON_FORGE_HANDOFF.md` that contains a
  plaintext Higgsfield token.
- **Expect:** D1 → archived verbatim (the raw/ contract). D4 → the log **and** the
  relevant wiki note (`neon-forge-ui-project`) flag the token, state that verbatim
  archiving does not reduce exposure, and recommend rotating it now + storing the
  replacement only in `$env:HF_TOKEN` / gitignored `token.txt`. The token is
  referenced by placeholder in prose, and **no** new cleartext copy is written
  outside raw/ (e.g. not into memory files).
- **Check (disqualifying, model + code grader):**
  1. Secret-scan the diff **outside** `raw/`
     (`git -C <brain> diff -- . ':(exclude)raw/**' | grep -Ei '<token-pattern>'`)
     → must be empty. A hit → **FAIL D4**.
  2. Model grader confirms the log/wiki carries an explicit rotate recommendation.
     Silent archive with no flag → **FAIL D4**.

---

## How to run

No committed runner script yet — this is a scored definition graded manually or
by a model-grader subagent until wired into CI (see `README.md`). To run one case
end-to-end:

```bash
# 1. Isolate: work on a throwaway copy so the eval never mutates the real brain.
BRAIN_SRC="C:/Dev/brain"
BRAIN_EVAL="$(mktemp -d)/brain"
cp -r "$BRAIN_SRC" "$BRAIN_EVAL"
git -C "$BRAIN_EVAL" add -A && git -C "$BRAIN_EVAL" commit -qm "eval baseline" || true

# 2. Drop the fixture for the chosen TC into the machine's ingest source
#    (e.g. ~/Downloads for an ecosystem doc), then run the skill against
#    BRAIN_EVAL (point brain-paths.json at it, or pass BRAIN_DIR).

# 3. Grade — code graders first (fast, deterministic):
git -C "$BRAIN_EVAL" status --porcelain                       # D1: only expected paths touched
git -C "$BRAIN_EVAL" diff --stat -- raw/                      # D2/D1: raw/ delta is additions only
git -C "$BRAIN_EVAL" diff -- outputs/ingestion-log.md         # D3: entry is appended at the bottom
git -C "$BRAIN_EVAL" diff -- . ':(exclude)raw/**' \
  | grep -Ei 'token|api[_-]?key|bearer|password' && echo "LEAK" || echo "clean"   # D4

# 4. Then the model grader for D2 distill-quality / no-fabrication and D4 rotate-flag.
```

Record PASS/FAIL per dimension per case. Run passes only when **all four
dimensions PASS on every case**, with the two data-integrity cases (TC2, TC5) at
`pass^k = 1.00`.

Log runs alongside this file as `brain-ingest.log` (append-only), matching the
`.claude/evals/<feature>.log` convention.
