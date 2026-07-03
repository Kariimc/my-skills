# Scaffolds — pre-decided starting points for recurring build types

Item #6 of the durable-leverage list: convert "smart model designs from
scratch" into "any model fills in blanks." Each row is a build type this user
actually recurs to, the fastest existing path, and the defaults already decided
— don't re-litigate them per project.

| Build type | Fastest existing path | Pre-decided defaults |
|---|---|---|
| Dark-mode React component/demo | `skills/neon-forge-ui` (4-file add flow) | React 19 + TanStack Start, Tailwind v4, motion/react; preview via `wrangler dev` after build, never `vite dev` (500s — see `C:/Dev/neon-forge-ui/ARCHITECTURE.md`) |
| Web artifact / small React app | `skills/web-artifacts-builder` — `scripts/init-artifact.sh` + bundled shadcn tarball | Vite + React + shadcn; single-file HTML output for sharing |
| Claude Code skill | `scaffolds/claude-skill/SKILL.md.template` + `skills/skill-creator`, ship via `skill-ship` | folder name == frontmatter `name`; description states the trigger ("Use when…"); body carries steps + worked example + output contract (see `skills/README-output-contracts.md`) |
| Claude Code subagent | copy an `agents/*.md` neighbor (e.g. `agents/docs-lookup.md`) | frontmatter description states when to auto-fire; smallest tool set that works |
| Python CLI/tool (incl. HF/gradio) | `scaffolds/python-tool/` | fast interpreter `C:/Users/karii/AppData/Local/Python/pythoncore-3.14-64/python.exe`; venv `Scripts\activate` (Windows); pin deps in requirements.txt; gotchas in `brain/wiki/hf-cli-and-gradio-setup.md` |
| Godot game | existing repo pattern `C:/Dev/hoopclone` | GitHub is source of truth; never gitignore `*.import` (see `brain/wiki/worked-examples.md` case 3) |
| Apex-gated repo (control-plane style) | clone `C:/Dev/my-skills` mechanics: `.githooks/` + `bin/apex-gates.sh` + `apex/GATES.md` | `core.hooksPath=.githooks`; gates: doctor/hooklint/secrets/selfintegrity/extra/live; ratchet mistakes via `bin/apex-ratchet.sh` |
| Eval / dataset for a workflow | `.claude/evals/README.md` convention + `datasets/harness-routing/` as the exemplar | rubric with threshold; runnable runner; deterministic graders gate, model graders report |

Rules: a scaffold is copy-ready or it doesn't belong here; defaults beat
options; if a build type recurs a third time without a row here, add one
(complexity-pays-rent applies to this table too).
