# HANDOFF — Portfolio Remediation (Claude Code)
> Source of truth: the three audits in this session — `PORTFOLIO-AUDIT.md`, `MY-SKILLS-AUDIT.md`, `HOOPCLONE-AUDIT.md`. This handoff is the executable version of every finding in them.
> Author: Claude Fable 5 · 2026-07-06. Owner: Kariim.

---

## HOW TO USE THIS
You are a principal engineer. Work top-down: tasks are in **payoff order** (highest-leverage first). Each task is self-contained — do it, verify it against its **Done bar**, commit, move on. One PR per task unless noted.

**Global rules for this handoff:**
- Branch per task: `fix/<task-id>`. Conventional-commit messages. Open a PR; don't merge to master without CI green.
- Every repo lives under the `Kariimc` GitHub org. Clone fresh if you don't have it.
- **Do NOT invent scope.** If a task's premise is already fixed in the code, say so and skip — don't manufacture work.
- **Gates resolved 2026-07-06:** Task 4 = **Mirror (A)** — proceed without asking. Task 9 = deep clean approved in principle — the ONLY remaining stop is showing the size preview and getting a one-word "go" before force-push. Task 8 = DROPPED (owner keeps Bball untouched). Everything else: act, don't ask.
- Proportionality: `whome-diagnostic-tool` and `Bball` are intentionally near-untouched. Don't over-engineer them.

**Task index (do in this order):**
1. Just-a-pinch — test the money & data paths ← highest leverage
2. Just-a-pinch — delete dead `backend/`, move design refs
3. Faceless-Tech-youtube — add CI (tests already exist)
4. my-skills — fix sync-never-deletes 🛑 GATED (decision)
5. my-skills — kill README count drift
6. Hoopclone — Sprint-5 prep: bug fixes + `main.gd` split
7. Midnight-return- — README + smoke tests + CI
8. ~~Bball — archive~~ DROPPED by owner
9. LFS migration — Learning-app + Hoopclone 🛑 GATED (history rewrite)
10. Omni-3d / Sub-Scraper — test breadth (only if active)

---

## TASK 1 — Just-a-pinch: test the money & data paths
**Repo:** `Just-a-pinch` · **Branch:** `fix/jap-critical-tests` · **Why:** only revenue app (Stripe + RevenueCat + AI-credit metering), **0 tests** across 13.5k LOC. Security is already mature (RLS verified); the unguarded risk is *correctness of money and data*. This is the single highest-value task in the portfolio.

**Do NOT chase coverage %.** Cover exactly these three surfaces, then stop:

**1a. AI-credit metering — `consume_ai_credit` (SQL function).**
- Set up Supabase local test DB (`supabase start`; use the migrations in `supabase/migrations/`).
- Tests: (i) a normal consume decrements by exactly the amount; (ii) consuming more than remaining is rejected, not driven negative; (iii) **concurrency** — two simultaneous `consume_ai_credit` calls on the same user with 1 credit left: exactly one succeeds. This is the bug that gives away paid AI or double-charges. Use two DB connections in one test to force the race.

**1b. `storage.ts` dual-write reconciliation** (`mobile/src/store/storage.ts`).
- It dual-writes Supabase (signed-in) + AsyncStorage (always). Test the conflict path: write offline → write same record online → reconcile → assert no silent data loss and a deterministic winner. Mock AsyncStorage; use the local Supabase for the remote side.

**1c. The three edge-function webhooks** (`supabase/functions/{stripe,revenuecat,delete-account}`).
- For stripe + revenuecat: (i) a request with a **bad/absent signature is rejected**; (ii) a **replayed** valid webhook is idempotent — entitlement granted once, not twice. For delete-account: it uses service_role — assert it only ever deletes the *caller's* rows (pass a forged `user_id`, expect refusal).

**Wiring:** add Jest + ts-jest to `mobile/` (RN 0.85 / Expo SDK 56 — match versions from `mobile/package.json`, don't independently pin). Add `"test": "jest"`. Extend `.github/workflows/build-android.yml` OR add `test.yml` that runs `npm test` in `mobile/` on push + PR. SQL tests can run via a `supabase-test` job (spin up local, apply migrations, run pgTAP or a node harness).

**Done bar:** `npm test` green locally and in CI; the three race/replay/forgery tests each **fail if you revert the guard they cover** (prove they bite — a test that passes against broken code is worthless). Report coverage of the three target files only.

---

## TASK 2 — Just-a-pinch: delete dead backend, relocate design refs
**Branch:** `chore/jap-prune` · Small, do alongside Task 1 or right after.
- `CLAUDE.md` states the `backend/` Express server is dead ("nothing points at it" — capture endpoints moved to the `recipe-api` edge function). **Confirm** nothing imports it (grep the mobile app for any localhost/backend URL), then delete `backend/`. It's a second attack surface for zero benefit.
- Move the 57 `hf_*.png` design refs out of repo root → `docs/refs/`. Update any references. (They're image exports, not secrets — just clone-bloat.)

**Done bar:** app builds and runs with `backend/` gone; root is clean; grep for the old backend URL returns nothing.

---

## TASK 3 — Faceless-Tech-youtube: add CI
**Branch:** `ci/add-pytest` · **Why:** 8 test files already exist, **no CI runs them.** Cheapest win in the portfolio (~15 min).
- Add `.github/workflows/ci.yml` mirroring Hoopclone's pattern: `actions/setup-python`, matrix `["3.10","3.11","3.12"]`, `pip install` from `pyproject.toml`, `pytest -v`, on push + PR, with the `concurrency: cancel-in-progress` block.

**Done bar:** CI badge green on a trivial PR; deliberately break one test → CI goes red → revert.

---

## TASK 4 — my-skills: fix sync-never-deletes 🛑 GATED
**Repo:** `my-skills` · **Branch:** `fix/sync-mirror-semantics` · **Why:** `.claude/hooks/session-start.sh` uses `cp -r` for skills/commands/agents — **never deletes**. Any skill deleted/renamed in the repo stays live in `~/.claude/` forever on every machine, still auto-triggering. (Rules rebuild-from-zero correctly; only these three don't.)

✅ **GATE RESOLVED — Owner chose Option A (Mirror) on 2026-07-06. Implement A; Option B kept below for the record only:**
- **Option A — Mirror (recommended):** `rsync -a --delete` (or delete-dir-then-copy) for skills/commands/agents. Repo becomes true source of truth. **Risk: wipes any skill that exists only in `~/.claude/` and not in the repo.**
- **Option B — Tombstone:** keep `cp`, add a `REMOVED.txt` the hook processes to delete named entries. Safer if any machine has hand-dropped local skills.

Proceed directly with A. Then:
- Implement the chosen semantics. Keep the async-hook + ff-only-pull behavior intact. Preserve the Windows/cygpath handling.
- If A: the hook must print what it removed on first run so it's auditable.
- Add a dry-run first-sync note to the README.

**Done bar:** create a throwaway `skills/_deletetest/SKILL.md`, sync, confirm it lands in `~/.claude/skills/`; delete it from the repo, sync again, confirm it's **gone** from `~/.claude/skills/`. Remove the test skill.

---

## TASK 5 — my-skills: kill README count drift
**Branch:** `fix/readme-count-gate` · **Why:** README says 411 skills / 67 agents; actual is **416 / 68** — in the repo whose apex layer advertises auto-fixing count drift. Credibility hole in the gate suite.
- Stop hand-writing counts. Make a gate (extend the existing count check, or add `apex/checks/`) that computes `ls skills | wc -l` and `ls agents/*.md | wc -l` and either (a) substitutes them into the README, or (b) fails CI on mismatch. Prefer (a) — drift becomes impossible.
- Add the entry to `apex/MISTAKE-LEDGER.md` per the ratchet rule ("a mistake happens at most once").
- Fix the current README numbers to 416 / 68 as part of the PR.

**Done bar:** add a dummy skill dir → gate updates/asserts the count automatically → CI stays honest. Remove the dummy.

---

## TASK 6 — Hoopclone: Sprint-5 prep (bugs + the main.gd split)
**Repo:** `Hoopclone` · **Branch:** `refactor/sprint5-prep` · **Why:** Sprint 5 (box score) will land inside an already-overloaded `main.gd` unless the seams are cut first. Full detail in `HOOPCLONE-AUDIT.md` §3–§5. Do these in order:

**6a. Bug fixes (cheap, do first):**
- **Miss-can-swish** (`game/player/shot.gd` `release()`): miss offset is `randf_range(-0.35,0.35)` per axis but rim radius is 0.23 — some "misses" fly clean through. Replace with polar offset: random angle, `radius = randf_range(rim_radius+0.05, 0.40)`.
- **Signal semantics** (`game/ball/ball.gd`): `missed` fires when the bounce *starts*, `made` when flight ends. Before the box score consumes these, make `missed` mean "ball live for rebound" — move the emit to where the bounce settles, or add `rebound_live`. Decide and document in `DECISIONS.md`.
- **Defender-registration guard** (`game/main.gd` `_spawn_defender`): if `player.shot` is null (equip early-returned when `RightHoop` missing), registration silently no-ops → every shot uncontested, no error. Add a `push_warning` on failure.

**6b. Split `main.gd`** (~430 lines, 5 jobs) — pure cut-and-paste, zero behavior change:
- `game/arena/crowd_bowl.gd` — CROWD_SHADER + `_make_crowd_arc` + `set_crowd_intensity`
- `game/arena/arena_builder.gd` — underfloor, courtside, floor-texture hydration
- `game/boot/spawner.gd` — player body, ball, defender spawn
- `main.gd` keeps only `_ready()` orchestration (~60 lines)

**6c. Scene-smoke test:** add to `tests/godot/run_tests.gd` (its existing style) a headless instance of `main.tscn` asserting player has shot + ball + rim + ≥1 registered defender. Catches the whole boot-order bug class.

**Done bar:** Godot headless self-test + Python pytest both green; game runs identically (camera, shot, contest, crowd) — verify by launching; `DECISIONS.md` updated with the signal-semantics call and a Sprint-4.5 row reconciling the README sprint table.

---

## TASK 7 — Midnight-return-: onboarding + safety net
**Repo:** `Midnight-return-` · **Branch:** `chore/readme-and-tests` · **Why:** 13.8k LOC Unity/HDRP, **no README, no tests, no CI.** Hardest stack to onboard cold.
- Generate `README.md` from `CLAUDE.md` + the `Assets/` structure: stack (Unity 2023.2 LTS + HDRP 16), how to open, project layout, current state.
- Add EditMode tests around the deterministic systems (combat math, physics/movement constants) — the things that break silently on refactor. Start with the 3–4 highest-traffic scripts.
- Add a Unity-test GitHub Actions workflow (game-ci/unity-test-runner or equivalent).

**Done bar:** README lets a stranger open and run it; EditMode tests pass in CI.

---

## TASK 8 — ❌ DROPPED (owner decision 2026-07-06: Bball stays as-is — no banner, no archive, no commits)
<details><summary>Original spec (kept for the record, do not execute)</summary>

## Bball: archive as superseded
**Repo:** `Bball` · **Branch:** `chore/archive-notice` · **Why:** it's the abandoned C# predecessor to Hoopclone (now Godot/GDScript). Looks like live code; isn't.
- Add a top-of-README banner: "⚠️ Superseded by [Hoopclone](https://github.com/Kariimc/Hoopclone). Kept for history; not maintained."
- Then archive the repo on GitHub (Settings → Archive). **This is a GitHub UI action I'll do**, or you do it via `gh repo archive Kariimc/Bball` — your call, name which.

**Done bar:** banner merged; repo archived (or `gh` command handed to me if auth-scoped).
</details>

---

## TASK 9 — LFS migration: Learning-app + Hoopclone 🛑 GATED
**Branch:** `chore/lfs-assets` (each repo) · **Why:** Learning-app carries 214 MB of mp3/png in history; Hoopclone ~40 MB (one texture committed twice, a `.png.jpeg` double-extension). Every clone/CI pays it forever.

🛑 **GATE (narrowed 2026-07-06): deep clean is pre-approved in principle.** Do the *additive* part freely; run the migrate-import prep; then STOP once — show the before/after size table and force-push command, and wait for a one-word "go":
- **Free (do now):** install Git LFS, `git lfs track` the asset globs, dedupe Hoopclone's doubled `crowd_panorama_dense.png`, rename `arena_backdrop.png.jpeg` → `.jpeg`. This fixes *new* commits.
- 🛑 **Gated:** purging existing large blobs from history needs `git lfs migrate import` (rewrites history, force-push, breaks existing clones). **Show me the before/after repo size and the exact command; wait for "go."** Solo repos, so blast radius is low — but it's my call.

**Done bar (additive):** new asset commits go to LFS; Hoopclone dupe gone, extension fixed. **Done bar (gated):** post-migration clone is <5 MB (Hoopclone) / dramatically smaller (Learning-app); CI still green.

---

## TASK 10 — Omni-3d / Sub-Scraper: test breadth (CONDITIONAL)
**Only if these are still active projects — check last-meaningful-commit first; if parked, SKIP and say so.**
- **Sub-Scraper:** cred hygiene is already a model (`.json` gitignored w/ allowlist, env secrets, fakes in tests). Only gap is breadth — one test file for 8.2k LOC. Add tests for the core scrape/normalize paths.
- **Omni-3d:** clean TS, RLS on all tables, 1 CI workflow, 0 tests. Add tests for the job-stage state machine if active.

**Done bar:** if active, meaningful tests green in CI; if parked, a one-line note saying so and why you skipped.

---

## WHAT I (KARIIM) MUST DECIDE OR DO — the irreducible manual steps
1. **Task 4 gate:** choose **Mirror (A)** or **Tombstone (B)** for the sync fix.
2. **Task 9 gate:** approve the **history rewrite / force-push** after seeing the size preview (or say "additive only, skip the purge").
3. **Task 8:** archive `Bball` in GitHub UI (or approve the `gh repo archive` command).
4. Anything needing GitHub **org-scoped auth** you don't hold — name it in one line and hand me the exact command.

Everything else: execute to done, one PR per task, CI green before merge. Report per task: what changed, Done-bar result, and the single most useful next step. Then stop.
