---
name: web-page-builder
description: THE primary, always-on skill for building any website — landing page, marketing site, portfolio, product page, web app UI, or microsite. Use whenever the user wants to build, create, design, redesign, or ship a website or web page. Runs one loop — pull a look from the taste library, commit a bold direction, build wide, view-and-tweak live in the browser, polish with impeccable, add award-tier motion, and deploy — folding in frontend-design, premium-web-craft, impeccable, visual-prototype, web-implementation, web-deployment, and Higgsfield assets. The front door for all website work; prefer it over the individual design skills.
license: Apache 2.0
version: 1.0.0
---

# Web Page Builder — the one front door for websites

This is the main skill for building websites. It does not replace the specialist
skills; it **drives** them in one deliberate loop so every site starts from real
taste, gets built to an award-tier floor, is reviewed the way a designer reviews
(click an element, change it), and ships. The user never touches a terminal — every
step runs through skills and tools.

> **Provenance & honesty:** this workflow is modeled on Chase AI's Claude-Code
> website method (taste library → committed direction → build → live tweak →
> impeccable polish → deploy). It was reconstructed from Chase AI's published
> material and the impeccable skill, **not** from the source video, which was
> unreachable when this skill was built. If the video's flow differs, treat the
> user's correction as truth and adjust `references/workflow.md`.

## The loop (run in order; skip only when the user scopes you down)

| # | Step | What happens | Owned by |
|---|------|--------------|----------|
| 1 | **Reference** | Pull 1–3 looks from the taste library that fit the brief. Empty library? Say so and offer to harvest sites first. | `library/` + `references/taste-library.md` |
| 2 | **Direction** | Commit to ONE bold aesthetic POV (palette, type, layout signature) before any CSS. No hedging, no three-safe-options. | `frontend-design` skill + `references/workflow.md` |
| 3 | **Build** | Implement the page/site for real, on the brief's real content. | `web-implementation` / `web-artifacts-builder` |
| 4 | **View & tweak** | Hand the user a clickable preview where they pin an element and say what to change — the exact Chase-AI "point and fix" loop. | `references/preview-and-tweak.md` (visual-prototype overlay + impeccable `live`) |
| 5 | **Polish** | Run impeccable's quality passes (`polish`, `audit`, `bolder`/`quieter`, `typeset`, `layout`) until it clears the floor. | vendored `impeccable` skill |
| 6 | **Motion** | Award-tier, reduced-motion-safe animation where it earns its frame budget. | `premium-web-craft` + `references/quality-floor.md` |
| 7 | **Assets & deploy** | Generate hero imagery/video/3D (Higgsfield), then deploy. | `references/assets.md`, `references/deploy.md` |

Not every request is a full loop. "Make this hero bolder" jumps straight to step 5
with impeccable `bolder`. "Build me a landing page for X" runs the whole thing.

## Start here, every time

1. **Read the brief for the real subject.** What is it, who's it for, what is the
   page's one job? If the brief doesn't say, pin it yourself and state your pick.
2. **Check the taste library** (`library/index.json`). If it has matching cards,
   load them and let their design systems inform direction. If it's empty, tell the
   user plainly and offer to harvest their sites (see below) — never invent a
   "reference" the library doesn't contain.
3. **Commit to a direction** (step 2) and only then write code. The single biggest
   failure is building before committing to a POV — you get AI-slop defaults
   (cream + serif + terracotta, black + acid-green, hairline broadsheet).
4. **Deliver a preview the user can pin-and-tweak** (step 4) — never hand over a
   site the user has to describe changes to blind.

## The taste / inspiration library

`library/` is the user's own reference collection — one **design card** per site,
each capturing that site's palette, type, motion, and layout signature as a prompt
you can build from (the "Awesome Design" pattern). It ships **empty on purpose**;
it fills from the user's actual sources.

### Add by URL — the one-line way in (do this whenever the user gives a URL to save)

When the user pastes a website URL and says anything like "add this to my taste
library", "save this site", "add this inspo", or just drops a URL as inspiration:
**run the harvester for them** — never make them type a command:

```
python3 tools/harvest_site.py <url>
```

Then confirm what landed (title, colors, fonts, screenshot yes/no) in one line, and
offer to rebuild the gallery. That's the whole loop: they give a URL, they get a card.
If the harvest can't reach the URL (blocked egress or an auth wall), say so plainly and
run it where the web is open — don't claim a card you didn't write. More ways to add: 

- **A URL (or a list):** `python3 tools/harvest_site.py <url> [url2 ...]` — fetches
  the page, screenshots it (headless Chromium), pulls its palette + fonts + layout
  signals, and writes a card + an `index.json` entry.
- **Chrome bookmarks:** `python3 tools/import_bookmarks.py <bookmarks.html>` — parses
  an exported bookmarks file and harvests every link (optionally filter to a folder
  like the bookmarks bar).
- **Awwwards / galleries:** harvest the site URLs the same way.

> **Where harvesting runs:** it needs open web access. On a locked-down cloud box
> (GitHub/PyPI only) most design sites are blocked — run the harvester on a surface
> with open egress (the laptop). The machinery is identical everywhere.

### Taste Studio — the standalone web app (the Chase-AI way)

`python3 tools/build_gallery.py` generates **Taste Studio** (`gallery.html`), a single
self-contained web app — a clickable grid of every look with its screenshot, palette
swatches, and fonts. This is a separate app from the skill launcher; its whole job is
turning inspiration into sites. Each look has:

- **⚡ Build a site in this style** — copies a ready build brief (that look's palette +
  font pairing + layout, phrased as a `web-page-builder` instruction) to paste into
  Claude. This is Chase AI's move — feed the design *system* to the builder — made
  one click. The brief carries the design **ideas only** and explicitly says to use the
  user's own assets/Higgsfield, never copy the reference site's content or images.
- **Visit** — opens the reference site.

`python3 tools/serve_library.py` runs the same studio as a **live localhost app** at
`http://127.0.0.1:8777` with a text box + **Add site** button (paste a URL → card
appears) and a **Harvest queue** button. Harvesting needs open web; the app itself
always runs. For a localhost GUI to build/tweak the *site itself*, use impeccable's
`live` mode (see `preview-and-tweak.md`).

**Copyright line (never cross it):** looks capture *others'* sites. Their palettes,
font pairings, and layout patterns are ideas you may build from; their screenshots and
images are not assets to drop into the user's live sites. Build from the user's own
assets + Higgsfield + the extracted tokens.

See `references/taste-library.md` for the card schema and `references/harvesting.md`
for details and troubleshooting.

## View & tweak — the exact "point at it and change it" loop

Two surfaces, both no-CLI for the user:

- **Primary — `visual-prototype` overlay.** Every preview ships with the Tweak &
  Comment overlay: the user arms pin mode, clicks any element, types the change,
  and exports one markdown block. Paste it back and this skill applies each pin
  exactly. This is the reliable, works-everywhere version of Chase AI's live edit.
- **Deeper — impeccable `live`.** For local dev, impeccable's `live` mode opens the
  running site in the browser, lets the user pick an element, and generates visual
  variants in place. Use it when the user wants in-browser variant generation rather
  than the pin-and-paste loop.

Full guidance: `references/preview-and-tweak.md`.

## What each folded-in skill is for

- **frontend-design** — taste-level direction: palette, type pairing, the one
  signature element. Runs at step 2.
- **impeccable** (vendored here) — the design *language* and quality engine: 23
  one-word commands (`polish`, `audit`, `critique`, `bolder`, `quieter`, `typeset`,
  `layout`, `animate`, `distill`, `harden`, `live`, …). Runs at steps 4–5.
- **premium-web-craft** — live award-tier research + motion vocabulary, harvested
  into a reusable library. Runs at step 6.
- **visual-prototype** — the pin-and-comment preview surface. Runs at step 4.
- **web-implementation / web-artifacts-builder** — turning the direction into a real
  page or a shareable artifact. Runs at step 3.
- **web-deployment** — Docker/Vercel/CI deploy paths. Runs at step 7.
- **Higgsfield MCP** — hero imagery, video, and 3D assets, plus its own website
  create/deploy tools. Runs at step 7 (`references/assets.md`).

## The quality floor (never negotiable)

Every site ships: responsive to mobile, visible keyboard focus, `prefers-reduced-motion`
honored (every effect collapses to a calm resting frame), no content gated behind
motion, animate transform/opacity only, LCP not regressed by entrance effects. The
full list — and the runtime gotchas the compiler won't catch — is in
`references/quality-floor.md`. Do not announce the floor; just clear it.

## No-CLI promise

The user stays out of the terminal. This skill runs the Python tools, the impeccable
passes, the browser preview, and the deploy for them. The only things that are ever
the user's to do: provide the reference URLs / bookmarks, pin the tweaks they want,
and approve the deploy.
