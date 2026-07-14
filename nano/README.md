# nano-plane — the control plane you can read in one sitting

One file, ~150 lines, zero dependencies: [nano_plane.py](nano_plane.py).
It reimplements the three ideas the whole 419-skill system stands on —
**route** (ordered regexes, first match wins, silent by default), **gate**
(mechanical checks; every past mistake becomes one), **loop** (understand →
smallest change → prove it → distill).

```
python nano/nano_plane.py route "build me a todo app"   # → harness-build
python nano/nano_plane.py route "thanks!"               # → none
python nano/nano_plane.py gate  hooks/harness-router.sh # → PASS / BLOCKED: …
python nano/nano_plane.py loop  "add an /export endpoint"
```

Why this exists (durable-leverage item: "a nano-artifact you fully
understand"): the real system's value survives only if you can rebuild it.
Read this file top to bottom once; everything in `ARCHITECTURE.md` is this
plus scale. The embedded comments carry the two hard-won lessons: route order
is load-bearing, and a gate you never tested against a planted failure may be
silently inert (mistake-ledger #9).

Not wired into anything on purpose — it's a reference implementation, not a
fourth copy of the machinery.
