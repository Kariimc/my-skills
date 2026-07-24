#!/usr/bin/env python3
"""
serve_library.py — a local web GUI for the taste library (Chase-AI style).

  python3 serve_library.py [port]     # default http://127.0.0.1:8777

Opens a localhost web app: a text box to paste a website URL, an "Add site" button,
and a live grid of every design card (screenshot, palette, fonts, tags). Paste a URL,
click Add, and the card appears — no CLI, no dependencies (Python's built-in server).

Buttons:
  - Add site   : harvest the pasted URL into a card (needs open web access)
  - Harvest queue : harvest every candidate in candidates.json that has a URL

Harvesting needs the internet. On a GitHub/PyPI-only box design sites are blocked, so
run this where the web is open (your laptop). The GUI itself always works.
"""
import sys, os, json, html, threading, webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_gallery          # render(), load_sites()
import harvest_site           # harvest(), load_index()

LIB = os.path.normpath(os.path.join(HERE, "..", "library"))

BAR_CSS = """<style>
  .addbar{display:flex;gap:10px;padding:16px 24px;border-bottom:1px solid var(--line);
    position:sticky;top:57px;z-index:4;background:color-mix(in srgb,var(--bg) 92%,transparent);
    backdrop-filter:blur(8px)}
  .addbar input{flex:1;padding:11px 14px;border:1px solid var(--line);border-radius:10px;
    background:var(--card);color:var(--fg);font-size:14px}
  .addbar input:focus{outline:none;border-color:var(--accent)}
  .addbar button{padding:11px 18px;border:none;border-radius:10px;background:var(--accent);
    color:#fff;font-weight:600;cursor:pointer;font-size:14px}
  .addbar button.ghost{background:var(--card);color:var(--fg);border:1px solid var(--line)}
  .flash{padding:10px 24px;font-size:13px;border-bottom:1px solid var(--line)}
  .flash.ok{color:#16a34a}.flash.err{color:#dc2626}
</style>"""


def bar_html(flash=""):
    f = ""
    if flash:
        cls = "err" if flash.startswith("!") else "ok"
        f = '<div class="flash %s">%s</div>' % (cls, html.escape(flash.lstrip("!")))
    return f"""{f}
<form class="addbar" method="post" action="/add">
  <input name="url" type="url" placeholder="Paste a website URL to add to your taste library…"
    autofocus required>
  <button type="submit">Add site</button>
  <button class="ghost" formaction="/queue" formmethod="post" type="submit">Harvest queue</button>
</form>"""


class Handler(BaseHTTPRequestHandler):
    def _page(self, flash=""):
        doc = build_gallery.render(build_gallery.load_sites(),
                                   inject_head=BAR_CSS, inject_body=bar_html(flash))
        body = doc.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _redirect(self, flash=""):
        self.send_response(303)
        loc = "/?m=" + (flash.replace(" ", "+") if flash else "")
        self.send_header("Location", loc)
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/favicon.ico":
            self.send_response(204); self.end_headers(); return
        flash = parse_qs(parsed.query).get("m", [""])[0]
        self._page(flash)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        data = parse_qs(self.rfile.read(length).decode("utf-8", "replace"))
        path = urlparse(self.path).path
        if path == "/add":
            url = (data.get("url", [""])[0] or "").strip()
            if not url:
                return self._redirect("!No URL given")
            ok = harvest_site.harvest(url)
            return self._redirect(("Added " if ok else "!Could not reach ") + url)
        if path == "/queue":
            cpath = os.path.join(LIB, "candidates.json")
            todo = []
            if os.path.exists(cpath):
                todo = [c for c in json.load(open(cpath)).get("candidates", [])
                        if c.get("status") == "pending" and c.get("url")]
            n = sum(1 for c in todo if harvest_site.harvest(c["url"]))
            return self._redirect("Harvested %d of %d queued sites" % (n, len(todo)))
        self._redirect("!Unknown action")

    def log_message(self, *a):
        pass  # quiet


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8777
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    url = "http://127.0.0.1:%d" % port
    print("Taste Library GUI  ->  %s   (Ctrl+C to stop)" % url)
    try:
        webbrowser.open(url)
    except Exception:
        pass
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped")


if __name__ == "__main__":
    main()
