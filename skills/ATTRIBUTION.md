# Imported Skills — Attribution

Skills adapted from upstream open-source repos. Frontmatter was normalized (name matched to folder, `when_to_use` folded into `description`) for auto-discovery; skill bodies are unmodified. Original licenses apply and are preserved (per-skill `LICENSE.txt` where provided).

## hardikpandya/stop-slop
- Source: https://github.com/hardikpandya/stop-slop
- Author: Hardik Pandya (https://hvpandya.com)
- License: MIT
- Imported (1): `stop-slop` — remove predictable AI writing patterns from prose. Skill body and `references/` (`phrases.md`, `structures.md`, `examples.md`) imported verbatim.

## anthropics/skills
- Source: https://github.com/anthropics/skills
- License: Anthropic (see THIRD_PARTY_NOTICES)
- Imported (17): `algorithmic-art`, `brand-guidelines`, `canvas-design`, `claude-api`, `doc-coauthoring`, `docx`, `frontend-design`, `internal-comms`, `mcp-builder`, `pdf`, `pptx`, `skill-creator`, `slack-gif-creator`, `theme-factory`, `web-artifacts-builder`, `webapp-testing`, `xlsx`

## obra/superpowers-skills
- Source: https://github.com/obra/superpowers-skills
- License: MIT (c) 2025 Jesse Vincent
- Imported (28): `brainstorming`, `collision-zone-thinking`, `condition-based-waiting`, `defense-in-depth`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `inversion-exercise`, `meta-pattern-recognition`, `preserving-productive-tensions`, `receiving-code-review`, `remembering-conversations`, `requesting-code-review`, `root-cause-tracing`, `scale-game`, `simplification-cascades`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `testing-anti-patterns`, `testing-skills-with-subagents`, `tracing-knowledge-lineages`, `using-git-worktrees`, `using-skills`, `verification-before-completion`, `when-stuck`, `writing-plans`, `writing-skills`

## obra/superpowers-lab
- Source: https://github.com/obra/superpowers-lab
- License: MIT (c) 2025 Jesse Vincent
- Imported (4): `finding-duplicate-functions`, `mcp-cli`, `using-tmux-for-interactive-commands`, `windows-vm`

## affaan-m/ECC
- Source: https://github.com/affaan-m/ECC
- License: MIT
- Imported (270): the large ECC engineering toolkit — backend/frontend stack patterns
  (`react-patterns`, `nextjs-turbopack`, `django-patterns`, `springboot-patterns`,
  `golang-patterns`, `rust-patterns`, …), testing (`*-testing`, `tdd-workflow`,
  `e2e-testing`), agent/LLM tooling (`agent-eval`, `eval-harness`, `autonomous-agent-harness`,
  `cost-aware-llm-pipeline`, …), data/infra (`clickhouse-io`, `postgres-patterns`,
  `kubernetes-patterns`, `docker-patterns`), security, ops, and domain packs
  (healthcare, ITO/markets, logistics, scientific DBs). ECC skills carry a
  `metadata.origin: ECC` tag in their frontmatter.
  - Also imported the 67 ECC specialist subagents into the repo-root [`agents/`](../agents/)
    folder (e.g. `code-reviewer`, language `*-reviewer` / `*-build-resolver`, `planner`,
    `security-reviewer`).
  - `accessibility` from ECC was **not** imported — the repo already ships a curated
    `accessibility` skill, which was kept.
- Heavier alternative: install ECC as a managed plugin instead of loose files —
  `claude plugin marketplace add affaan-m/ECC` then `claude plugin install ecc@ecc`.

## mvanhorn/last30days-skill
- Source: https://github.com/mvanhorn/last30days-skill
- Author: Matt Van Horn (https://github.com/mvanhorn)
- License: MIT (c) 2026 Matt Van Horn (preserved at `skills/last30days/LICENSE`)
- Imported (1): `last30days` — research what people said about any topic in the
  last 30 days across Reddit, X, YouTube, TikTok, Hacker News, Polymarket,
  GitHub, and the web. Vendored the **runtime subtree only** (`SKILL.md`,
  `scripts/` + `scripts/lib/**`, `references/`); pruned demo `assets/`, dev/eval
  scripts, tests, CI, and the Go MCP server per the upstream `.skillignore`.
  Optional API keys widen source coverage; runs keyless via web search otherwise.
- Paired with `skill-scout` + `skill-ship` by the authored `skill-radar`
  discovery kit.

## DietrichGebert/ponytail
- Source: https://github.com/DietrichGebert/ponytail
- License: see upstream
- Imported (6): `ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`,
  `ponytail-help`, `ponytail-review` — "keep the code simple" tools (YAGNI / laziest
  solution that works, with lite/full/ultra intensity).

> A plain-English walkthrough of the full ECC + ponytail batch lives in the
> repo-root `global-skills-guide.pdf`.

## Forward-Future/loopy
- Source: https://github.com/Forward-Future/loopy
- Author: Forward Future (Matthew Berman) — https://signals.forwardfuture.com/loop-library/
- License: MIT (c) 2026 Forward Future (see `skills/loopy/LICENSE.txt`)
- Imported (1): `loopy` — discover, find, audit, adapt, craft, run, debrief, save, and
  publish repeatable AI-agent loops so the right bounded loop can be picked per project.
  Skill body and `references/` (`discover.md`, `audit.md`, `run.md`, `debrief.md`,
  `publish.md`) imported verbatim.

## Intentionally not imported
These are superpowers-plugin maintenance skills that only function inside that plugin's repo, so they were skipped:
- `sharing-skills` (obra/superpowers-skills)
- `gardening-skills-wiki` (obra/superpowers-skills)
- `pulling-updates-from-skills-repository` (obra/superpowers-skills)
