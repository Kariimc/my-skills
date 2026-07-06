# Portfolio Audit — All Repos
**Written by Claude Fable 5 · July 6, 2026 · pulled every repo by tarball, full source, no sampling.**
**Method: uniform triage (size, LOC, tests, CI, secrets, RLS), then depth only where risk was real. This is the "bank now, execute later" artifact for the whole account — Opus/Sonnet can act on any section after July 7.**

Companion files: `MY-SKILLS-AUDIT.md` (the true main repo) and `HOOPCLONE-AUDIT.md` (deep-dived earlier).

---

## 0. The one-screen verdict

| Repo | LOC | Tests | CI | Real state | Top action |
|---|---|---|---|---|---|
| **my-skills** | control plane | — | apex | Main repo. Sync-never-deletes + count drift. | See `MY-SKILLS-AUDIT.md` |
| **Just-a-pinch** | 13.5k | **0** | 3 | Shipping paid app, security mature, **untested** | Add tests around money + storage |
| **Sub-Scraper** | 8.2k | 1 file | 1 | Solid; good cred hygiene | Widen test coverage |
| **Hoopclone** | ~2k gd | good | 2 | Active, healthy | See `HOOPCLONE-AUDIT.md` |
| **Midnight-return-** | 13.8k | **0** | 0 | Real Unity codebase, no README, no tests | README + smoke tests |
| **Learning-app** | 5.4k | 8 | 2 | Healthy; 214 MB asset bloat | LFS the assets |
| **Faceless-Tech-youtube** | 2.2k | 8 | **0** | Well-tested pipeline, no CI | Add CI (tests already exist!) |
| **Omni-3d** | 4.5k | 0 | 1 | Clean TS + RLS | Tests if still active |
| **whome-diagnostic-tool** | 2.1k | 0 | 0 | Small utility | Proportionate — leave |
| **Bball** | 6.3k C# | 2 | 0 | **Superseded by Hoopclone** | Archive it |

**Security sweep result across all 9: clean.** No live secrets committed. The two scary-looking hits were both false alarms (details in §5). This is a genuinely good result — most portfolios this size leak something.

---

## 1. Just-a-pinch — the one that matters most (shipping + paid + zero tests)

**Why it's top priority:** it's the only repo taking money (Stripe + RevenueCat webhooks, AI-credit metering, a paywall) and it has **0 automated tests** across 13.5k LOC. Security is mature — RLS on every table, `auth.uid()`-scoped policies, a dedicated hardening migration that fixed earlier `USING (true)` bypasses, service_role confined to edge functions, anon key public-by-design. The risk here is **not security, it's correctness of the money and data paths**, and nothing guards them.

The three things a bug would hurt most, none tested:
1. **`consume_ai_credit` metering** — a decrement/race bug either gives away paid AI or double-charges. This is a pure SQL function → trivial to test with a Supabase test harness. Highest value test in the whole portfolio.
2. **`storage.ts` dual-write** (Supabase when signed-in, AsyncStorage always) — the offline/online merge is exactly where silent data-loss lives. Test the conflict path: edit offline, edit online, reconcile.
3. **The three webhooks** (stripe / revenuecat / delete-account) — signature verification and idempotency. A replayed webhook must not double-grant entitlement.

**Execute-later plan:** add Jest + a Supabase local test DB; write those three suites first (they're ~80% of the risk), wire into the existing Android CI. Don't chase 100% coverage — cover money and storage, stop. This is the single highest-leverage engineering task across every repo you own.

**Two smaller notes:** (a) the `backend/` Express server is dead code (CLAUDE.md says nothing points at it) — delete it, it's a second attack surface and a maintenance tax for zero benefit; (b) 57 `hf_*.png` design refs sit in repo root — move to `docs/refs/` or LFS, they bloat every clone.

---

## 2. Midnight-return- — real codebase flying blind

13.8k LOC of Unity/C# (HDRP Metroidvania), **no README, no tests, no CI.** The CLAUDE.md is strong (clear architecture, opinionated), but a human landing here has nothing — and Unity C# is the hardest stack to onboard cold. Two cheap, high-payoff moves: (1) generate a README from the CLAUDE.md + Assets structure (30 min of cheap-model work); (2) add EditMode tests around the combat/physics math — the deterministic systems that break silently when you refactor. No CI yet either; a single Unity-test workflow closes it.

---

## 3. Faceless-Tech-youtube — has tests, missing the one line that runs them

2.2k LOC, **8 test files already written**, and **no CI to run them.** This is the cheapest win in the portfolio: the tests exist and rot untested on every push. Add one `.github/workflows/ci.yml` (copy the pattern from Hoopclone's — same house style, pytest) and the safety net you already built starts actually catching things. ~15 minutes.

---

## 4. The rest — proportionate calls

- **Learning-app** — healthy (8 tests, 2 CI workflows). The only issue is **214 MB of assets** (mp3/png) in git history; every clone and CI run pays it. Git LFS migration, any quiet afternoon. Same fix Hoopclone needs — do them together.
- **Sub-Scraper** — the credential hygiene is a model: `*.json` gitignored with explicit `!railway.json` / `!.env.example` allowlist, secrets from env, tests use fakes. Only gap is breadth — one test file for 8.2k LOC. Widen if it's still active; otherwise leave.
- **Omni-3d** — clean TypeScript, RLS enabled on all tables, one CI workflow. No tests. Add them only if it's an active project (unclear from activity); don't invest in a parked repo.
- **whome-diagnostic-tool** — 2.1k-LOC single-purpose Windows utility. No tests, no CI — and that's **fine**. Proportionality rule: a throwaway fix-it tool doesn't need a test suite. Leave it. (Flagging explicitly so nobody "improves" it into over-engineering.)
- **Bball** — 6.3k LOC of C#, and it's the **abandoned predecessor to Hoopclone** (which moved to Godot/GDScript). It's not a project, it's history. Archive it on GitHub (or add a one-line README pointing at Hoopclone) so it stops looking like live code in your portfolio. Don't test it, don't touch it.

---

## 5. Security sweep — the two false alarms, documented so they're not re-flagged

1. **`hf_*.png` filenames in Just-a-pinch** look like `hf_` Higgsfield tokens. They're not — they're `hf_<timestamp>_<uuid>.png` image exports. Harmless. (Real HF-token hygiene is handled correctly in Neon-Forge: `token.txt` is gitignored with a "never commit this" comment.)
2. **Supabase `anon` key in `app.json`** — decodes to `"role":"anon"`; this key is *designed* to ship in the client and is safe **because** RLS is enabled and policies are `auth.uid()`-scoped. Verified across every migration. Not a leak. (If you ever see a `service_role` key client-side, that IS an emergency — but it's correctly server-only in all three edge functions.)

---

## 6. If you touch only three things (ranked)

1. **Just-a-pinch: test the AI-credit + webhook + storage paths.** Money and data, currently unguarded, on your only revenue app.
2. **Faceless-Tech-youtube: add CI.** The tests already exist — one file makes them real.
3. **Batch the LFS migrations** (Learning-app + Hoopclone) and **archive Bball.** Portfolio hygiene, one afternoon, stops the slow bleed.

Everything else is proportionate-to-leave or already covered in the two companion audits.
