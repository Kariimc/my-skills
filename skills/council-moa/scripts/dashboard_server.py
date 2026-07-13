#!/usr/bin/env python3
"""
Local visual dashboard for The Council — runs on YOUR machine.

  python dashboard_server.py                # opens http://localhost:8787
  python dashboard_server.py --port 9000

The browser only ever talks to this local server; the server makes the LLM
calls (Ollama, Groq, OpenRouter, Gemini, OpenAI, Anthropic). That means:
  * no CORS to configure, ever
  * your API key never touches the browser (enter it in the UI or set an env var)
  * works fully offline with Ollama (no internet, no external scripts)

Pure standard library — no `pip install` needed. Reuses council.py (same folder).
"""
import argparse
import json
import os
import queue
import sys
import threading
import urllib.error
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import council  # noqa: E402  (engine is pure stdlib; provider SDK imports are lazy and unused here)


# --------------------------------------------------------------------------- #
# Provider callers (stdlib urllib — no third-party packages)
# --------------------------------------------------------------------------- #
def _openai_compatible(base_url, api_key, models, default_model):
    base = base_url.rstrip("/")

    def call(role, system, user, want_json=False, grounded=False):
        model = (models or {}).get(role) or default_model
        body = {"model": model, "messages": [{"role": "system", "content": system},
                                             {"role": "user", "content": user}]}

        def post(b):
            req = urllib.request.Request(
                base + "/chat/completions", data=json.dumps(b).encode("utf-8"),
                headers={"Content-Type": "application/json",
                         "Authorization": "Bearer " + (api_key or "x")})
            with urllib.request.urlopen(req, timeout=300) as r:
                d = json.loads(r.read().decode("utf-8"))
            return (d["choices"][0]["message"].get("content") or "").strip()

        if want_json:
            try:
                return post({**body, "response_format": {"type": "json_object"}})
            except urllib.error.HTTPError:
                return post(body)   # provider may not support response_format
        return post(body)
    return call


def _anthropic(api_key, models, default_model):
    def call(role, system, user, want_json=False, grounded=False):
        model = (models or {}).get(role) or default_model
        body = {"model": model, "max_tokens": 2048, "system": system,
                "messages": [{"role": "user", "content": user}]}
        if grounded:
            body["tools"] = [{"type": "web_search_20250305", "name": "web_search", "max_uses": 3}]
        req = urllib.request.Request(
            "https://api.anthropic.com/v1/messages", data=json.dumps(body).encode("utf-8"),
            headers={"content-type": "application/json", "x-api-key": api_key or "",
                     "anthropic-version": "2023-06-01"})
        with urllib.request.urlopen(req, timeout=300) as r:
            d = json.loads(r.read().decode("utf-8"))
        return "".join(b.get("text", "") for b in d.get("content", [])
                       if b.get("type") == "text").strip()
    return call


PROVIDERS = {
    "ollama":     {"base": "http://localhost:11434/v1", "env": None, "default": "llama3.1"},
    "groq":       {"base": "https://api.groq.com/openai/v1", "env": ("GROQ_API_KEY",), "default": "llama-3.3-70b-versatile"},
    "openrouter": {"base": "https://openrouter.ai/api/v1", "env": ("OPENROUTER_API_KEY",), "default": "meta-llama/llama-3.3-70b-instruct:free"},
    "gemini":     {"base": "https://generativelanguage.googleapis.com/v1beta/openai/", "env": ("GEMINI_API_KEY", "GOOGLE_API_KEY"), "default": "gemini-2.5-flash"},
    "openai":     {"base": "https://api.openai.com/v1", "env": ("OPENAI_API_KEY",), "default": "gpt-4o-mini"},
    "anthropic":  {"base": None, "env": ("ANTHROPIC_API_KEY",), "default": "claude-sonnet-5"},
}


def build_caller(cfg):
    prov = cfg.get("provider", "ollama")
    spec = PROVIDERS.get(prov)
    if not spec:
        raise ValueError("unknown provider: " + str(prov))
    key = (cfg.get("api_key") or "").strip()
    if not key and spec["env"]:
        for e in spec["env"]:
            if os.environ.get(e):
                key = os.environ[e]
                break
    default_model = cfg.get("model") or spec["default"]
    models = cfg.get("models") or None
    if prov == "anthropic":
        if not key:
            raise RuntimeError("No Anthropic API key — enter it in the dashboard or set ANTHROPIC_API_KEY.")
        return _anthropic(key, models, default_model)
    if prov == "ollama":
        key = key or "ollama"   # Ollama ignores the key but the header must exist
    if not key:
        raise RuntimeError("No API key for %s — enter it in the dashboard or set %s." % (prov, spec["env"][0]))
    return _openai_compatible(spec["base"], key, models, default_model)


# --------------------------------------------------------------------------- #
# HTTP server
# --------------------------------------------------------------------------- #
class Handler(BaseHTTPRequestHandler):
    def _send(self, code, ctype, body=b""):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        if body:
            self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            try:
                with open(os.path.join(HERE, "dashboard.html"), "rb") as f:
                    self._send(200, "text/html; charset=utf-8", f.read())
            except FileNotFoundError:
                self._send(500, "text/plain; charset=utf-8",
                           b"dashboard.html must sit next to dashboard_server.py")
        elif path == "/health":
            self._send(200, "application/json", b'{"ok":true}')
        else:
            self._send(404, "text/plain; charset=utf-8", b"not found")

    def do_POST(self):
        if self.path.split("?")[0] != "/api/council":
            self._send(404, "text/plain; charset=utf-8", b"not found")
            return
        try:
            n = int(self.headers.get("Content-Length", "0"))
            cfg = json.loads(self.rfile.read(n) or b"{}")
        except Exception as e:
            self._send(400, "application/json", json.dumps({"error": str(e)}).encode("utf-8"))
            return
        if not (cfg.get("question") or "").strip():
            self._send(400, "application/json", b'{"error":"no question"}')
            return

        # stream newline-delimited JSON as the council runs
        self.send_response(200)
        self.send_header("Content-Type", "application/x-ndjson; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.end_headers()

        q = queue.Queue()

        def run():
            try:
                call = build_caller(cfg)
                rec = council.council(
                    cfg["question"], call=call,
                    depth=cfg.get("depth", "deep"),
                    grounded=cfg.get("grounded"),
                    on_event=lambda name, status, data=None: q.put(
                        {"type": "event", "name": name, "status": status, "data": data}),
                )
                q.put({"type": "result", "record": rec})
            except urllib.error.URLError as e:
                q.put({"type": "error", "message": "Could not reach the model endpoint: %s. "
                       "Is the provider/key right? (For Ollama, is it running and the model pulled?)" % e})
            except Exception as e:
                msg = str(e)
                prov = cfg.get("provider", "ollama")
                if prov == "ollama":
                    msg += " — is Ollama running? Start it, then run:  ollama pull %s" % (cfg.get("model") or "llama3.1")
                elif "key" not in msg.lower():
                    msg += " — check the provider selection and API key."
                q.put({"type": "error", "message": msg})
            finally:
                q.put({"type": "done"})

        threading.Thread(target=run, daemon=True).start()
        while True:
            msg = q.get()
            try:
                self.wfile.write((json.dumps(msg) + "\n").encode("utf-8"))
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                break
            if msg.get("type") == "done":
                break

    def log_message(self, *a):
        pass  # keep the console quiet


def main():
    ap = argparse.ArgumentParser(description="Local visual dashboard for The Council.")
    ap.add_argument("--port", type=int, default=8787)
    ap.add_argument("--no-open", action="store_true", help="don't auto-open the browser")
    args = ap.parse_args()
    url = "http://localhost:%d" % args.port
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print("\n  The Council — dashboard running at  %s\n  (press Ctrl+C to stop)\n" % url)
    if not args.no_open:
        try:
            webbrowser.open(url)
        except Exception:
            pass
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  stopped.\n")


if __name__ == "__main__":
    main()
