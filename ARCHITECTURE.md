# ARCHITECTURE — the `my-skills` control plane

> Deep-map of a personal Claude Code control plane. This repo is the **single
> source of truth** for the skills, subagents, rules, slash commands, and hooks
> that Claude loads in **every** project on this machine — not just this one.
> Written against the real code (2026-07-03). If it drifts from the code, the
> code wins; fix this file in the same session.

**Scale (verified live, not claimed):** 426 skills · 73 subagents · 4 slash
commands · 6 rule files · 2 global hooks · 6 apex gates · 4 git hooks.
Counts are enforced, not decorative — see the doctor gate.

---

## 1. What this repo *is*

A **control plane**, not an application. It ships no runtime product; it ships
the *configuration and guardrails* that shape how Claude behaves. The mental
model (from `README.md`): this repo is a toy box, `~/.claude/` is the shelf
Claude reads from, and a SessionStart hook copies the box onto the shelf every
time a session starts. So any project on the machine gets the same skills.

Two directions of flow, both important:

- **Outward sync** (repo → `~/.claude/`): every session, `session-start.sh`
  compiles and copies skills/rules/commands/agents/hooks to the global config.
- **Inward guard** (gates → repo): every commit/push/CI run, the apex gate
  suite blocks changes that would corrupt the control plane.

---

## 2. The layer stack

Four ranked layers. Higher layers govern lower ones; nothing overrides apex.

| Rank | Layer | Lives in | Job | Enforced by |
|---|---|---|---|---|
| 0 (apex) | **apex** — immune system | `skills/apex/`, `bin/apex*.sh`, `apex/`, `.githooks/`, `.github/workflows/apex.yml` | Self-enforcing, self-healing, self-guarding, self-extending guardrail suite. Answers to nothing. | itself (`gate_selfintegrity`) |
| 1 | **The six harnesses** — how work gets done | `skills/harness-*`, `hooks/harness-router.sh` | Named orchestration loops for substantial work (Build, Quality/GAN, Research, Audit, Autonomous, Refactor). | router hook (advisory) |
| 2 | **`skill-ship`** — how the repo changes | `skills/skill-ship/`, `bin/skill-doctor.sh` | The pipeline any change to *this* repo goes through. | `gate_doctor` |
| 3 | **The skill library** — the toys | `skills/`, `agents/`, `commands/`, `rules/` | 426 skills + 73 agents + commands + rules Claude actually uses. | sync + doctor |

Ordering is asserted in `rules/03-apex.md` ("a `selfintegrity` gate failure
outranks all other work") and in the repo `README.md` hierarchy line.

```
apex  (immune system — gates on commit/push/CI, ratchet, self-integrity)
  └── six harnesses  (Build · Quality · Research · Audit · Autonomous · Refactor)
        └── skill-ship  (skill-doctor + skill-ship skill = how the repo mutates)
              └── skill library  (426 skills · 73 agents · commands · rules)
```

---

## 3. The sync engine — `.claude/hooks/session-start.sh`

The heart of the outward flow. Registered as a `SessionStart` hook in
`.claude/settings.json` (this repo) and, after `install-global.sh`, in
`~/.claude/settings.json` (every project). It is **also** re-invoked by
`.githooks/post-commit` and `.githooks/post-merge`, so a commit or a pull
re-syncs `~/.claude/` in the background.

**Source-dir resolution** (line 25): `$1` (installer arg) → `$CLAUDE_PROJECT_DIR`
(set by Claude when this repo is open) → `$(pwd)` fallback. This is why the
global installer can point the hook at a fixed clone path.

**It prints `{"async": true, "asyncTimeout": 60000}` first** (line 19) so the
session starts *immediately* and the sync runs in the background — the sync is
never on the critical path of a session opening.

### The eight steps (in order)

| # | Step | What it does | Source of truth |
|---|---|---|---|
| pre | `git pull --ff-only` | Grabs latest skills/rules before syncing. **Fast-forward only** so a pull-only clone can never hit a merge conflict that blocks the session (line 30). `|| true` — failure is non-fatal. | remote |
| 1 | **Skills** | `cp -r skills/. ~/.claude/skills/` — mirror every skill folder. | `skills/` |
| 2 | **Rules → CLAUDE.md** | Concatenate `rules/*.md` (skip `README.md`) into `~/.claude/CLAUDE.md`, in **filename-sorted order**, each separated by a blank line. Truncates first (`: > file`). | `rules/` |
| 3 | **Slash commands** | Copy each `commands/*.md` (skip `README.md`) → `~/.claude/commands/`. | `commands/` |
| 4 | **Subagents** | Copy each `agents/*.md` (skip `README.md`) → `~/.claude/agents/`. | `agents/` |
| 5 | **Global hooks** | Copy `hooks/*.sh` → `~/.claude/hooks/`, `chmod +x`. | `hooks/` |
| 6 | **Register router** | Idempotently add the `harness-router.sh` `UserPromptSubmit` hook to `~/.claude/settings.json` via a Python JSON merge. Additive — never clobbers existing hooks; skips if already present (matches on filename, path-independent). | settings.json |
| 6b | **Register guard** | Same idempotent merge for `guard-destructive.sh` as a `PreToolUse` hook. | settings.json |
| 7 | **Arm the git guard** | *Self-scoping:* only if `$PROJECT_DIR/.githooks/pre-commit` exists (i.e. this repo) does it run `git config core.hooksPath .githooks`. Every other repo is untouched. Makes the guard survive fresh clones with zero manual `git config`. | `.githooks/` |
| 8 | Launcher settings | Restore `launcher-settings.json` if present. | `.claude/` |

### Why it's built this way (invariants baked into the sync)

- **Filename-sorted rule concat** (step 2): the numeric prefixes on rule files
  (`00-core.md`, `02-harnesses.md`, `03-apex.md`, …) are load-bearing — they set
  the order rules appear in the compiled `CLAUDE.md`. Rename a file and you
  reorder the global instruction set. `README.md` is deliberately excluded from
  the concat (it's docs, not a rule).
- **Idempotent + additive hook registration** (steps 6/6b): re-running the sync
  never stacks duplicate hooks and never removes a hook the user added by hand.
  The check is a substring match on the script filename, so it survives the hook
  living at a different absolute path on another machine.
- **Self-scoping guard activation** (step 7): the pre-commit guard is armed *only*
  in repos that ship `.githooks/pre-commit`. This is how "install once" doesn't
  leak the control-plane gates into unrelated projects.
- **Never block the session**: every risky operation (`git pull`, the Python
  merges) is wrapped `|| true`; the whole thing runs async.

---

## 4. The gate suite — `bin/apex-gates.sh`

**One library, six gates, three enforcement points.** The gate logic is defined
*exactly once* here and called identically from pre-commit, pre-push, and CI, so
a gate can never behave differently in one place than another.

Repo root is discovered by walking up until a dir has **both** `skills/` and
`rules/` (line 26–31) — the definition of "a skills control repo" used
consistently across `apex-gates.sh`, `skill-doctor.sh`, and `apex.sh`. Outside
such a repo, the gates no-op (`exit 0`).

### The gates

| Gate | Fn | Checks | Severity |
|---|---|---|---|
| Metadata integrity | `gate_doctor` | Runs `skill-doctor.sh`. Stale counts, trigger-less skills, `name`≠folder, over-long descriptions. | HARD on doctor's HARD |
| Hook safety | `gate_hooklint` | `bash -n` syntax-checks every `hooks/*.sh .githooks/* bin/*.sh`, then **live-pipes** a sample `{"prompt":"build me an app"}` through `harness-router.sh` and asserts it routes to `harness-build`. | HARD |
| Secret hygiene | `gate_secrets` | Greps tracked/staged files for credential-shaped strings (PEM keys, `AKIA…`, `AIza…`, `xox[baprs]-…`, `gh[pousr]_…`, `sk-…`). Uses `-e` so patterns starting with `-` aren't parsed as flags. | HARD |
| Self-integrity | `gate_selfintegrity` | The guard that guards the guards (see §6). | HARD (mostly) |
| Ratchet checks | `gate_extra` | Runs every `apex/checks/*.sh`; each is a self-contained drop-in check. Non-zero = HARD. | HARD |
| Liveness | `gate_live` | Is the change actually synced & firing? Checks `~/.claude/skills/apex` exists and the router is registered in settings. | soft |

**HARD vs soft:** HARD failures increment a counter and make the suite `exit 1`
(blocking the action); soft issues only warn. `note_hard` / `note_soft`
(line 36–37) are the whole mechanism.

### The three enforcement points

| Point | File | Behavior |
|---|---|---|
| **pre-commit** | `.githooks/pre-commit` | Runs `skill-doctor.sh --fix` (heals + enforces in **one** pass — the doctor is slow on Windows, so it must not run twice), re-stages auto-fixed `README.md`/`TRIGGERLESS-REPORT.md`, then runs `hooklint secrets selfintegrity extra live` **`--staged`** (scoped to staged files). Blocks on HARD. |
| **pre-push** | `.githooks/pre-push` | **Warns (does not block)** on a direct push to `master`/`main`, then runs the full unscoped suite (`apex-gates.sh all`). Blocks the push on HARD. |
| **CI** | `.github/workflows/apex.yml` | Mirrors `apex-gates.sh all` on every push/PR to `master`/`main`, so the trunk is protected even if local hooks are bypassed on another machine. Also asserts `skill-doctor --fix` produces **no** diff (metadata already reconciled). |

Note the deliberate asymmetry: `gate_live` runs at commit and (via `all`) push
but is meaningless in CI (no `~/.claude` there) — it degrades to a soft skip
(`apex-gates.sh` line 116). And the pre-commit runs the doctor *directly* (for
the `--fix` self-heal) rather than via `gate_doctor`, then skips the doctor gate
in the follow-up loop to avoid a double slow run.

---

## 5. The doctor — `bin/skill-doctor.sh`

The single integrity engine behind both the `skill-ship` skill and `gate_doctor`.
It exists to catch the failure class that caused "a month of drift" (its own
header comment): stale counts, skills that can't auto-fire, mismatched
frontmatter.

**Check mode** (`skill-doctor.sh`): report, `exit 1` on HARD.
**Fix mode** (`--fix`): heal safe drift + write triage report — but **still
`exit 1` on HARD**, which is why the pre-commit can use one `--fix` run to both
heal and enforce.

| Class | Rule | Severity |
|---|---|---|
| Missing `SKILL.md` | every `skills/*/` must have one | HARD |
| Missing / mismatched `name:` | frontmatter `name:` must **exactly equal** the folder name | HARD |
| Over-long description | > 1024 chars (Claude Code rejects/truncates → silently breaks auto-invocation) | HARD; > 700 = soft |
| Trigger-less skill | description lacks a "Use when …"-family trigger phrase | soft (→ `TRIGGERLESS-REPORT.md`) |
| Count drift | `N skills` claims in `README.md` ≠ actual folder count | soft; `--fix` rewrites it |

**Key subtlety — the trigger check is scoped to the *description*, not the whole
file** (line 74–80). The description is the only text Claude loads for
auto-invocation matching; a skill with "When to Activate" in its body but a
trigger-less description won't fire reliably. `extract_desc()` (line 40) parses
the description out of the frontmatter, handling plain, quoted, and block
(`>`/`|`) scalars.

---

## 6. `gate_selfintegrity` — the guard that guards the guards

The highest-priority gate. If it fails, the control plane's own defenses are
compromised — `rules/03-apex.md` mandates it "outranks all other work." What it
asserts (`apex-gates.sh` line 92–110):

1. **Protected files exist:** `bin/skill-doctor.sh`, `bin/apex-gates.sh`,
   `.githooks/pre-commit`, `.githooks/pre-push`, `.github/workflows/apex.yml`,
   `apex/GATES.md`. Any missing → HARD.
2. **The doctor still has teeth:** `skill-doctor.sh` must still contain the
   string `HARD` — i.e. it wasn't gutted to always-pass. → HARD.
3. **Hooks are wired:** `core.hooksPath == .githooks` (soft — not knowable in CI).
4. **Manifest ↔ implementation cross-check:** every `` `gate_*` `` named in
   `apex/GATES.md` must be an implemented function here. A gate documented but
   un-coded is itself a failure (soft).

That last point makes `apex/GATES.md` a *live contract*, not just docs: the
manifest table and the implementation are checked against each other on every run.

---

## 7. The ratchet — `bin/apex-ratchet.sh`

The self-extending mechanism. Principle: **a mistake is allowed at most once**,
then it becomes permanent machinery. Invoked as
`bin/apex-ratchet.sh "<what went wrong>"`, it:

1. Appends a numbered row to `apex/MISTAKE-LEDGER.md` (append-only ledger).
2. Slugs the description and scaffolds a runnable check at
   `apex/checks/<slug>.sh` with a TODO for the real assertion.

`gate_extra` then runs that check on every commit/push/CI forever after — the
layer extends itself **without touching the core `apex-gates.sh` library**. Drop
a new `.sh` into `apex/checks/` and it's live.

### The ledger (real mistakes, already gated)

`apex/MISTAKE-LEDGER.md` records 9 entries. Entries 1–8 were "the mistakes of the
first month" (count drift, trigger-less skills, name mismatch, the
heredoc-ate-stdin router bug, sync uncertainty, credential leak, guards being
gutted, master regression). **Entry #9** is the exemplar of the ratchet working:

> A bare 40-hex auth token committed in plaintext sailed past `gate_secrets`,
> because that gate only matched *prefixed* keys (`AKIA…`, `ghp_…`, `sk-…`) and
> its PEM pattern started with `-----`, which grep parsed as **options** (rc=2) —
> leaving it silently inert on Windows.

The fix was two-part: a new ratchet check
`apex/checks/no-plaintext-secrets-in-brain.sh` (detects bare-token + literal
shapes) **and** a fix to `gate_secrets` to pass `-e`. That check is worth reading
as the reference for how a good ratchet check is written — see §9.

---

## 8. The harness layer (rank 1) & the router

Six named orchestration loops (`skills/harness-*`) for work a single focused
loop genuinely can't do. `hooks/harness-router.sh` (a `UserPromptSubmit` hook)
reads the prompt and injects **one** short routing hint when it confidently
matches — a hint, not a mandate.

| Priority | Harness | Fires on (regex families) |
|---|---|---|
| 1 | `harness-autonomous` | `every N min`, `schedule`, `cron`, `continuous`, `monitor/watch/babysit`, `loop` |
| 2 | `harness-audit` | `audit`, `what's broken/redundant/missing`, `security review`, `vulnerab`, `production-ready` |
| 3 | `harness-research` | `research`, `investigate`, `compare`, `competitor`, `what's the best`, `fact-check` |
| 4 | `harness-quality` | `production-quality`, `polished`, `no slop`, `stunning`, `make it great` |
| 5 | `harness-refactor` | `refactor`, `simplify`, `dedup`, `dead code`, `clean up the code` |
| 6 | `harness-build` | `build me a`, `implement`, `ship a`, `create a {app,game,api,…}`, `add a … feature` |

**Ordering is load-bearing:** most-specific → least, first match wins, one hint
max (`harness-router.sh` line 62). Build is the catch-all last. On anything
ambiguous the router stays silent and lets normal skill auto-invocation work.

Audit vs Refactor is the subtle split (also called out in the global rules):
Audit *finds* problems (read-only); Refactor *fixes* structure without changing
behavior. "audit for dead code" → audit; "remove dead code" → refactor.

The router shares two hardening patterns with `guard-destructive.sh`:
- **Fastest-python resolution:** prefer `pythoncore-3.14-64\python.exe` over the
  WindowsApps Store shim (which adds ~1s/spawn — see gotchas). No interpreter →
  no-op, never block the prompt.
- **stdin-not-eaten:** the payload is read into `HARNESS_HOOK_INPUT` *before* the
  Python heredoc, because the heredoc would otherwise consume stdin and Python
  would read the script instead of the payload. This is exactly the bug that
  became ledger entry #4, and `gate_hooklint` live-tests against it.

---

## 9. The two global hooks (synced to every project)

Both live in `hooks/`, are copied to `~/.claude/hooks/` by the sync, and are
registered idempotently into `~/.claude/settings.json`.

- **`harness-router.sh`** (`UserPromptSubmit`) — the routing hint above.
- **`guard-destructive.sh`** (`PreToolUse`) — blocks catastrophic Bash before it
  runs. Exit 0 = allow, exit 2 = block. Two HARD patterns: `rm -rf /` or `~`,
  and `git push --force`/`-f` (but **allows** `--force-with-lease`). Two WARN
  patterns: `git reset --hard`, destructive SQL (`DROP`/`TRUNCATE`).

`guard-destructive.sh` is a study in hot-path performance discipline (it runs on
*every* tool call): two pure-bash pre-filters (is it a Bash call? does it even
contain a guarded keyword?) short-circuit before any interpreter spawns — because
each Windows spawn costs ~0.5–1.2s. Only a payload that *could* match pays for a
single Python parse.

`apex/checks/no-plaintext-secrets-in-brain.sh` is the reference ratchet check and
worth studying: it uses **one `git grep` per rule** over the whole tracked tree
(not a per-file shell loop — that forks once per file and takes minutes on Git
Bash), assembles the 40-hex pattern at runtime so the check file doesn't flag
*itself*, excludes lockfiles/fonts/media that carry legitimate 40-hex hashes, and
filters false positives (env lookups, `YOUR_…` placeholders, git-SHA context).
Its design contract is explicit: flag REAL committed secret material, never the
mere *mention* of a credential — or it would HARD-block every normal commit.

---

## 10. Repo layout (what's where)

| Path | Synced to | Holds |
|---|---|---|
| `skills/` | `~/.claude/skills/` | **419** skills, `skills/<name>/SKILL.md` each. Catalog in `skills/README.md`. |
| `agents/` | `~/.claude/agents/` | **67** subagents (`*.md`): per-language `*-reviewer` + `*-build-resolver`, the `gan-{planner,generator,evaluator}` trio, `architect`, `code-explorer`, `chief-of-staff`, etc. |
| `rules/` | `~/.claude/CLAUDE.md` | 6 always-on rule files, concatenated filename-sorted: `00-core`, `02-harnesses`, `03-apex`, `04-response-mode`, `05-github-workflow`, `07-progress-file`. |
| `commands/` | `~/.claude/commands/` | 4 slash commands: `/new-skill`, `/revise-claude-md`, `/skill-audit`, `/sync-skills`. |
| `hooks/` | `~/.claude/hooks/` | The 2 global hooks + auto-registration into settings. |
| `bin/` | — (tooling) | `apex.sh`, `apex-gates.sh`, `apex-ratchet.sh`, `skill-doctor.sh`, `eval-router.sh`, `apply-hook-tuning.sh`, watch scripts. |
| `apex/` | — | `GATES.md` (manifest/contract), `MISTAKE-LEDGER.md`, `checks/*.sh` (ratchet drop-ins). |
| `.githooks/` | — | `pre-commit`, `pre-push` (the guards) + `post-commit`, `post-merge` (re-sync triggers). Armed via `core.hooksPath`. |
| `.github/workflows/` | — | `apex.yml` (CI mirror), `dependabot-auto-merge.yml`. |
| `.claude/` | — | This repo's own config: `session-start.sh` + settings. **Not** synced out. |

`bin/apex.sh` is the one-prompt installer/verifier: chmods every guard, runs
`git config core.hooksPath .githooks`, confirms the CI mirror exists, heals
drift, runs the full suite, and prints a status dashboard. Idempotent — re-run
any time to re-arm.

---

## 11. Key invariants (the load-bearing rules)

1. **`core.hooksPath` must stay `.githooks`.** The whole local guard depends on
   it. `session-start.sh` step 7 re-arms it on every session; `bin/apex.sh`
   re-arms on demand; `gate_selfintegrity` warns if it drifts. (Verified: it is
   currently `.githooks`.)
2. **`selfintegrity` outranks everything.** A `selfintegrity` failure is the
   highest-priority issue in the repo — the checks that guard the checks are
   compromised. (`rules/03-apex.md`.)
3. **One fact per memory / one recipe per distill.** The Distill step
   (`rules/00-core.md`) writes recipes into PROGRESS.md gotchas or auto-memory —
   *not* a new file; and if it can regress, encode it as a gate, not prose. The
   auto-memory itself is one-fact-per-entry (see `MEMORY.md`).
4. **Filename-sorted rule concatenation.** `rules/*.md` numeric prefixes set the
   order of the compiled `~/.claude/CLAUDE.md`. `README.md` is excluded.
5. **`name:` == folder name, exactly.** HARD doctor gate. A mismatch means the
   skill won't resolve.
6. **Every skill needs a "Use when …" trigger in its *description*.** The
   description is the only text loaded for auto-invocation; no trigger → the
   skill only works when called by name.
7. **A gate is defined exactly once** in `bin/apex-gates.sh` and runs identically
   at all three enforcement points. Never disable, weaken, or route around a
   gate — fix the gate and update `apex/GATES.md`.
8. **A mistake is allowed at most once.** Then it's ratcheted into
   `apex/checks/` and can never recur silently.
9. **Idempotent, additive, self-scoping.** Sync re-registration never duplicates
   or clobbers hooks; the git guard arms only in repos that ship `.githooks/`.
10. **Never block the session or the prompt.** Sync is async + `|| true`
    throughout; hooks no-op when no interpreter is available.

---

## 12. Gotchas (the machine reality — from `PROGRESS.md`)

These are real, load-bearing environment facts. Ignore them and things silently
break or crawl on this Windows box.

- **Python shim is slow.** `python3`/`python` on PATH = the WindowsApps Store shim
  (~1.2s/spawn). The fast interpreter is
  `C:\Users\karii\AppData\Local\Python\pythoncore-3.14-64\python.exe`. Both the
  router and the guard hard-code a preference for it. Hooks on the hot path must
  respect this or every tool call pays the tax.
- **Git Bash forks are slow.** Bulk per-file shell loops over 400+ skill dirs
  **time out**. Use single-pass `awk`/`python`/`git grep`, never a `for f in
  skills/*` loop that spawns per file. (This is baked into `skill-doctor.sh` and
  the ratchet check design.)
- **Commits/pushes run the full gate suite: ~5 min each.** Run them in the
  background with a ~10-min budget; don't block on them interactively.
- **Long-lived agent shells have stale PATH.** `gh`/`jq`/`rg`/`fd` need full
  paths inside old shells; fresh terminals are fine.
- **`~/.claude/settings.json` is classifier-blocked for the agent.** The agent
  can't edit it directly — hand the user a script (pattern:
  `bin/apply-hook-tuning.sh`). This is *why* the sync uses a Python merge run by
  the hook rather than the agent editing settings.
- **Never put guarded strings literally in a Bash command line.** `rm -rf /`, a
  force-push, etc. — the live `guard-destructive.sh` blocks the call. Pipe test
  payloads from a file instead.
- **Windows 10 Home 10.0.19045 is past end-of-support (Oct 2025).** Migration is
  an open item.

---

## 13. Onboarding pointer

New here? Read in this order:

1. **`README.md`** (repo root) — the toy-box/shelf mental model + how to install
   globally (`bash install-global.sh`) and add a skill.
2. **`PROGRESS.md`** (repo root) — live session handoff: current focus, next
   action, the machine gotchas. Read before touching anything; if it conflicts
   with the code, the code wins.
3. **This file** — the deep structure and invariants.
4. **`apex/GATES.md`** — the gate manifest/contract. Then read
   `bin/apex-gates.sh` and `bin/skill-doctor.sh` to see the gates in code.
5. **`skills/README.md`** — the 419-skill catalog by category.

To go live after a change: `bin/apex.sh` (arm + verify), then `/sync-skills` or
just start a new session. To add a skill: `/new-skill <name>`, ensure
`name:` == folder and the description ends with a sharp "Use when …" trigger,
commit (the pre-commit heals counts + enforces), push. When a mistake slips a
gate: `bin/apex-ratchet.sh "<what happened>"`, fill in the generated check, commit.
