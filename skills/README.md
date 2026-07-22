# Skills Catalog

419 skills, organized by domain. Each lives in `skills/<name>/SKILL.md` and is
auto-loaded into every project via the SessionStart sync hook (see the repo
root `README.md`). Claude invokes a skill automatically when your request
matches its `description` — you can also force one with `/<skill-name>`.

Counts: 52 original · 6 authored (engineering/game gaps) · 49 imported &
adapted from upstream repos (see [Imported skills](#imported-skills)) · 276
imported in the ECC + ponytail batch (see [Imported batch](#-imported-batch--ecc--ponytail))
· plus later one-off additions (advisor, codebase-memory, neon-forge-ui, windows-env-repair, loopy, …).

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
| `plain-language` | Opposite of token-saver — explain anything in plain, jargon-free words with everyday comparisons, defining terms on the spot. |
| `stop-slop` | Strip predictable "AI tells" from prose — filler openers, jargon, adverbs, binary contrasts, passive voice; with before/after examples and a 50-pt score. |
| `sql-developer` | Write/optimize/debug SQL and schema design across major engines. |
| `backend-design` | Game/realtime backends — matchmaking, leaderboards, WebSockets, anti-cheat. |
| `api-integration` | Integrate free/open APIs — auth, rate limiting, async fetch pipelines. |
| `session-start-hook` | Build Claude Code SessionStart hooks for web/remote environments. |
| `codebase-memory` | Query the codebase knowledge graph (callers, call chains, impact analysis, dead code) via the codebase-memory MCP tools. |
| `windows-env-repair` | Repair a broken Windows dev environment — OneDrive-redirected folders, lost project paths, broken git links, config drift. |

## 🌐 Web & Frontend
| Skill | What it does |
|---|---|
| `web-implementation` | Build out web app features/frontends. |
| `web-deployment` | Ship web apps — build, deploy, release validation. |
| `web-scraper` | Robust web scraping pipelines. |
| `accessibility` | WCAG 2.2 AA/AAA, ARIA, keyboard nav, automated a11y CI testing. |
| `visual-prototype` | High-fidelity single-file interactive UI mockups with a built-in "Tweak & Comment" review overlay (click-to-pin feedback, markdown export). |
| `neon-forge-ui` | Expert agent for the Neon Forge UI library (React 19 + TanStack Start + Tailwind v4 dark-mode component workbench) — add components, preview, deploy. |

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

---

## 📦 Imported batch — ECC + ponytail

276 skills imported from upstream toolkits (see [`ATTRIBUTION.md`](./ATTRIBUTION.md) and the repo-root `global-skills-guide.pdf`). ECC skills carry a `metadata.origin: ECC` tag.

### ponytail — keep-it-simple tools
| Skill | What it does |
|---|---|
| `ponytail` | Forces the laziest solution that actually works, simplest, shortest, most minimal. Channels a senior dev who has seen everything: questio… |
| `ponytail-audit` | Whole-repo audit for over-engineering. Like ponytail-review, but scans the entire codebase instead of a diff: a ranked list of what to de… |
| `ponytail-debt` | Harvest every `ponytail:` comment in the codebase into a debt ledger, so the deliberate shortcuts and deferrals ponytail leaves behind ge… |
| `ponytail-gain` | Show ponytail's measured impact as a compact scoreboard: less code, less cost, more speed, from the benchmark medians. One-shot display,… |
| `ponytail-help` | Quick-reference card for all ponytail modes, skills, and commands. One-shot display, not a persistent mode. Trigger: /ponytail-help, "pon… |
| `ponytail-review` | Code review focused exclusively on over-engineering. Finds what to delete: reinvented standard library, unneeded dependencies, speculativ… |

### ECC engineering toolkit (270)
| Skill | What it does |
|---|---|
| `agent-architecture-audit` | Full-stack diagnostic for agent and LLM applications. Audits the 12-layer agent stack for wrapper regression, memory pollution, tool disc… |
| `agent-eval` | Head-to-head comparison of coding agents (Claude Code, Aider, Codex, etc.) on custom tasks with pass rate, cost, time, and consistency me… |
| `agent-harness-construction` | Design and optimize AI agent action spaces, tool definitions, and observation formatting for higher completion rates |
| `agent-introspection-debugging` | Structured self-debugging workflow for AI agent failures using capture, diagnosis, contained recovery, and introspection reports |
| `agent-payment-x402` | Add x402 payment execution to AI agents with per-task budgets, spending controls, and non-custodial wallets. Supports Base through agentw… |
| `agent-self-evaluation` | Use after completing any non-trivial task. The agent self-rates its output on 5 axes — accuracy, completeness, clarity, actionability, co… |
| `agent-sort` | Build an evidence-backed ECC install plan for a specific repo by sorting skills, commands, rules, hooks, and extras into DAILY vs LIBRARY… |
| `agentic-engineering` | Operate as an agentic engineer using eval-first execution, decomposition, and cost-aware model routing |
| `agentic-os` | Build persistent multi-agent operating systems on Claude Code. Covers kernel architecture, specialist agents, slash commands, file-based… |
| `ai-first-engineering` | Engineering operating model for teams where AI agents generate a large share of implementation output |
| `ai-regression-testing` | Regression testing strategies for AI-assisted development. Sandbox-mode API testing without database dependencies, automated bug-check wo… |
| `android-clean-architecture` | Clean Architecture patterns for Android and Kotlin Multiplatform projects — module structure, dependency rules, UseCases, Repositories, a… |
| `angular-developer` | Generates Angular code and provides architectural guidance. Trigger when creating projects, components, or services, or for best practice… |
| `api-connector-builder` | Build a new API connector or provider by matching the target repo's existing integration pattern exactly |
| `api-design` | REST API design patterns including resource naming, status codes, pagination, filtering, error responses, versioning, and rate limiting f… |
| `architecture-decision-records` | Capture architectural decisions made during Claude Code sessions as structured ADRs. Auto-detects decision moments, records context, alte… |
| `article-writing` | Write articles, guides, blog posts, tutorials, newsletter issues, and other long-form content in a distinctive voice derived from supplie… |
| `automation-audit-ops` | Evidence-first automation inventory and overlap audit workflow for ECC |
| `autonomous-agent-harness` | Transform Claude Code into a fully autonomous agent system with persistent memory, scheduled operations, computer use, and task queuing.… |
| `backend-patterns` | Backend architecture patterns, API design, database optimization, and server-side best practices for Node.js, Express, and Next.js API ro… |
| `benchmark` |  |
| `benchmark-methodology` | Use after competitive-platform-analysis has produced a tiered competitor set. Scores each competitor across nine weighted dimensions (pos… |
| `benchmark-optimization-loop` |  |
| `blender-motion-state-inspection` |  |
| `blueprint` | Turn a one-line objective into a step-by-step construction plan for multi-session, multi-agent engineering projects. Each step has a self… |
| `brand-discovery` |  |
| `brand-voice` | Build a source-derived writing style profile from real posts, essays, launch notes, docs, or site copy, then reuse that profile across co… |
| `browser-qa` |  |
| `bun-runtime` | Bun as runtime, package manager, bundler, and test runner. When to choose Bun vs Node, migration notes, and Vercel support |
| `canary-watch` |  |
| `carrier-relationship-management` | Codified expertise for managing carrier portfolios, negotiating freight rates, tracking carrier performance, allocating freight, and main… |
| `cisco-ios-patterns` | Cisco IOS and IOS-XE review patterns for show commands, config hierarchy, wildcard masks, ACL placement, interface hygiene, and safe chan… |
| `ck` | Persistent per-project memory for Claude Code. Auto-loads project context on session start, tracks sessions with git activity, and writes… |
| `claude-devfleet` | Orchestrate multi-agent coding tasks via Claude DevFleet — plan projects, dispatch parallel agents in isolated worktrees, monitor progres… |
| `click-path-audit` | "Trace every user-facing button/touchpoint through its full state change sequence to find bugs where functions individually work but canc… |
| `clickhouse-io` | ClickHouse database patterns, query optimization, analytics, and data engineering best practices for high-performance analytical workloads |
| `code-tour` | Create CodeTour `.tour` files — persona-targeted, step-by-step walkthroughs with real file and line anchors. Use for onboarding tours, ar… |
| `codebase-onboarding` | Analyze an unfamiliar codebase and generate a structured onboarding guide with architecture map, key entry points, conventions, and a sta… |
| `codehealth-mcp` | Real-time structural Code Health via CodeScene MCP — review before edits, verify score deltas after changes, gate commits and PRs |
| `coding-standards` | Baseline cross-project coding conventions for naming, readability, immutability, and code-quality review. Use detailed frontend or backen… |
| `competitive-platform-analysis` |  |
| `competitive-report-structure` | Use after benchmark-methodology has produced scored competitor profile cards. Assembles findings into a decision-grade report: landscape… |
| `compose-multiplatform-patterns` | Compose Multiplatform and Jetpack Compose patterns for KMP projects — state management, navigation, theming, performance, and platform-sp… |
| `config-gc` | Garbage collection for your Claude Code configuration. Periodically scans ~/.claude (skills, memory, hooks, permissions, MCP servers, cac… |
| `configure-ecc` | Interactive installer for Everything Claude Code — guides users through selecting and installing skills and rules to user-level or projec… |
| `connections-optimizer` | Reorganize the user's X and LinkedIn network with review-first pruning, add/follow recommendations, and channel-specific warm outreach dr… |
| `content-engine` | Create platform-native content systems for X, LinkedIn, TikTok, YouTube, newsletters, and repurposed multi-platform campaigns |
| `content-hash-cache-pattern` | Cache expensive file processing results using SHA-256 content hashes — path-independent, auto-invalidating, with service layer separation |
| `context-budget` | Audits Claude Code context window consumption across agents, skills, MCP servers, and rules. Identifies bloat, redundant components, and… |
| `continuous-agent-loop` | Patterns for continuous autonomous agent loops with quality gates, evals, and recovery controls |
| `continuous-learning` | "[DEPRECATED - use continuous-learning-v2] Legacy v1 stop-hook skill extractor. v2 is a strict superset with instinct-based, project-scop… |
| `continuous-learning-v2` | Instinct-based learning system that observes sessions via hooks, creates atomic instincts with confidence scoring, and evolves them into… |
| `cost-aware-llm-pipeline` | Cost optimization patterns for LLM API usage — model routing by task complexity, budget tracking, retry logic, and prompt caching |
| `cost-tracking` | Track and report Claude Code token usage, spending, and budgets from the local ECC cost-tracker metrics log |
| `council` | Convene a four-voice council for ambiguous decisions, tradeoffs, and go/no-go calls |
| `council-moa` | Mixture-of-agents council — advisors propose through distinct lenses, debate, an Arbiter synthesizes one decision, an adversary verifies it (CLI + dashboard) |
| `cpp-coding-standards` | C++ coding standards based on the C++ Core Guidelines (isocpp.github.io) |
| `cpp-testing` | Use only when writing/updating/fixing C++ tests, configuring GoogleTest/CTest, diagnosing failing or flaky tests, or adding coverage/sani… |
| `crosspost` | Multi-platform content distribution across X, LinkedIn, Threads, and Bluesky. Adapts content per platform using content-engine patterns.… |
| `csharp-testing` | C# and .NET testing patterns with xUnit, FluentAssertions, mocking, integration tests, and test organization best practices |
| `customer-billing-ops` | Operate customer billing workflows such as subscriptions, refunds, churn triage, billing-portal recovery, and plan analysis using connect… |
| `customs-trade-compliance` | Codified expertise for customs documentation, tariff classification, duty optimization, restricted party screening, and regulatory compli… |
| `dart-flutter-patterns` | Production-ready Dart and Flutter patterns covering null safety, immutable state, async composition, widget architecture, popular state m… |
| `dashboard-builder` | Build monitoring dashboards that answer real operator questions for Grafana, SigNoz, and similar platforms |
| `data-scraper-agent` | Build a fully automated AI-powered data collection agent for any public source — job boards, prices, news, GitHub, sports, anything. Scra… |
| `data-throughput-accelerator` |  |
| `database-migrations` | Database migration best practices for schema changes, data migrations, rollbacks, and zero-downtime deployments across PostgreSQL, MySQL,… |
| `deep-research` | Multi-source deep research using firecrawl and exa MCPs. Searches the web, synthesizes findings, and delivers cited reports with source a… |
| `defi-amm-security` | Security checklist for Solidity AMM contracts, liquidity pools, and swap flows. Covers reentrancy, CEI ordering, donation or inflation at… |
| `deployment-patterns` | Deployment workflows, CI/CD pipeline patterns, Docker containerization, health checks, rollback strategies, and production readiness chec… |
| `design-system` |  |
| `django-celery` | Django + Celery async task patterns — configuration, task design, beat scheduling, retries, canvas workflows, monitoring, and testing |
| `django-patterns` | Django architecture patterns, REST API design with DRF, ORM best practices, caching, signals, middleware, and production-grade Django apps |
| `django-security` | Django security best practices, authentication, authorization, CSRF protection, SQL injection prevention, XSS prevention, and secure depl… |
| `django-tdd` | Django testing strategies with pytest-django, TDD methodology, factory_boy, mocking, coverage, and testing Django REST Framework APIs |
| `django-verification` | "Verification loop for Django projects: migrations, linting, tests with coverage, security scans, and deployment readiness checks before… |
| `dmux-workflows` | Multi-agent orchestration using dmux (tmux pane manager for AI agents). Patterns for parallel agent workflows across Claude Code, Codex,… |
| `docker-patterns` | Docker and Docker Compose patterns for local development, container security, networking, volume strategies, and multi-service orchestration |
| `documentation-lookup` | Use up-to-date library and framework docs via Context7 MCP instead of training data. Activates for setup questions, API references, code… |
| `dotnet-patterns` | Idiomatic C# and .NET patterns, conventions, dependency injection, async/await, and best practices for building robust, maintainable .NET… |
| `dynamic-workflow-mode` | "Design task-local harnesses, eval gates, and reusable skill extraction for Claude dynamic workflow mode and other adaptive agent harness… |
| `e2e-testing` | Playwright E2E testing patterns, Page Object Model, configuration, CI/CD integration, artifact management, and flaky test strategies |
| `ecc-guide` | Guide users through ECC's current agents, skills, commands, hooks, rules, install profiles, and project onboarding by reading the live re… |
| `ecc-tools-cost-audit` | Evidence-first ECC Tools burn and billing audit workflow |
| `email-ops` | Evidence-first mailbox triage, drafting, send verification, and sent-mail-safe follow-up workflow for ECC |
| `energy-procurement` | Codified expertise for electricity and gas procurement, tariff optimization, demand charge management, renewable PPA evaluation, and mult… |
| `enterprise-agent-ops` | Operate long-lived agent workloads with observability, security boundaries, and lifecycle management |
| `error-handling` | Patterns for robust error handling across TypeScript, Python, and Go. Covers typed errors, error boundaries, retries, circuit breakers, a… |
| `eval-harness` | Formal evaluation framework for Claude Code sessions implementing eval-driven development (EDD) principles |
| `evm-token-decimals` | Prevent silent decimal mismatch bugs across EVM chains. Covers runtime decimal lookup, chain-aware caching, bridged-token precision drift… |
| `exa-search` | Neural search via Exa MCP for web, code, and company research |
| `fal-ai-media` | Unified media generation via fal.ai MCP — image, video, and audio. Covers text-to-image (Nano Banana), text/image-to-video (Seedance, Kli… |
| `fastapi-patterns` | FastAPI best practices covering project structure, Pydantic v2 schemas, dependency injection, async handlers, authentication, authorizati… |
| `finance-billing-ops` | Evidence-first revenue, pricing, refunds, team-billing, and billing-model truth workflow for ECC |
| `flox-environments` | "Create reproducible, cross-platform (macOS/Linux) development environments with Flox, a declarative Nix-based environment manager |
| `flutter-dart-code-review` | Library-agnostic Flutter/Dart code review checklist covering widget best practices, state management patterns (BLoC, Riverpod, Provider,… |
| `foundation-models-on-device` | Apple FoundationModels framework for on-device LLM — text generation, guided generation with @Generable, tool calling, and snapshot strea… |
| `frontend-a11y` | Accessibility patterns for React and Next.js — semantic HTML, ARIA attributes, form labeling, keyboard navigation, focus management, and… |
| `frontend-design-direction` | Set an ECC-specific frontend design direction for production UI work |
| `frontend-patterns` | Frontend development patterns for React, Next.js, state management, performance optimization, and UI best practices |
| `frontend-slides` | Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files |
| `fsharp-testing` | F# testing patterns with xUnit, FsUnit, Unquote, FsCheck property-based testing, integration tests, and test organization best practices |
| `gan-style-harness` | "GAN-inspired Generator-Evaluator agent harness for building high-quality applications autonomously. Based on Anthropic's March 2026 harn… |
| `gateguard` | Fact-forcing gate that blocks Edit/Write/Bash (including MultiEdit) and demands concrete investigation (importers, data schemas, user ins… |
| `generating-python-installer` | "Commercial-grade Python installer expert for Windows: Nuitka extreme compilation, dist slimming, DLL footprint analysis, and Inno Setup… |
| `git-workflow` | Git workflow patterns including branching strategies, commit conventions, merge vs rebase, conflict resolution, and collaborative develop… |
| `github-ops` | GitHub repository operations, automation, and management. Issue triage, PR management, CI/CD operations, release management, and security… |
| `golang-patterns` | Idiomatic Go patterns, best practices, and conventions for building robust, efficient, and maintainable Go applications |
| `golang-testing` | Go testing patterns including table-driven tests, subtests, benchmarks, fuzzing, and test coverage. Follows TDD methodology with idiomati… |
| `google-workspace-ops` | Operate across Google Drive, Docs, Sheets, and Slides as one workflow surface for plans, trackers, decks, and shared documents |
| `healthcare-cdss-patterns` | Clinical Decision Support System (CDSS) development patterns. Drug interaction checking, dose validation, clinical scoring (NEWS2, qSOFA)… |
| `healthcare-emr-patterns` | EMR/EHR development patterns for healthcare applications. Clinical safety, encounter workflows, prescription generation, clinical decisio… |
| `healthcare-eval-harness` | Patient safety evaluation harness for healthcare application deployments. Automated test suites for CDSS accuracy, PHI exposure, clinical… |
| `healthcare-phi-compliance` | Protected Health Information (PHI) and Personally Identifiable Information (PII) compliance patterns for healthcare applications. Covers… |
| `hermes-imports` | Convert local Hermes operator workflows into sanitized ECC skills and release-pack artifacts |
| `hexagonal-architecture` | Design, implement, and refactor Ports & Adapters systems with clear domain boundaries, dependency inversion, and testable use-case orches… |
| `hipaa-compliance` | HIPAA-specific entrypoint for healthcare privacy and security work |
| `homelab-network-readiness` | Readiness checklist for homelab VLAN segmentation, local DNS filtering, and WireGuard-style remote access before changing router, firewal… |
| `homelab-network-setup` | Practical home and homelab network planning for gateways, switches, access points, IP ranges, DHCP reservations, DNS, cabling, and common… |
| `homelab-pihole-dns` | Pi-hole installation, blocklist management, DNS-over-HTTPS setup, DHCP integration, local DNS records, and troubleshooting broken DNS res… |
| `homelab-vlan-segmentation` | Segmenting home networks into VLANs for IoT, guest, trusted, and server traffic using UniFi, pfSense/OPNsense, and MikroTik — including s… |
| `homelab-wireguard-vpn` | WireGuard VPN server setup, peer configuration, key generation, split tunneling vs full tunnel routing, and remote access to a home netwo… |
| `hookify-rules` | This skill should be used when the user asks to create a hookify rule, write a hook rule, configure hookify, add a hookify rule, or needs… |
| `inherit-legacy-style` | Legacy-project style inheritance skill |
| `intent-driven-development` | Turn ambiguous or high-impact product and engineering changes into scoped, verifiable acceptance criteria before or alongside implementation |
| `inventory-demand-planning` | Codified expertise for demand forecasting, safety stock optimization, replenishment planning, and promotional lift estimation at multi-lo… |
| `investor-materials` | Create and update pitch decks, one-pagers, investor memos, accelerator applications, financial models, and fundraising materials |
| `investor-outreach` | Draft cold emails, warm intro blurbs, follow-ups, update emails, and investor communications for fundraising |
| `ios-icon-gen` | Generate iOS app icons as PNG imagesets for Xcode asset catalogs from SF Symbols (5000+ Apple-native) or Iconify API (275k+ open source i… |
| `iterative-retrieval` | Pattern for progressively refining context retrieval to solve the subagent context problem |
| `ito-basket-compare` | Compare Itô prediction-market baskets against a user's knowledge base, portfolio notes, financial context, watchlist, or research thesis.… |
| `ito-data-atlas-agent` | Design background Data Atlas style agents for Itô basket research, market discovery, parameter drafting, and human-in-the-loop editing. U… |
| `ito-market-intelligence` | Research prediction-market events, venues, underliers, liquidity, and news context for Itô basket workflows. Use for read-only market int… |
| `ito-trade-planner` | Build a non-advisory prediction-market trade planning worksheet for Itô or venue workflows. Use to inspect venues, underliers, constraint… |
| `java-coding-standards` | "Java coding standards for Spring Boot and Quarkus services: naming, immutability, Optional usage, streams, exceptions, generics, CDI, re… |
| `jira-integration` |  |
| `jpa-patterns` | JPA/Hibernate patterns for entity design, relationships, query optimization, transactions, auditing, indexing, pagination, and pooling in… |
| `knowledge-ops` | Knowledge base management, ingestion, sync, and retrieval across multiple storage layers (local files, MCP memory, vector stores, Git repos) |
| `kotlin-coroutines-flows` | Kotlin Coroutines and Flow patterns for Android and KMP — structured concurrency, Flow operators, StateFlow, error handling, and testing |
| `kotlin-exposed-patterns` | JetBrains Exposed ORM patterns including DSL queries, DAO pattern, transactions, HikariCP connection pooling, Flyway migrations, and repo… |
| `kotlin-ktor-patterns` | Ktor server patterns including routing DSL, plugins, authentication, Koin DI, kotlinx.serialization, WebSockets, and testApplication testing |
| `kotlin-patterns` | Idiomatic Kotlin patterns, best practices, and conventions for building robust, efficient, and maintainable Kotlin applications with coro… |
| `kotlin-testing` | Kotlin testing patterns with Kotest, MockK, coroutine testing, property-based testing, and Kover coverage. Follows TDD methodology with i… |
| `kubernetes-patterns` | Kubernetes workload patterns, resource management, RBAC, probes, autoscaling, ConfigMap/Secret handling, and kubectl debugging for produc… |
| `laravel-patterns` | Laravel architecture patterns, routing/controllers, Eloquent ORM, service layers, queues, events, caching, and API resources for producti… |
| `laravel-plugin-discovery` | Discover and evaluate Laravel packages via LaraPlugins.io MCP |
| `laravel-security` | Laravel security best practices — authentication, authorization, Eloquent safety, CSRF, XSS prevention, API security, and secure deployme… |
| `laravel-tdd` | Laravel testing strategies with PHPUnit, Pest, model factories, HTTP tests, Sanctum authentication testing, mocking, and coverage |
| `laravel-verification` | "Verification loop for Laravel projects: env checks, linting, static analysis, tests with coverage, security scans, and deployment readin… |
| `latency-critical-systems` | Use for latency-sensitive systems such as realtime dashboards, market data, streaming agents, execution gateways, queues, caches, or HFT-… |
| `lead-intelligence` | AI-native lead intelligence and outreach pipeline. Replaces Apollo, Clay, and ZoomInfo with agent-powered signal scoring, mutual ranking,… |
| `liquid-glass-design` | iOS 26 Liquid Glass design system — dynamic glass material with blur, reflection, and interactive morphing for SwiftUI, UIKit, and WidgetKit |
| `llm-trading-agent-security` | Security patterns for autonomous trading agents with wallet or transaction authority. Covers prompt injection, spend limits, pre-send sim… |
| `logistics-exception-management` | Codified expertise for handling freight exceptions, shipment delays, damages, losses, and carrier disputes. Informed by logistics profess… |
| `make-interfaces-feel-better` | Apply concrete design-engineering details that make interfaces feel polished |
| `manim-video` | Build reusable Manim explainers for technical concepts, graphs, system diagrams, and product walkthroughs, then hand off to the wider ECC… |
| `market-research` | Conduct market research, competitive analysis, investor due diligence, and industry intelligence with source attribution and decision-ori… |
| `marketing-campaign` | End-to-end marketing campaign planning and execution. Covers audience research, positioning, campaign angle definition, landing page copy… |
| `mcp-server-patterns` | Build MCP servers with Node/TypeScript SDK — tools, resources, prompts, Zod validation, stdio vs Streamable HTTP. Use Context7 or officia… |
| `messages-ops` | Evidence-first live messaging workflow for ECC |
| `ml-adoption-playbook` | End-to-end methodology for AI agents and software engineers to add machine learning algorithms to existing non-ML codebases. Covers probl… |
| `mle-workflow` | Production machine-learning engineering workflow for data contracts, reproducible training, model evaluation, deployment, monitoring, and… |
| `motion-advanced` | Advanced motion patterns for React / Next.js — drag & drop, gestures, text animations, SVG path drawing, custom hooks, imperative sequenc… |
| `motion-foundations` | Motion tokens, spring presets, performance rules, device adaptation, accessibility enforcement, and SSR safety for React / Next.js using… |
| `motion-patterns` | Production-ready animation patterns for React / Next.js — button, modal, toast, stagger, page transitions, exit animations, scroll, and l… |
| `mysql-patterns` | MySQL and MariaDB schema, query, indexing, transaction, replication, and connection-pool patterns for production backends |
| `nanoclaw-repl` | Operate and extend NanoClaw v2, ECC's zero-dependency session-aware REPL built on claude -p |
| `nestjs-patterns` | NestJS architecture patterns for modules, controllers, providers, DTO validation, guards, interceptors, config, and production-grade Type… |
| `netmiko-ssh-automation` | Safe Python Netmiko patterns for read-only collection, bounded batch SSH, TextFSM parsing, guarded config changes, timeouts, and network… |
| `network-bgp-diagnostics` | Diagnostics-only BGP troubleshooting patterns for neighbor state, route exchange, prefix policy, AS path inspection, and safe evidence co… |
| `network-config-validation` | Pre-deployment checks for router and switch configuration, including dangerous commands, duplicate addresses, subnet overlaps, stale refe… |
| `network-interface-health` | Diagnose interface errors, drops, CRCs, duplex mismatches, flapping, speed negotiation issues, and counter trends on routers, switches, a… |
| `nextjs-turbopack` | Next.js 16+ and Turbopack — incremental bundling, FS caching, dev speed, and when to use Turbopack vs webpack |
| `nodejs-keccak256` | Prevent Ethereum hashing bugs in JavaScript and TypeScript. Node's sha3-256 is NIST SHA3, not Ethereum Keccak-256, and silently breaks se… |
| `nutrient-document-processing` | Process, convert, OCR, extract, redact, sign, and fill documents using the Nutrient DWS API. Works with PDFs, DOCX, XLSX, PPTX, HTML, and… |
| `nuxt4-patterns` | Nuxt 4 app patterns for hydration safety, performance, route rules, lazy loading, and SSR-safe data fetching with useFetch and useAsyncData |
| `openclaw-persona-forge` | "为 OpenClaw AI Agent 锻造完整的龙虾灵魂方案。根据用户偏好或随机抽卡， 输出身份定位、灵魂描述(SOUL.md)、角色化底线规则、名字和头像生图提示词。 如当前环境提供已审核的生图 skill，可自动生成统一风格头像图片。 当用户需要创建、设计或定制 O… |
| `opensource-pipeline` | "Open-source pipeline: fork, sanitize, and package private projects for safe public release. Chains 3 agents (forker, sanitizer, packager… |
| `orch-add-feature` | Orchestrate building a brand-new feature end to end — research, plan, TDD implementation, review, and gated commit — by delegating each p… |
| `orch-build-mvp` | Orchestrate bootstrapping a working MVP from a design or spec document — ingest the doc, plan thin vertical slices, scaffold the first en… |
| `orch-change-feature` | Orchestrate altering an existing, working feature to new desired behavior — update its tests to the new spec, change the implementation t… |
| `orch-fix-defect` | Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, and gated commit — by delegating each phase t… |
| `orch-pipeline` | Shared orchestration engine for the orch-* skill family. Defines the gated Research-Plan-TDD-Review-Commit pipeline, the size classifier,… |
| `orch-refine-code` | Orchestrate a behavior-preserving refactor — confirm tests are green, restructure without changing behavior, keep tests green, review, an… |
| `parallel-execution-optimizer` |  |
| `perl-patterns` | Modern Perl 5.36+ idioms, best practices, and conventions for building robust, maintainable Perl applications |
| `perl-security` | Comprehensive Perl security covering taint mode, input validation, safe process execution, DBI parameterized queries, web security (XSS/S… |
| `perl-testing` | Perl testing patterns using Test2::V0, Test::More, prove runner, mocking, coverage with Devel::Cover, and TDD methodology |
| `plan-orchestrate` | Read a plan document, decompose it into steps, design a per-step agent chain from the ECC catalogue, and emit ready-to-paste /orchestrate… |
| `plankton-code-quality` | "Write-time code quality enforcement using Plankton — auto-formatting, linting, and Claude-powered fixes on every file edit via hooks." |
| `postgres-patterns` | PostgreSQL database patterns for query optimization, schema design, indexing, and security. Based on Supabase best practices |
| `prediction-market-oracle-research` | Research prediction markets as data sources or oracle signals for products, agents, dashboards, and corporate decision intelligence. Use… |
| `prediction-market-risk-review` | Review prediction-market, basket, oracle, and trading-agent workflows for compliance, safety, data-quality, privacy, and execution risk.… |
| `prisma-patterns` | Prisma ORM patterns for TypeScript backends — schema design, query optimization, transactions, pagination, and critical traps like update… |
| `product-capability` | Translate PRD intent, roadmap asks, or product discussions into an implementation-ready capability plan that exposes constraints, invaria… |
| `product-lens` |  |
| `production-audit` | Local-evidence production readiness audit for shipped apps, pre-launch reviews, post-merge checks, and "what breaks in prod?" questions w… |
| `production-scheduling` | Codified expertise for production scheduling, job sequencing, line balancing, changeover optimization, and bottleneck resolution in discr… |
| `project-flow-ops` | Operate execution flow across GitHub and Linear by triaging issues and pull requests, linking active work, and keeping GitHub public-faci… |
| `prompt-optimizer` | Analyze raw prompts, identify intent and gaps, match ECC components (skills/commands/agents/hooks), and output a ready-to-paste optimized… |
| `python-patterns` | Pythonic idioms, PEP 8 standards, type hints, and best practices for building robust, efficient, and maintainable Python applications |
| `python-testing` | Python testing strategies using pytest, TDD methodology, fixtures, mocking, parametrization, and coverage requirements |
| `pytorch-patterns` | PyTorch deep learning patterns and best practices for building robust, efficient, and reproducible training pipelines, model architecture… |
| `quality-nonconformance` | Codified expertise for quality control, non-conformance investigation, root cause analysis, corrective action, and supplier quality manag… |
| `quarkus-patterns` | Quarkus 3.x LTS architecture patterns with Camel for messaging, RESTful API design, CDI services, data access with Panache, and async pro… |
| `quarkus-security` | Quarkus Security best practices for authentication, authorization, JWT/OIDC, RBAC, input validation, CSRF, secrets management, and depend… |
| `quarkus-tdd` | Test-driven development for Quarkus 3.x LTS using JUnit 5, Mockito, REST Assured, Camel testing, and JaCoCo |
| `quarkus-verification` | "Verification loop for Quarkus projects: build, static analysis, tests with coverage, security scans, native compilation, and diff review… |
| `ralphinho-rfc-pipeline` | RFC-driven multi-agent DAG execution pattern with quality gates, merge queues, and work unit orchestration |
| `react-patterns` | React 18/19 patterns including hooks discipline, server/client component boundaries, Suspense + error boundaries, form actions, data fetc… |
| `react-performance` | React and Next.js performance optimization patterns adapted from Vercel Engineering's React Best Practices (https://github.com/vercel-lab… |
| `react-testing` | React component testing with React Testing Library, Vitest/Jest, MSW for network mocking, accessibility assertions with axe, and the deci… |
| `recsys-pipeline-architect` | Design composable recommendation, ranking, and feed pipelines using the six-stage Source→Hydrator→Filter→Scorer→Selector→SideEffect frame… |
| `recursive-decision-ledger` |  |
| `redis-patterns` | Redis data structure patterns, caching strategies, distributed locks, rate limiting, pub/sub, and connection management for production ap… |
| `regex-vs-llm-structured-text` | Decision framework for choosing between regex and LLM when parsing structured text — start with regex, add LLM only for low-confidence ed… |
| `remotion-video-creation` | Best practices for Remotion - Video creation in React. 29 domain-specific rules covering 3D, animations, audio, captions, charts, transit… |
| `repo-scan` | Cross-stack source code asset audit — classifies every file, detects embedded third-party libraries, and delivers actionable four-level v… |
| `research-ops` | Evidence-first current-state research workflow for ECC |
| `returns-reverse-logistics` | Codified expertise for returns authorization, receipt and inspection, disposition decisions, refund processing, fraud detection, and warr… |
| `rules-distill` | "Scan skills to extract cross-cutting principles and distill them into rules — append, revise, or create new rule files" |
| `rust-patterns` | Idiomatic Rust patterns, ownership, error handling, traits, concurrency, and best practices for building safe, performant applications |
| `rust-testing` | Rust testing patterns including unit tests, integration tests, async testing, property-based testing, mocking, and coverage. Follows TDD… |
| `safety-guard` |  |
| `santa-method` | "Multi-agent adversarial verification with convergence loop. Two independent review agents must both pass before output ships." |
| `scientific-db-pubmed-database` | Direct PubMed and NCBI E-utilities search workflows for biomedical literature, MeSH queries, PMID lookup, citation retrieval, and API-bac… |
| `scientific-db-uspto-database` | USPTO patent and trademark data workflow for official record lookup, PatentSearch queries, TSDR checks, assignment data, and reproducible… |
| `scientific-pkg-gget` | gget CLI and Python workflow for quick genomic database queries, sequence lookup, BLAST-style searches, enrichment checks, and reproducib… |
| `scientific-thinking-literature-review` | Systematic literature-review workflow for academic, biomedical, technical, and scientific topics, including search planning, source scree… |
| `scientific-thinking-scholar-evaluation` | Structured scholarly-work evaluation for papers, proposals, literature reviews, methods sections, evidence quality, citation support, and… |
| `search-first` | Research-before-coding workflow. Search for existing tools, libraries, and patterns before writing custom code. Invokes the researcher agent |
| `security-bounty-hunter` | Hunt for exploitable, bounty-worthy security issues in repositories. Focuses on remotely reachable vulnerabilities that qualify for real… |
| `security-review` |  |
| `security-scan` | Scan your Claude Code configuration (.claude/ directory) for security vulnerabilities, misconfigurations, and injection risks using Agent… |
| `seo` | Audit, plan, and implement SEO improvements across technical SEO, on-page optimization, structured data, Core Web Vitals, and content str… |
| `skill-comply` | Visualize whether skills, rules, and agent definitions are actually followed — auto-generates scenarios at 3 prompt strictness levels, ru… |
| `skill-scout` | Search existing local, marketplace, GitHub, and web skill sources before creating a new skill |
| `skill-stocktake` | " |
| `social-graph-ranker` | Weighted social-graph ranking for warm intro discovery, bridge scoring, and network gap analysis across X and LinkedIn |
| `social-publisher` | Agent-driven scheduling and publishing of social media posts across 13 platforms via SocialClaw |
| `springboot-patterns` | Spring Boot architecture patterns, REST API design, layered services, data access, caching, async processing, and logging. Use for Java S… |
| `springboot-security` | Spring Security best practices for authn/authz, validation, CSRF, secrets, headers, rate limiting, and dependency security in Java Spring… |
| `springboot-tdd` | Test-driven development for Spring Boot using JUnit 5, Mockito, MockMvc, Testcontainers, and JaCoCo |
| `springboot-verification` | "Verification loop for Spring Boot projects: build, static analysis, tests with coverage, security scans, and diff review before release… |
| `strategic-compact` | Suggests manual context compaction at logical intervals to preserve context through task phases rather than arbitrary auto-compaction |
| `swift-actor-persistence` | Thread-safe data persistence in Swift using actors — in-memory cache with file-backed storage, eliminating data races by design |
| `swift-concurrency-6-2` | Swift 6.2 Approachable Concurrency — single-threaded by default, @concurrent for explicit background offloading, isolated conformances fo… |
| `swift-protocol-di-testing` | Protocol-based dependency injection for testable Swift code — mock file system, network, and external APIs using focused protocols and Sw… |
| `swiftui-patterns` | SwiftUI architecture patterns, state management with @Observable, view composition, navigation, performance optimization, and modern iOS/… |
| `taste` | A creative-direction (taste) layer for music videos and short-form edits in the angelcore / cloud-trance / hyperpop visual family. Distil… |
| `tdd-workflow` |  |
| `team-agent-orchestration` | "Run team-based orchestration for agent squads using work items, ownership, agent Kanban, merge gates, and control pane handoffs." |
| `team-builder` | Interactive agent picker for composing and dispatching parallel teams |
| `terminal-ops` | Evidence-first repo execution workflow for ECC |
| `tinystruct-patterns` | Expert guidance for developing with the tinystruct Java framework |
| `token-budget-advisor` | Offers the user an informed choice about how much response depth to consume before answering |
| `ui-demo` | Record polished UI demo videos using Playwright |
| `ui-to-vue` |  |
| `uncloud` |  |
| `unified-notifications-ops` | Operate notifications as one ECC-native workflow across GitHub, Linear, desktop alerts, hooks, and connected communication surfaces |
| `verification-loop` | "A comprehensive verification system for Claude Code sessions." |
| `video-editing` | AI-assisted video editing workflows for cutting, structuring, and augmenting real footage. Covers the full pipeline from raw capture thro… |
| `videodb` | See, Understand, Act on video and audio. See- ingest from local files, URLs, RTSP/live feeds, or live record desktop; return realtime con… |
| `visa-doc-translate` | Translate visa application documents (images) to English and create a bilingual PDF with original and translation |
| `vite-patterns` | Vite build tool patterns including config, plugins, HMR, env variables, proxy setup, SSR, library mode, dependency pre-bundling, and buil… |
| `vue-patterns` | Vue.js 3 Composition API patterns, component architecture, reactivity best practices, Pinia state management, Vue Router navigation, and… |
| `windows-desktop-e2e` | E2E testing for Windows native desktop apps (WPF, WinForms, Win32/MFC, Qt) using pywinauto and Windows UI Automation |
| `workspace-surface-audit` | Audit the active repo, MCP servers, plugins, connectors, env surfaces, and harness setup, then recommend the highest-value ECC-native ski… |
| `x-api` | X/Twitter API integration for posting tweets, threads, reading timelines, search, and analytics. Covers OAuth auth patterns, rate limits,… |
