# Skills Catalog

107 skills, organized by domain. Each lives in `skills/<name>/SKILL.md` and is
auto-loaded into every project via the SessionStart sync hook (see the repo
root `README.md`). Claude invokes a skill automatically when your request
matches its `description` — you can also force one with `/<skill-name>`.

Counts: 52 original · 6 authored (engineering/game gaps) · 49 imported &
adapted from upstream repos (see [Imported skills](#imported-skills)).

---

## 🤖 AI & Agents
| Skill | What it does |
|---|---|
| `agent-swarm` | Multi-agent orchestration (CrewAI, AutoGen, LangGraph, Swarm) — routing, handoffs, shared memory, loop/cost control. |
| `ai-agent-developer` | Build single AI-agent tools — JSON tool schemas, few-shot prompts, RAG pipelines, agent-loop debugging. |
| `ai-vision` | Reverse-engineer UIs/architecture from images & video; OCR and multimodal extraction pipelines. |
| `skill-builder` | Turn any blueprint/ruleset into a standardized `SKILL.md` + automation script. |

## 🛠️ Software Engineering & Tooling
| Skill | What it does |
|---|---|
| `software-implementation` | SOLID, DDD, layered architecture, test suites, concurrency audits. |
| `debugger` | Root-cause analysis and clean fixes with beginner-friendly write-ups. |
| `test-engineer` | ⭐ Test strategy & TDD — pyramid, mocking, flake elimination, coverage. |
| `code-review` | ⭐ Rigorous diff/PR review — correctness, security, design, prioritized findings. |
| `performance-optimization` | ⭐ Profile & optimize CPU/GPU/memory/frame budget; kill jank. |
| `devops-cicd` | ⭐ CI/CD pipelines, Docker, deploy strategies, rollback, secrets. |
| `coding-notes` | Auto-generate/maintain README docs + "What Changed & Why" changelogs. |
| `token-saver` | Hyper-dense, zero-prose code output mode. |
| `sql-developer` | Write/optimize/debug SQL and schema design across major engines. |
| `backend-design` | Game/realtime backends — matchmaking, leaderboards, WebSockets, anti-cheat. |
| `api-integration` | Integrate free/open APIs — auth, rate limiting, async fetch pipelines. |
| `session-start-hook` | Build Claude Code SessionStart hooks for web/remote environments. |

## 🌐 Web & Frontend
| Skill | What it does |
|---|---|
| `web-implementation` | Build out web app features/frontends. |
| `web-deployment` | Ship web apps — build, deploy, release validation. |
| `web-scraper` | Robust web scraping pipelines. |
| `accessibility` | WCAG 2.2 AA/AAA, ARIA, keyboard nav, automated a11y CI testing. |

## 🎨 Design & Creative
| Skill | What it does |
|---|---|
| `ui-ux-design` | Design systems, tokens, accessible React/Tailwind components. |
| `graphic-design` | Brand identity, layout systems, typography, print export. |
| `color-specialist` | Color science, OKLCH/CIELAB palettes, WCAG contrast, theme tokens. |
| `mobile-app-design` | iOS/Android UX, design systems, SwiftUI/Compose handoff. |
| `anime-artist` | Copyright-safe manga/anime generative-art prompts + asset metadata. |
| `audio-engineer` | Mixing/mastering, DSP, audio repair, Python audio pipelines. |
| `photo-video-editing` | Color grading, NLE workflows, export configs (DaVinci/Premiere/AE). |

## 🎮 Game Development
| Skill | What it does |
|---|---|
| `game-design` | ⭐ Original systems design — core loops, economy/progression balancing, GDDs. |
| `multiplayer-netcode` | ⭐ Real-time netcode — authority, prediction/reconciliation, rollback, lag comp. |
| `game-art` | Concept/technical art bibles, asset specs, shader debugging, AI art prompts. |
| `game-assets` | 2D→3D pipeline: retopology, UV unwrap, PBR texturing (Unity/UE5). |
| `game-environment` | Backgrounds/environments — parallax, skyboxes, lighting, shaders. |
| `game-mechanics-sniffer` | Reverse-engineer & re-implement game mechanics. |
| `animation-particle-design` | Real-time VFX/particle sims, animation state machines (Niagara/VFX Graph). |
| `physics-destruction` | 2D rigid/soft body, Voronoi fracturing, destructible terrain. |
| `ar-vr-developer` | XR for visionOS/Quest/WebXR — hand tracking, spatial UI, frame budgets. |
| `video-to-game` | Convert video into game assets (animations, sprites, SFX, shaders, VFX). |
| `video-to-animation` | Convert video into game-ready animations / sprite sheets. |

## 📊 Data & Scraping
| Skill | What it does |
|---|---|
| `data-analysis` | KPI analysis, growth strategy, reporting dashboards. |
| `sports-scraper` | Sports stats/logos/photos via APIs + scraping (NBA/NFL/EPL/etc.). |
| `spotify-scraper` | Authenticate to Spotify and download personal library with metadata. |
| `music-manager` | PyQt6 desktop app aggregating Spotify/iTunes/local into one library. |

## 🔐 Security & Networking
| Skill | What it does |
|---|---|
| `cybersecurity` | AppSec reviews, OWASP Top 10, secure coding, hardening. |
| `network-engineer` | CCIE-level routing/switching, BGP/OSPF, vendor CLI configs. |
| `network-infrastructure` | Enterprise/multi-cloud networking, SD-WAN, ZTNA, automation. |
| `diagnostics-expert` | Packet capture, physical-layer/IoT diagnostics, serial debugging. |

## 📈 Marketing & Growth
| Skill | What it does |
|---|---|
| `digital-marketing` | Reverse-engineer funnels, ads, landing pages, email flows, A/B tests. |
| `game-marketing` | Game positioning, trailers, Steam pages, community/launch strategy. |
| `youtube-research` | YouTube research and analysis. |

## 🔬 Research & Analysis
| Skill | What it does |
|---|---|
| `osint-research` | Structured OSINT/academic research, source taxonomies, red-team audits. |
| `advanced-math` | Rigorous proofs, formal verification (Lean/Isabelle), counter-examples. |
| `financial-analyst` | CFA-level modeling — Black-Scholes, Fama-French, portfolio optimization. |

## 🏗️ Domain & Compliance
| Skill | What it does |
|---|---|
| `app-store-compliance` | Apple/Google/GDPR/CCPA audits + deployment-readiness checklists. |
| `cannabis-delivery-app` | NJ CRC-compliant cannabis delivery app architecture + METRC. |
| `cannabis-delivery-compliance` | Full NJ cannabis platform implementation (schema, middleware, POS sync, CI/CD). |
| `master-builder` | Construction/VDC/BIM — clash detection, scheduling, submittals. |
| `sneaker-aggregator` | Next.js sneaker-release aggregator (scraping, DB, calendar, UI). |
| `3d-printing` | DFAM, slicer tuning, defect troubleshooting, printer calibration. |

---

## Imported skills
Adapted from upstream open-source repos (frontmatter normalized; bodies intact). Full provenance + licenses in [`ATTRIBUTION.md`](./ATTRIBUTION.md).

### 📄 Anthropic official skills (17)
| Skill | What it does |
|---|---|
| `algorithmic-art` | Creating algorithmic art using p5.js with seeded randomness and interactive parameter e… |
| `brand-guidelines` | Applies Anthropic's official brand colors and typography to any sort of artifact that m… |
| `canvas-design` | Create beautiful visual art in .png and .pdf documents using design philosophy. You sho… |
| `claude-api` | Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, t… |
| `doc-coauthoring` | Guide users through a structured workflow for co-authoring documentation |
| `docx` | Use this skill whenever the user wants to create, read, edit, or manipulate Word docume… |
| `frontend-design` | Guidance for distinctive, intentional visual design when building new UI or reshaping a… |
| `internal-comms` | A set of resources to help me write all kinds of internal communications, using the for… |
| `mcp-builder` | Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs t… |
| `pdf` | Use this skill whenever the user wants to do anything with PDF files. This includes rea… |
| `pptx` | Use this skill any time a .pptx file is involved in any way — as input, output, or both… |
| `skill-creator` | Create new skills, modify and improve existing skills, and measure skill performance |
| `slack-gif-creator` | Knowledge and utilities for creating animated GIFs optimized for Slack. Provides constr… |
| `theme-factory` | Toolkit for styling artifacts with a theme. These artifacts can be slides, docs, report… |
| `web-artifacts-builder` | Suite of tools for creating elaborate, multi-component claude.ai HTML artifacts using m… |
| `webapp-testing` | Toolkit for interacting with and testing local web applications using Playwright. Suppo… |
| `xlsx` | Use this skill any time a spreadsheet file is the primary input or output. This means a… |

### 🧪 Superpowers — engineering workflow & thinking (28)
| Skill | What it does |
|---|---|
| `brainstorming` | Interactive idea refinement using Socratic method to develop fully-formed designs |
| `collision-zone-thinking` | Force unrelated concepts together to discover emergent properties - "What if we treated… |
| `condition-based-waiting` | Replace arbitrary timeouts with condition polling for reliable async tests |
| `defense-in-depth` | Validate at every layer data passes through to make bugs impossible |
| `dispatching-parallel-agents` | Use multiple Claude agents to investigate and fix independent problems concurrently |
| `executing-plans` | Execute detailed plans in batches with review checkpoints |
| `finishing-a-development-branch` | Complete feature development with structured options for merge, PR, or cleanup |
| `inversion-exercise` | Flip core assumptions to reveal hidden constraints and alternative approaches - "what i… |
| `meta-pattern-recognition` | Spot patterns appearing in 3+ domains to find universal principles |
| `preserving-productive-tensions` | Recognize when disagreements reveal valuable context, preserve multiple valid approache… |
| `receiving-code-review` | Receive and act on code review feedback with technical rigor, not performative agreemen… |
| `remembering-conversations` | Search previous Claude Code conversations for facts, patterns, decisions, and context u… |
| `requesting-code-review` | Dispatch code-reviewer subagent to review implementation against plan or requirements b… |
| `root-cause-tracing` | Systematically trace bugs backward through call stack to find original trigger |
| `scale-game` | Test at extremes (1000x bigger/smaller, instant/year-long) to expose fundamental truths… |
| `simplification-cascades` | Find one insight that eliminates multiple components - "if this is true, we don't need… |
| `subagent-driven-development` | Execute implementation plan by dispatching fresh subagent for each task, with code revi… |
| `systematic-debugging` | Four-phase debugging framework that ensures root cause investigation before attempting… |
| `test-driven-development` | Write the test first, watch it fail, write minimal code to pass |
| `testing-anti-patterns` | Never test mock behavior. Never add test-only methods to production classes. Understand… |
| `testing-skills-with-subagents` | RED-GREEN-REFACTOR for process documentation - baseline without skill, write addressing… |
| `tracing-knowledge-lineages` | Understand how ideas evolved over time to find old solutions for new problems and avoid… |
| `using-git-worktrees` | Create isolated git worktrees with smart directory selection and safety verification |
| `using-skills` | Skills wiki intro - mandatory workflows, search tool, brainstorming triggers |
| `verification-before-completion` | Run verification commands and confirm output before claiming success |
| `when-stuck` | Dispatch to the right problem-solving technique based on how you're stuck |
| `writing-plans` | Create detailed implementation plans with bite-sized tasks for engineers with zero code… |
| `writing-skills` | TDD for process documentation - test with subagents before writing, iterate until bulle… |

### 🔬 Superpowers Lab — experimental (4)
| Skill | What it does |
|---|---|
| `finding-duplicate-functions` | Use when auditing a codebase for semantic duplication - functions that do the same thin… |
| `mcp-cli` | Use MCP servers on-demand via the mcp CLI tool - discover tools, resources, and prompts… |
| `using-tmux-for-interactive-commands` | Use when you need to run interactive CLI tools (vim, git rebase -i, Python REPL, etc.)… |
| `windows-vm` | Create, manage, or connect to a headless Windows 11 VM running in Docker with SSH access |

## 🧩 Built-in (shipped with Claude Code, not files in this repo)
These are always available globally without living in `skills/` — listed here for reference only.
| Skill | What it does |
|---|---|
| `loop` | Run a prompt or slash command on a recurring interval (e.g. poll a deploy every 5m). |
| `launch-your-agent` (`Agent`) | Launch a sub-agent to handle complex, multi-step or parallel tasks. |

---

See [`OVERLAP-REPORT.md`](./OVERLAP-REPORT.md) for skills with colliding triggers
and recommended merges.
