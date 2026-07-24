# Taste Library

Your own curated web-design references. One **design card** (`<slug>.md`) per site,
plus `index.json` (the machine index that powers the gallery) and `sources.json` (the
feeds you pull inspiration from).

This ships **empty of cards** on purpose — it fills from *your* sources, not generic
picks. See `../references/taste-library.md` for the card schema and
`../references/harvesting.md` for how harvesting works.

## Add sites (run by Claude — you never touch a terminal)

- **A single site:** `python3 ../tools/harvest_site.py https://thesite.com`
- **A gallery/feed → mine it for site links first:**
  `python3 ../tools/harvest_site.py --links https://www.awwwards.com/websites/sites_of_the_day/`
- **A Chrome bookmarks export:**
  `python3 ../tools/import_bookmarks.py bookmarks.html --harvest --folder "Bookmarks bar"`

## Browse it — the gallery web app

`python3 ../tools/build_gallery.py` → writes `../gallery.html`, a clickable grid of
every card (screenshot, palette, fonts, tags) with tag filtering and light/dark. Open
it in a browser or publish it as an Artifact.

## Your queued sources

See `sources.json` / `sources.md`. They're **galleries and dashboards**, not single
sites — harvest them in "gallery mode" (mine for the individual site links, then
harvest the good ones). Two are logged-in dashboards that need your browser session.

## Where this runs

Harvesting needs open web access. On a GitHub/PyPI-only cloud box it reaches none of
these — run it on your laptop (open egress + your logins). The machinery is identical
everywhere.
