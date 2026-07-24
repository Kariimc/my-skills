# Harvesting sites into the taste library

How reference sites become design cards. All of it runs through the tools — the user
never types a command.

## Two kinds of source

1. **A single site** (e.g. an award-winner's actual URL) → becomes **one card**.
   `python3 tools/harvest_site.py https://thesite.com`

2. **A gallery / feed** (Awwwards, recent.design, Dribbble, Godly, Wix's "inspiring
   websites", a Lovable dashboard) → is a **list of sites**. Harvesting the gallery URL
   directly would only capture the gallery's *own* design. Instead, mine it for the
   outbound site links, then harvest those:
   `python3 tools/harvest_site.py --links https://www.awwwards.com/websites/sites_of_the_day/`
   prints the external site URLs it finds; review them, then harvest the good ones.

## The user's queued sources

`library/sources.json` holds the feeds the user has pointed at. Each entry records the
URL, what kind of source it is, and any access note. Current queue includes public
galleries (Awwwards Sites of the Day, recent.design, Dribbble) and **auth-gated
dashboards** (Wix account explore, Lovable dashboard) — see the access note below.

## Access reality — read before promising a harvest

- **Egress:** harvesting needs open web. A locked-down cloud box (GitHub/PyPI only)
  reaches none of these — run the harvester on a surface with open egress (the laptop).
  Always probe first; never claim a site is unreachable without proving it
  (`curl -s -o /dev/null -w "%{http_code}" https://host`).
- **Auth:** logged-in dashboards (`manage.wix.com/account/...`, `lovable.dev/dashboard`)
  need the user's own browser session. A headless fetch sees a login wall, not the
  content. For these, either the user exports/points at the specific public site URLs
  they liked, or the harvest runs in a browser already logged in as them. Don't pretend
  a headless harvest captured logged-in content.
- **Robots / rate limits:** be a good citizen — one request per page, a real
  User-Agent, no hammering. Galleries like Dribbble and Awwwards paginate; harvest a
  reasonable batch, not the whole site.

## What the harvester extracts (best-effort, degrades gracefully)

- **Screenshot** → `library/screenshots/<slug>.png`. Uses Playwright if importable
  (full-page, best quality); otherwise the pre-installed headless Chromium via its CLI;
  otherwise skips the image and still writes the card.
- **Palette** → the most frequent hex / `rgb()` colors across inline styles and
  same-origin stylesheets, deduped to a working set.
- **Fonts** → `font-family` families declared in the CSS, generics filtered out.
- **Layout signals** → rough flags: canvas/WebGL present, grid/flex usage, max-width,
  section count — hints for the "layout signature" field.
- **Title** → `<title>`.

Judgment fields (why it's here, the signature move, motion character, tags) are left for
you to sharpen when you use the card — the extractor fills facts, not taste.

## Playwright (optional upgrade)

The harvester works without Playwright. To enable the higher-quality full-page
screenshot path, run `bash tools/setup.sh` once on a surface with open web — it
`pip install`s Playwright and reuses the already-present Chromium
(`PLAYWRIGHT_BROWSERS_PATH` is set; do **not** run `playwright install`). Nothing about
the card schema changes; only the screenshot quality improves.

## Idempotent & additive

Re-harvesting a URL updates its card and `index.json` entry in place — it never
duplicates. Safe to re-run on the whole queue.
