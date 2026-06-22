# Skill Overlap & Dedupe Report

Auto-invocation picks a skill by matching your request against each skill's
`description`. When two skills describe overlapping territory, matching becomes
ambiguous and the wrong one can fire. Below are the real collisions, ranked by
how much they overlap, with a recommendation.

> Nothing here has been merged or deleted — these are recommendations. Say the
> word and I'll execute any of them.

| # | Skills | Overlap | Recommendation |
|---|---|---|---|
| 1 | `network-engineer` ↔ `network-infrastructure` | **High** — both are "Principal Network…", both cover BGP/OSPF/EVPN-VXLAN/SD-WAN and vendor CLI. | **Merge.** Keep `network-engineer` (routing/switching/CLI), fold the unique infra bits (ZTNA, NFV, multi-cloud, Terraform/Ansible) in as sections. Delete `network-infrastructure`. |
| 2 | `video-to-game` ↔ `video-to-animation` | **High** — `video-to-game` already lists "extract animations" among sprites/SFX/shaders/VFX. `video-to-animation` is a strict subset. | **Merge** animation into `video-to-game`, or narrow `video-to-animation`'s description to *only* mocap→animation so triggers stop colliding. |
| 3 | `cannabis-delivery-app` ↔ `cannabis-delivery-compliance` | **Medium-High** — same NJ CRC/METRC domain; app = architecture, compliance = full code implementation. | **Keep both but split cleanly:** app = design/architecture only; compliance = implementation only. Cross-reference in each description so the right one fires. |
| 4 | `game-art` ↔ `game-assets` ↔ `game-environment` | **Medium** — all "technical artist" for games; art = concept/specs, assets = 2D→3D pipeline, environment = backgrounds. | Keep all three but sharpen the first line of each description to its niche (concept vs. mesh pipeline vs. environment) to reduce mis-fires. |
| 5 | `spotify-scraper` ↔ `music-manager` | **Medium** — both ingest a Spotify library; manager is a full desktop app, scraper is a downloader. | Narrow `spotify-scraper` to "download/export" and `music-manager` to "aggregate/manage multi-source library." |
| 6 | `digital-marketing` ↔ `game-marketing` | **Low-Medium** — game-marketing is a vertical of digital-marketing. | Acceptable. Ensure `game-marketing` says "for games specifically" so it wins game contexts and defers otherwise. |
| 7 | `ai-agent-developer` ↔ `agent-swarm` | **Low** — single-agent tooling vs. multi-agent orchestration. | Keep separate; boundaries are already clear. |
| 8 | `coding-notes` ↔ `debugger` | **Low** — both auto-update a README changelog, but distinct primary jobs (docs vs. fixes). | Keep separate. |

## Frontmatter fix applied
- `session-start-hook/SKILL.md` — `name:` was `startup-hook-skill` (mismatched its
  directory, which can break `/session-start-hook` invocation). Corrected to
  `session-start-hook`.

## Suggested next actions (in priority order)
1. Merge `network-infrastructure` → `network-engineer`.
2. Resolve `video-to-game` / `video-to-animation` overlap.
3. Split cannabis app vs. compliance descriptions cleanly.
4. Sharpen the game-art trio's first lines.
5. Clarify spotify-scraper vs. music-manager boundary.
