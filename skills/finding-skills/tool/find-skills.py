#!/usr/bin/env python3
"""Given a task, return the top-k existing skills that likely apply.
Consult BEFORE building from scratch or saying "can't" (rule 09).

Source order (mirrors relay): local clone first, else public raw URL.
  local : ./index.json next to this file, or --index PATH
  remote: raw.githubusercontent.com/Kariimc/my-skills/<branch>/skills/finding-skills/index.json
Usage:
  find-skills.py "make an angular component with signals"
  find-skills.py -k 8 --json "extract tables from a scanned pdf"
  find-skills.py --remote "..."            # force fetch over public API
"""
import argparse, json, os, re, sys, urllib.request

STOP = set("a an the to of for and or with in on into from your my me i it "
           "how do does can could should would when what which that this "
           "make build create get set use using need want help via".split())
BRANCH = "master"  # my-skills default branch (relay repo is 'main')
RAW = f"https://raw.githubusercontent.com/Kariimc/my-skills/{BRANCH}/skills/finding-skills/index.json"

def stem(t):
    for suf in ("ies", "ing", "ers", "er", "ed", "es", "s"):
        if t.endswith(suf) and len(t) - len(suf) >= 3:
            return t[:-len(suf)] + ("y" if suf == "ies" else "")
    return t

def toks(s):
    return [stem(t) for t in re.split(r"[^a-z0-9]+", (s or "").lower())
            if len(t) > 1 and t not in STOP]

def load(args):
    if not args.remote:
        here = os.path.dirname(os.path.abspath(__file__))
        cands = [args.index] if args.index else []
        cands += [os.path.join(here, "index.json"),
                  os.path.join(here, "..", "index.json"),
                  os.path.join(os.getcwd(), "index.json")]
        for c in cands:
            if c and os.path.isfile(c):
                return json.load(open(c, encoding="utf-8"))
    with urllib.request.urlopen(RAW, timeout=15) as r:      # public repo, no auth
        return json.loads(r.read().decode("utf-8"))

def score(qtoks, qraw, row):
    name, desc = toks(row["name"]), toks(row["description"])
    nset, dset, q = set(name), set(desc), set(qtoks)
    s = 3 * len(q & nset) + 1 * len(q & dset)
    blob = (row["name"] + " " + row["description"]).lower()
    for a, b in zip(qtoks, qtoks[1:]):                       # bigram phrase bonus
        if f"{a} {b}" in blob:
            s += 2
    return s

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("query", nargs="+")
    ap.add_argument("-k", type=int, default=5)
    ap.add_argument("--index"); ap.add_argument("--remote", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    q = " ".join(a.query); qt = toks(q)
    rows = load(a)
    ranked = sorted(((score(qt, q, r), r) for r in rows), key=lambda x: (-x[0], x[1]["name"]))
    hits = [{"name": r["name"], "path": r["path"], "score": s,
             "description": r["description"]} for s, r in ranked[:a.k] if s > 0]
    if a.json:
        print(json.dumps(hits, ensure_ascii=False)); return
    if not hits:
        print("NO SKILL MATCH — none of the 418 apply. Only now may you say "
              "\"can't\", and name the exact missing access (token/connector/surface)."); return
    for h in hits:
        d = h["description"][:110] + ("…" if len(h["description"]) > 110 else "")
        print(f"[{h['score']:>2}] {h['name']:<28} {h['path']}\n     {d}")

if __name__ == "__main__":
    main()
