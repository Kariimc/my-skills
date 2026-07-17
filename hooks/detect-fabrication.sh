#!/bin/bash
# detect-fabrication.sh — pure detector. Reads a unified diff on STDIN.
#
# EXIT CONTRACT (load-bearing):
#   1 = fabrication found. NOTHING else may exit 1.
#   0 = clean OR any internal error (fail open).
# Deliberately NO `set -e`/`set -euo pipefail`: it is the house idiom in this
# repo and it is WRONG here. Any incidental command failure would exit
# non-zero, and callers read non-zero as "fabrication found" -> a false block
# on the guard's own bug. Errors must be indistinguishable from clean.
#
# Runs no git of its own — the caller supplies the diff. That is what lets the
# Stop hook (session scope) and CI (PR scope) share one set of patterns.

GUARD_PY=""
for cand in \
  "$LOCALAPPDATA/Python/pythoncore-3.14-64/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python313/python.exe" \
  "$LOCALAPPDATA/Programs/Python/Python312/python.exe"; do
  [ -x "$cand" ] && GUARD_PY="$cand" && break
done
if [ -z "$GUARD_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then GUARD_PY=python3
  elif command -v python >/dev/null 2>&1; then GUARD_PY=python
  else exit 0
  fi
fi

# The heredoc below occupies python's stdin, so the diff CANNOT be piped
# straight through — it would be swallowed and the detector would silently see
# an empty diff and pass everything. Spool stdin to a temp file, pass the path.
tmp="$(mktemp 2>/dev/null)" || exit 0
cat > "$tmp" 2>/dev/null || { rm -f "$tmp"; exit 0; }

"$GUARD_PY" - "$tmp" <<'PY'
import sys, re, posixpath

PROSE_EXT = (".md", ".txt", ".rst")

ANY = ["rest of code remains the same", "insert logic here",
       "implementation goes here", "your code here", "unchanged code",
       "... rest of", "remaining code"]

# Case-sensitive; not when glued to _ or - so TODO_LIMIT / todo-list stay legal.
CODE = re.compile(r"(?<![A-Za-z0-9_])(TODO|FIXME|XXX)(?![A-Za-z0-9_-])")

ANYWHERE = ("node_modules/", "vendor/", "dist/", "build/", ".git/")
LOCKS = ("package-lock.json", "yarn.lock", "pnpm-lock.yaml", "poetry.lock",
         "cargo.lock", "go.sum", "composer.lock")

def skipped(path):
    low = path.lower()
    if any(f in low for f in ANYWHERE):
        return True
    base = posixpath.basename(low)
    if base in LOCKS or base.startswith("todo."):
        return True
    # ANCHORED to repo root. Unanchored "hooks/" would also swallow
    # src/hooks/useAuth.ts in every React repo — the guard would report clean
    # while reading almost nothing. Anchor it, or it lies.
    if low.startswith("hooks/") or low.startswith("bin/selftest"):
        return True
    if base == "selftest-guards.sh":
        return True
    return False

def main():
    try:
        with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
            data = f.read()
    except Exception:
        return 0
    hits, cur = [], None
    for ln in data.split("\n"):
        if ln.startswith("+++"):
            p = ln[3:].strip()
            if p.startswith("b/"):
                p = p[2:]
            cur = None if p in ("/dev/null", "") else p
            continue
        if ln.startswith(("---", "@@", "diff ", "index ")):
            continue
        if not ln.startswith("+") or cur is None or skipped(cur):
            continue
        body = ln[1:]
        s = body.strip()
        # A line whose entire body is "..." is valid Python (Protocol stubs,
        # @overload, Ellipsis). Never a hit. "... rest of" is prose and still is.
        if s == "...":
            continue
        low = s.lower()
        hit = any(p in low for p in ANY)
        if not hit and not cur.lower().endswith(PROSE_EXT):
            hit = bool(CODE.search(body))
        if hit:
            hits.append("%s: %s" % (cur, s))
    for h in hits:
        sys.stdout.write(h + "\n")
    return 1 if hits else 0

try:
    sys.exit(main())
except SystemExit:
    raise
except Exception:
    sys.exit(0)
PY
rc=$?
rm -f "$tmp" 2>/dev/null
# Any exit other than a clean 0/1 from python (crash, signal) means the
# detector itself broke -> report clean. Only a real hit may return 1.
[ "$rc" = "1" ] && exit 1
exit 0
