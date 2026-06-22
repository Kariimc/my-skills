# Imported Skills — Attribution

Skills adapted from upstream open-source repos. Frontmatter was normalized (name matched to folder, `when_to_use` folded into `description`) for auto-discovery; skill bodies are unmodified. Original licenses apply and are preserved (per-skill `LICENSE.txt` where provided).

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

## DietrichGebert/ponytail
- Source: https://github.com/DietrichGebert/ponytail
- License: see upstream
- Imported (6): `ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`,
  `ponytail-help`, `ponytail-review` — "keep the code simple" tools (YAGNI / laziest
  solution that works, with lite/full/ultra intensity).

> A plain-English walkthrough of the full ECC + ponytail batch lives in the
> repo-root `global-skills-guide.pdf`.

## Intentionally not imported
These are superpowers-plugin maintenance skills that only function inside that plugin's repo, so they were skipped:
- `sharing-skills` (obra/superpowers-skills)
- `gardening-skills-wiki` (obra/superpowers-skills)
- `pulling-updates-from-skills-repository` (obra/superpowers-skills)
