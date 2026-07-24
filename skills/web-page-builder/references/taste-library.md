# The taste / inspiration library

A folder of **design cards** — one Markdown file per reference site — plus a machine
index (`index.json`) that powers the gallery web app. This is the user's own curated
taste, the thing that makes builds start from a point of view instead of a blank page.

## Layout

```
library/
  README.md          # human intro + how to add sites
  _TEMPLATE.md       # the card schema (copied per site by the harvester)
  index.json         # { "sites": [ {slug,url,title,palette,fonts,tags,screenshot}, ... ] }
  screenshots/       # <slug>.png per harvested site (created on first harvest)
  <slug>.md          # one card per site
```

## A card captures

- **Identity:** the site, its URL, one line on what makes it memorable.
- **Palette:** 4–6 named hex values (the ones that carry the design, not every color).
- **Type:** display face, body face, any utility/mono face; the pairing's character.
- **Layout signature:** the one structural move it's remembered by (split hero,
  oversized type, horizontal scroll, sticky index, editorial grid…).
- **Motion:** what animates and how (scroll-velocity type, WebGL hero, page transitions,
  reveal vocabulary) — or "static/minimal".
- **Why it's here / when to reach for it:** the mood or brief this card fits.
- **Tags:** freeform, for filtering in the gallery (e.g. `editorial`, `webgl`, `dark`,
  `luxury`, `saas`, `brutalist`).

`_TEMPLATE.md` is the exact schema; the harvester fills as much as it can extract
(palette, fonts, screenshot, layout signals) and leaves the judgment fields for you to
sharpen when you use the card.

## Adding sites (all no-CLI for the user — you run these)

- **One or many URLs:** `python3 tools/harvest_site.py <url> [url2 …]`
- **A Chrome bookmarks export:** `python3 tools/import_bookmarks.py bookmarks.html --harvest`
  (add `--folder "Bookmarks bar"` to limit to the bar).
- **Awwwards / FWA / Godly picks:** copy the site URLs and harvest them the same way.

The harvester is **additive and idempotent** — re-harvesting a URL updates its card in
place, never duplicates it.

## Using the library in a build

At step 1 of the loop, load `index.json`, pick 1–3 cards by mood, read them, and let
their systems inform the direction. Reference is fuel, not a template — never ship a
copy of a card; metabolize it into something specific to the brief.

## Browsing it — the gallery web app

`python3 tools/build_gallery.py` reads `index.json` and writes a single self-contained
`gallery.html`: a responsive grid of every card with its screenshot, palette swatches,
fonts, and tags, with tag filtering and light/dark. That is the "view your inspiration"
surface — open it in the browser, or publish it as an Artifact to click through.

Empty library → the gallery renders a friendly empty state telling the user how to add
sites. It never looks broken.
