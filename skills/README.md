# Skills Catalog

52 skills, organized by domain. Each lives in `skills/<name>/SKILL.md` and is
auto-loaded into every project via the SessionStart sync hook (see the repo
root `README.md`). Claude invokes a skill automatically when your request
matches its `description` — you can also force one with `/<skill-name>`.

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

## 🧩 Built-in (shipped with Claude Code, not files in this repo)
These are always available globally without living in `skills/` — listed here for reference only.
| Skill | What it does |
|---|---|
| `loop` | Run a prompt or slash command on a recurring interval (e.g. poll a deploy every 5m). |
| `launch-your-agent` (`Agent`) | Launch a sub-agent to handle complex, multi-step or parallel tasks. |

---

See [`OVERLAP-REPORT.md`](./OVERLAP-REPORT.md) for skills with colliding triggers
and recommended merges.
