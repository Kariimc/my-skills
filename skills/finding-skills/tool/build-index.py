#!/usr/bin/env python3
"""Scan skills/*/SKILL.md -> index.json = [{name, description, path}].
One committed index means remote consult is ONE fetch, not 418."""
import json, os, re, sys

def frontmatter(text):
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end]
    out, key, buf = {}, None, []
    for line in block.splitlines():
        m = re.match(r"^([A-Za-z0-9_-]+):\s?(.*)$", line)
        if m:
            if key:
                out[key] = " ".join(buf).strip()
            key, buf = m.group(1), [m.group(2)]
        elif key and (line.startswith((" ", "\t")) or line.strip()):
            buf.append(line.strip())
    if key:
        out[key] = " ".join(buf).strip()
    return out

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "skills"
    # Default beside the finder, NOT in the caller's cwd — a stray index.json at
    # the repo root looks like success while find-skills.py keeps reading the old
    # one, which is exactly how new skills went missing before (playbook P-12).
    out_path = sys.argv[2] if len(sys.argv) > 2 else \
        os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "index.json")
    rows = []
    for d in sorted(os.listdir(root)):
        p = os.path.join(root, d, "SKILL.md")
        if not os.path.isfile(p):
            continue
        fm = frontmatter(open(p, encoding="utf-8").read())
        name = fm.get("name") or d
        desc = fm.get("description", "")
        rows.append({"name": name, "description": desc, "path": f"skills/{d}/SKILL.md"})
    json.dump(rows, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"indexed {len(rows)} skills -> {out_path}")

if __name__ == "__main__":
    main()
