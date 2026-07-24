#!/usr/bin/env python3
"""
harvest_site.py — turn a website into a taste-library design card.

Usage:
  python3 harvest_site.py <url> [<url> ...]        # harvest one or more sites -> cards
  python3 harvest_site.py --links <gallery_url>    # print external site links found on a
                                                   # gallery/feed page (Awwwards, recent.design,
                                                   # Dribbble...) so you can pick which to harvest
  python3 harvest_site.py --queue                  # harvest everything still 'pending' in
                                                   # library/candidates.json that has a url

For each harvested site it writes:
  library/<slug>.md               a design card (palette, fonts, layout signals, screenshot)
  library/screenshots/<slug>.png  a screenshot (if a browser is available)
  library/index.json              updated in place (idempotent, keyed by url)

No third-party deps required: uses `requests` if present else urllib; screenshots via
Playwright if importable, else the pre-installed headless Chromium CLI, else skipped.
Needs OPEN WEB access — on a GitHub/PyPI-only box every design site is blocked; run it
where the web is open (the laptop).
"""
import sys, os, re, json, subprocess, shutil, datetime
from urllib.parse import urlparse, urljoin

HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.normpath(os.path.join(HERE, "..", "library"))
SHOTS = os.path.join(LIB, "screenshots")
INDEX = os.path.join(LIB, "index.json")
GENERIC_FONTS = {"sans-serif", "serif", "monospace", "system-ui", "ui-sans-serif",
                 "ui-serif", "ui-monospace", "cursive", "fantasy", "inherit",
                 "-apple-system", "blinkmacsystemfont", "arial", "helvetica"}
UA = "Mozilla/5.0 (compatible; taste-library-harvester/1.0)"


def fetch(url, timeout=15):
    """Return page text, or None. Prefer requests, fall back to urllib."""
    try:
        import requests
        r = requests.get(url, headers={"User-Agent": UA}, timeout=timeout)
        return r.text if r.status_code < 400 else None
    except ImportError:
        pass
    except Exception:
        return None
    try:
        import urllib.request
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read().decode("utf-8", "replace")
    except Exception:
        return None


def slugify(url):
    host = urlparse(url).netloc.replace("www.", "")
    path = urlparse(url).path.strip("/").replace("/", "-")
    s = (host + ("-" + path if path else "")).lower()
    s = re.sub(r"[^a-z0-9-]+", "-", s).strip("-")
    return s[:60] or "site"


def extract_colors(text, limit=8):
    hexes = re.findall(r"#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", text)
    norm = []
    for h in hexes:
        h = h.lower()
        if len(h) == 4:  # #abc -> #aabbcc
            h = "#" + "".join(c * 2 for c in h[1:])
        norm.append(h)
    rgbs = re.findall(r"rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})", text)
    for r, g, b in rgbs:
        try:
            norm.append("#%02x%02x%02x" % (int(r), int(g), int(b)))
        except ValueError:
            continue
    counts = {}
    for c in norm:
        counts[c] = counts.get(c, 0) + 1
    ranked = sorted(counts, key=lambda c: -counts[c])
    return ranked[:limit]


def extract_fonts(text, limit=6):
    fams = re.findall(r"font-family\s*:\s*([^;{}\"']+)", text, re.I)
    out, seen = [], set()
    for decl in fams:
        for token in decl.split(","):
            name = token.strip().strip("'\"").strip()
            name = name.replace("\\ ", " ").replace("\\", "").strip()
            key = name.lower()
            if not name or key in GENERIC_FONTS or key in seen:
                continue
            if len(name) > 40 or any(ch in name for ch in "{}()<>"):
                continue
            seen.add(key)
            out.append(name)
            if len(out) >= limit:
                return out
    return out


def layout_signals(text):
    t = text.lower()
    sig = []
    if "<canvas" in t or "webgl" in t or "three" in t:
        sig.append("canvas/WebGL present")
    if "display:grid" in t.replace(" ", "") or "display: grid" in t:
        sig.append("CSS grid")
    if "display:flex" in t.replace(" ", "") or "display: flex" in t:
        sig.append("flexbox")
    mw = re.search(r"max-width\s*:\s*(\d{3,4})px", t)
    if mw:
        sig.append("max-width " + mw.group(1) + "px")
    sig.append(str(len(re.findall(r"<section", t))) + " <section> blocks")
    if "gsap" in t:
        sig.append("GSAP")
    if "lenis" in t:
        sig.append("Lenis smooth scroll")
    return sig


def title_of(text, url):
    m = re.search(r"<title[^>]*>(.*?)</title>", text, re.I | re.S)
    return re.sub(r"\s+", " ", m.group(1)).strip() if m else urlparse(url).netloc


def screenshot(url, out_path):
    """Best-effort screenshot. Returns True on success."""
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    # 1) Playwright (best quality, full page) if installed
    try:
        from playwright.sync_api import sync_playwright
        exe = os.environ.get("PLAYWRIGHT_CHROMIUM") or "/opt/pw-browsers/chromium"
        with sync_playwright() as p:
            launch = {"headless": True}
            if os.path.exists(exe):
                launch["executable_path"] = exe
            browser = p.chromium.launch(**launch)
            page = browser.new_page(viewport={"width": 1440, "height": 900})
            page.goto(url, wait_until="networkidle", timeout=30000)
            page.screenshot(path=out_path, full_page=True)
            browser.close()
        return os.path.exists(out_path)
    except Exception:
        pass
    # 2) Headless Chromium CLI (pre-installed on this box; no pip needed)
    for exe in (os.environ.get("PLAYWRIGHT_CHROMIUM"), "/opt/pw-browsers/chromium",
                shutil.which("chromium"), shutil.which("google-chrome"),
                shutil.which("chromium-browser")):
        if exe and os.path.exists(exe):
            try:
                subprocess.run(
                    [exe, "--headless=new", "--no-sandbox", "--hide-scrollbars",
                     "--window-size=1440,2400", "--screenshot=" + out_path, url],
                    timeout=45, check=False,
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
                    return True
            except Exception:
                continue
    return False


def load_index():
    if os.path.exists(INDEX):
        try:
            return json.load(open(INDEX))
        except Exception:
            pass
    return {"sites": []}


def save_index(idx):
    json.dump(idx, open(INDEX, "w"), indent=2)


def write_card(slug, url, title, palette, fonts, sig, shot_rel, harvested):
    tags = "[]"
    pal = ", ".join('"%s"' % c for c in palette)
    fnt = ", ".join('"%s"' % f for f in fonts)
    body = f"""---
slug: {slug}
url: {url}
title: {title}
tags: {tags}
palette: [{pal}]
fonts: [{fnt}]
screenshot: {shot_rel}
harvested: "{harvested}"
---

# {title}

> _One line on what makes this site memorable — fill in when you use the card._

## Palette
{", ".join(palette) if palette else "_none extracted_"}

## Type
{", ".join(fonts) if fonts else "_none extracted_"}

## Layout signals (auto)
{", ".join(sig) if sig else "_none_"}

## Layout signature
_The one structural move it's remembered by — fill in._

## Motion
_What animates and how — fill in._

## When to reach for it
_The mood or brief this card fits — fill in._
"""
    open(os.path.join(LIB, slug + ".md"), "w").write(body)


def same_origin_css(text, base_url, max_sheets=5):
    """Fetch up to N same-origin linked stylesheets and return their concatenated text.
    Modern sites keep most color/type in CSS, not inline HTML, so this is where the
    real palette and fonts live."""
    hrefs = re.findall(r'<link[^>]+rel=["\']?stylesheet["\']?[^>]*>', text, re.I)
    urls = []
    host = urlparse(base_url).netloc
    for tag in hrefs:
        m = re.search(r'href=["\']([^"\']+)["\']', tag, re.I)
        if not m:
            continue
        full = urljoin(base_url, m.group(1))
        if urlparse(full).netloc == host and full not in urls:
            urls.append(full)
    css = []
    for u in urls[:max_sheets]:
        c = fetch(u, timeout=12)
        if c:
            css.append(c)
    return "\n".join(css)


def harvest(url):
    text = fetch(url)
    if text is None:
        print("  ! unreachable (blocked, offline, or auth wall): " + url)
        return False
    slug = slugify(url)
    title = title_of(text, url)
    css = same_origin_css(text, url)
    corpus = text + "\n" + css
    palette = extract_colors(corpus)
    fonts = extract_fonts(corpus)
    sig = layout_signals(text)
    shot_rel = "screenshots/" + slug + ".png"
    ok = screenshot(url, os.path.join(SHOTS, slug + ".png"))
    if not ok:
        shot_rel = ""
    harvested = datetime.date.today().isoformat()
    write_card(slug, url, title, palette, fonts, sig, shot_rel, harvested)
    idx = load_index()
    idx["sites"] = [s for s in idx["sites"] if s.get("url") != url]
    idx["sites"].append({"slug": slug, "url": url, "title": title,
                         "palette": palette, "fonts": fonts, "tags": [],
                         "screenshot": shot_rel, "harvested": harvested})
    save_index(idx)
    print("  + card: %s.md  (%d colors, %d fonts, screenshot=%s)"
          % (slug, len(palette), len(fonts), "yes" if shot_rel else "no"))
    return True


def gallery_links(url):
    text = fetch(url)
    if text is None:
        print("Unreachable (blocked/offline/auth): " + url)
        return
    host = urlparse(url).netloc
    hrefs = re.findall(r'href=["\']([^"\']+)["\']', text)
    ext = []
    seen = set()
    for h in hrefs:
        full = urljoin(url, h)
        p = urlparse(full)
        if p.scheme not in ("http", "https"):
            continue
        if p.netloc and p.netloc != host and full not in seen:
            seen.add(full)
            ext.append(full)
    print("# %d external links on %s" % (len(ext), url))
    for e in ext:
        print(e)


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    os.makedirs(LIB, exist_ok=True)
    if args[0] == "--links":
        for u in args[1:]:
            gallery_links(u)
        return
    if args[0] == "--queue":
        cpath = os.path.join(LIB, "candidates.json")
        if not os.path.exists(cpath):
            print("no candidates.json")
            return
        cands = json.load(open(cpath)).get("candidates", [])
        todo = [c for c in cands if c.get("status") == "pending" and c.get("url")]
        print("Harvesting %d candidates with URLs..." % len(todo))
        for c in todo:
            print(c.get("name", c["url"]))
            harvest(c["url"])
        return
    for u in args:
        print("Harvesting: " + u)
        harvest(u)


if __name__ == "__main__":
    main()
