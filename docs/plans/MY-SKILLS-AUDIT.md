# my-skills — Control-Plane Audit
> Status note, 2026-07-14: historical July 6 plan/audit. Current live state is 419 skills and 67 agents on origin/master; old 416/68 or 411/67 counts below are preserved as historical evidence, not current truth.
**Written by Claude Fable 5 · July 6, 2026 · audited from `Kariimc/my-skills` @ HEAD (tarball, full tree)**
**This is the account's main repo: 416 skills, 68 agents, 6 rule files, 4 slash commands, the apex gate suite, and the SessionStart sync that every other repo depends on.**

---

## 1. Verdict up front

This repo is in better shape than most professional internal tooling. Every one of the 416 skills has valid frontmatter with `name:` matching its folder and a `description:` trigger — zero mismatches, zero missing. The secret scan is clean (one hit is a code *sample* inside `spotify-scraper`, not a live credential). The installer is idempotent with a Node→Python→pure-bash fallback chain and Windows path handling that shows real battle scars. PROGRESS.md is a genuinely excellent handoff document. The architecture — repo as source of truth, hook mirrors to `~/.claude/` — is the right shape.

Two real problems, both in the load-bearing sync path. Both are cheap to fix now and quietly corrosive if left.

---

## 2. Finding #1 — The sync never deletes: deleted skills become immortal zombies

`session-start.sh` syncs with `cp -r "$REPO/skills/." "$CLAUDE_DIR/skills/"` — **copy, never remove**. Commands and agents use the same pattern. Consequence: any skill you delete or rename in the repo **stays live in `~/.claude/skills/` forever**, still auto-triggering on its description line, on every machine, in every session. The repo stops being the source of truth the moment you remove anything — and the evidence says you do remove things: `rules/` numbering has gaps (00, 02, 03, 04, 05, 07 — no 01, no 06), so rules have been deleted. Rules are safe (CLAUDE.md is rebuilt from scratch each sync — correct). Skills, commands, and agents are not.

**Fix (one decision needed from you, then one small edit):**
- **Mirror semantics (recommended, matches your own README's "single source of truth" claim):** replace each `cp -r` with a delete-then-copy (or `rsync -a --delete` where available). Caveat named plainly: this erases any skill that exists *only* in `~/.claude/` and not in the repo — if any machine has hand-dropped local skills, they die on next session start. If that's a feature (it forces everything through the repo, which apex can then gate), take mirror.
- **Tombstone semantics (safer if local-only skills exist):** keep copy, add a `REMOVED.txt` manifest in the repo that the hook deletes by name.

Mirror is the correct call for a control plane; the upgrade path if it ever bites is the tombstone list. One-line risk: first mirror-sync on each machine should be run once manually so you see what it removes.

## 3. Finding #2 — Count drift, in the repo whose flagship feature is fixing count drift

Actual counts: **416 skills, 68 agents.** The README says **411** (twice) and **67**. The apex section of that same README advertises *"Self-healing: count/triage drift is auto-fixed before a commit can land."* The drift gate demonstrably does not cover the README's own numbers — five skills and one agent landed without the counts moving. Not cosmetic: this is the exact class of rot apex exists to prevent, in the most-read file in the repo, so it's a credibility hole in the gate suite.

**Fix:** extend the count gate (or add ratchet check #2 — `apex/checks/` currently holds exactly one check) to regenerate/verify the README counts from `ls skills | wc -l`. Better: stop hand-writing counts — have the gate substitute them into the README so drift is impossible. Also log it in `MISTAKE-LEDGER.md`; per your own ratchet rule, a mistake happens at most once.

---

## 4. Smaller findings, ranked

**4.1 — 416 always-on skills is approaching the trigger-collision ceiling.** Every description line loads into every session on every project; OVERLAP-REPORT.md already documents colliding triggers. No action now — the upgrade path, when misfires get annoying, is a two-tier split (core always-on / on-demand via `/name`), one hook change.

**4.2 — XAVIER scheduled task has never fired** (your own PROGRESS.md, item 22). Known, user-gated, unresolved. Restating because it's the only claimed automation in the plane with zero evidence of life.

**4.3 — `apex/checks/` has one check.** The ratchet story is sound but young; finding #2 above is its natural second entry.

**4.4 — Fragile-but-fine, leave alone:** async hook with 60 s timeout, ff-only `git pull` that can never block a session, README-skipping in commands sync — all correct; noted so nobody "improves" them.

---

## 5. What's solid (protect in review)

| Piece | Why it's right |
|---|---|
| Frontmatter discipline | 416/416 valid — this is what makes auto-triggering trustworthy |
| Rules → CLAUDE.md rebuild-from-zero | The one sync path with correct delete semantics; use it as the model for finding #1 |
| Installer fallback chain | Node → located node.exe → Python → pure-bash-if-no-settings; refuses to clobber an existing settings.json it can't parse safely |
| ff-only pull in the hook | A dirty clone can never wedge a session start |
| PROGRESS.md format | Where-we-are / scoreboard / user-gated / machine-gotchas is a handoff spec worth copying into every repo |

## 6. Execute-later plan (any model, post-July 7)

1. Decide mirror vs tombstone (§2) — only step that needs you.
2. Edit `session-start.sh`: apply delete semantics to skills/commands/agents. ~10 lines.
3. Add the README-count gate + ledger entry (§3). ~20 lines.
4. Run one manual sync per machine, eyeball the removals, commit.
Done bar: deleting a test skill from the repo removes it from `~/.claude/skills/` on next session start, and CI goes red if README counts drift.
