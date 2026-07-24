#!/usr/bin/env python3
"""
build_gallery.py — render the taste library as a single self-contained web app.

  python3 build_gallery.py                # -> ../gallery.html
  python3 build_gallery.py path/out.html  # custom output path

Reads library/index.json and writes one HTML file: a responsive grid of every design
card (screenshot, palette swatches, fonts, tags) with tag filtering and light/dark.
Screenshots are embedded as data URIs so the file is fully portable (open it anywhere,
or publish it as an Artifact). Empty library -> a friendly empty state, never broken.
"""
import sys, os, json, base64, html, mimetypes

HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.normpath(os.path.join(HERE, "..", "library"))
INDEX = os.path.join(LIB, "index.json")


def data_uri(rel):
    if not rel:
        return ""
    p = os.path.join(LIB, rel)
    if not os.path.exists(p) or os.path.getsize(p) > 4_000_000:
        return ""
    mime = mimetypes.guess_type(p)[0] or "image/png"
    return "data:%s;base64,%s" % (mime, base64.b64encode(open(p, "rb").read()).decode())


def esc(s):
    return html.escape(str(s), quote=True)


def swatches(palette):
    return "".join(
        '<span class="sw" style="background:%s" title="%s"></span>' % (esc(c), esc(c))
        for c in (palette or [])[:6])


def card_html(s):
    uri = data_uri(s.get("screenshot", ""))
    if uri:
        media = '<img loading="lazy" src="%s" alt="%s">' % (uri, esc(s.get("title", "")))
    else:
        media = '<div class="noshot">%s</div>' % esc(s.get("title", "site")[:2].upper())
    tags = " ".join(esc(t) for t in s.get("tags", []))
    fonts = ", ".join(esc(f) for f in s.get("fonts", [])[:3]) or "&mdash;"
    return f"""<a class="card" href="{esc(s.get('url','#'))}" target="_blank" rel="noopener"
      data-tags="{tags}">
      <div class="shot">{media}</div>
      <div class="meta">
        <div class="ttl">{esc(s.get('title','Untitled'))}</div>
        <div class="pal">{swatches(s.get('palette'))}</div>
        <div class="fon">{fonts}</div>
        <div class="url">{esc(s.get('url',''))}</div>
      </div>
    </a>"""


def load_sites():
    idx = json.load(open(INDEX)) if os.path.exists(INDEX) else {"sites": []}
    return idx.get("sites", [])


def render(sites, inject_head="", inject_body=""):
    alltags = sorted({t for s in sites for t in s.get("tags", [])})
    chips = "".join('<button class="chip" data-tag="%s">%s</button>' % (esc(t), esc(t))
                    for t in alltags)
    if sites:
        grid = "\n".join(card_html(s) for s in sites)
        empty = ""
    else:
        grid = ""
        empty = """<div class="empty">
          <h2>Your taste library is empty</h2>
          <p>Add sites and this gallery fills itself:</p>
          <pre>python3 tools/harvest_site.py https://a-site.com
python3 tools/harvest_site.py --links https://www.awwwards.com/websites/sites_of_the_day/
python3 tools/import_bookmarks.py bookmarks.html --harvest</pre>
          <p>Seven inspiration feeds are already queued in <code>library/sources.json</code>
          and candidate sites in <code>library/candidates.json</code> &mdash; harvest them on a
          machine with open web access.</p>
        </div>"""
    count = len(sites)
    doc = f"""<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Taste Library &mdash; {count} site{'s' if count!=1 else ''}</title>
{inject_head}
<style>
  :root{{--bg:#faf9f7;--fg:#16161a;--muted:#6b7280;--card:#ffffff;--line:#e6e4df;--accent:#e8482b}}
  html[data-theme=dark]{{--bg:#0b0b0f;--fg:#f4f3ee;--muted:#8a8f98;--card:#15151b;--line:#26262e;--accent:#ff5a3c}}
  *{{box-sizing:border-box}}
  body{{margin:0;background:var(--bg);color:var(--fg);
    font:15px/1.5 ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,sans-serif}}
  header{{position:sticky;top:0;z-index:5;display:flex;gap:16px;align-items:center;
    padding:16px 24px;background:color-mix(in srgb,var(--bg) 88%,transparent);
    backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}}
  h1{{font-size:16px;margin:0;letter-spacing:.02em;font-weight:650}}
  .count{{color:var(--muted);font-size:13px}}
  .spacer{{flex:1}}
  .chips{{display:flex;gap:8px;flex-wrap:wrap;padding:12px 24px;border-bottom:1px solid var(--line)}}
  .chip,.themebtn{{cursor:pointer;border:1px solid var(--line);background:var(--card);
    color:var(--fg);border-radius:999px;padding:5px 12px;font-size:12px}}
  .chip.on{{background:var(--accent);color:#fff;border-color:var(--accent)}}
  .grid{{display:grid;gap:20px;padding:24px;
    grid-template-columns:repeat(auto-fill,minmax(300px,1fr))}}
  .card{{display:flex;flex-direction:column;background:var(--card);border:1px solid var(--line);
    border-radius:14px;overflow:hidden;text-decoration:none;color:inherit;
    transition:transform .15s ease,border-color .15s ease}}
  .card:hover{{transform:translateY(-3px);border-color:var(--accent)}}
  .shot{{aspect-ratio:16/10;overflow:hidden;background:var(--bg);border-bottom:1px solid var(--line)}}
  .shot img{{width:100%;height:100%;object-fit:cover;object-position:top}}
  .noshot{{width:100%;height:100%;display:grid;place-items:center;font-size:34px;
    font-weight:700;color:var(--muted)}}
  .meta{{padding:14px 16px;display:flex;flex-direction:column;gap:7px}}
  .ttl{{font-weight:640}}
  .pal{{display:flex;gap:5px}}
  .sw{{width:20px;height:20px;border-radius:5px;border:1px solid rgba(128,128,128,.35)}}
  .fon{{font-size:12.5px;color:var(--muted)}}
  .url{{font-size:11.5px;color:var(--muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}}
  .empty{{max-width:640px;margin:12vh auto;padding:0 24px;text-align:center;color:var(--muted)}}
  .empty h2{{color:var(--fg)}}
  .empty pre{{text-align:left;background:var(--card);border:1px solid var(--line);
    border-radius:10px;padding:14px;overflow:auto;font-size:12.5px}}
  a{{color:var(--accent)}}
</style>
</head>
<body>
<header>
  <h1>Taste Library</h1>
  <span class="count">{count} site{'s' if count!=1 else ''}</span>
  <span class="spacer"></span>
  <button class="themebtn" onclick="var r=document.documentElement;r.dataset.theme=r.dataset.theme==='dark'?'light':'dark'">theme</button>
</header>
{inject_body}
{f'<div class="chips"><button class="chip on" data-tag="">all</button>{chips}</div>' if alltags else ''}
<main>
  <div class="grid">{grid}</div>
  {empty}
</main>
<script>
  var chips=[].slice.call(document.querySelectorAll('.chip'));
  var cards=[].slice.call(document.querySelectorAll('.card'));
  chips.forEach(function(c){{c.onclick=function(){{
    chips.forEach(function(x){{x.classList.remove('on')}});c.classList.add('on');
    var t=c.dataset.tag;
    cards.forEach(function(card){{
      card.style.display=(!t||(' '+card.dataset.tags+' ').indexOf(' '+t+' ')>=0)?'':'none';
    }});
  }};}});
</script>
</body>
</html>"""
    return doc


def build(out_path):
    sites = load_sites()
    open(out_path, "w").write(render(sites))
    print("Wrote %s (%d sites)" % (out_path, len(sites)))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.normpath(
        os.path.join(HERE, "..", "gallery.html"))
    build(out)


if __name__ == "__main__":
    main()
