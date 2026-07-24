#!/usr/bin/env python3
"""
import_bookmarks.py — pull URLs from a Chrome/Firefox/Safari bookmarks export.

Export your bookmarks to HTML (Chrome: Bookmarks > Bookmark manager > ⋮ > Export),
then:

  python3 import_bookmarks.py bookmarks.html                       # list every URL
  python3 import_bookmarks.py bookmarks.html --folder "Bookmarks bar"   # only that folder
  python3 import_bookmarks.py bookmarks.html --harvest             # harvest each into a card
  python3 import_bookmarks.py bookmarks.html --folder "Web Design" --harvest

The bookmarks file is a standard Netscape-bookmark HTML; folders are <H3> headings and
links are <A HREF>. --folder matches a folder name (case-insensitive substring) and
takes the links under it. --harvest calls harvest_site.py on each URL.
"""
import sys, os, re, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))


def parse(html, folder=None):
    """Return list of (title, url). If folder given, only links under a matching <H3>."""
    if folder is None:
        pairs = re.findall(r'<A[^>]*HREF="([^"]+)"[^>]*>(.*?)</A>', html, re.I | re.S)
        return [(re.sub(r"<[^>]+>", "", t).strip(), u) for u, t in pairs
                if u.startswith("http")]
    # Folder scoping: find the <H3>folder</H3>, then the <DL>...</DL> block that follows.
    out = []
    for m in re.finditer(r"<H3[^>]*>(.*?)</H3>", html, re.I | re.S):
        name = re.sub(r"<[^>]+>", "", m.group(1)).strip()
        if folder.lower() not in name.lower():
            continue
        rest = html[m.end():]
        dl = re.search(r"<DL>(.*)", rest, re.I | re.S)
        if not dl:
            continue
        # Balance <DL> nesting to capture just this folder's block.
        depth, i, block = 0, 0, dl.group(1)
        chunk = []
        for tok in re.split(r"(<DL>|</DL>)", block, flags=re.I):
            if re.match(r"<DL>", tok, re.I):
                depth += 1
            elif re.match(r"</DL>", tok, re.I):
                if depth == 0:
                    break
                depth -= 1
            chunk.append(tok)
        sub = "".join(chunk)
        pairs = re.findall(r'<A[^>]*HREF="([^"]+)"[^>]*>(.*?)</A>', sub, re.I | re.S)
        out.extend((re.sub(r"<[^>]+>", "", t).strip(), u) for u, t in pairs
                   if u.startswith("http"))
    return out


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    path = args[0]
    folder = None
    harvest = "--harvest" in args
    if "--folder" in args:
        folder = args[args.index("--folder") + 1]
    if not os.path.exists(path):
        print("no such file: " + path)
        return
    html = open(path, encoding="utf-8", errors="replace").read()
    pairs = parse(html, folder)
    # dedupe by url, keep order
    seen, uniq = set(), []
    for t, u in pairs:
        if u not in seen:
            seen.add(u)
            uniq.append((t, u))
    print("# %d bookmarks%s" % (len(uniq), (" under '%s'" % folder) if folder else ""))
    for t, u in uniq:
        print("%s\t%s" % (u, t))
    if harvest and uniq:
        print("\nHarvesting %d sites..." % len(uniq))
        subprocess.run([sys.executable, os.path.join(HERE, "harvest_site.py")]
                       + [u for _, u in uniq])


if __name__ == "__main__":
    main()
