## Root cause

The miss offset is sampled from a **square** that fully contains the make zone. You add `Vector3(randf_range(-0.35,0.35), 0, randf_range(-0.35,0.35))` — a point uniformly distributed over the 0.7 × 0.7 square centered on `rim_pos`, at rim height (`y = 0`). Nothing forces that point to land *outside* the rim.

The rim is a circle of radius 0.23 centered at the same point. So any sampled offset whose horizontal distance from center is under 0.23 targets a spot **inside the hoop** — the ball drops through and reads as a clean make.

How often that happens:

- square area = 0.7² = 0.49
- rim-circle area = π·0.23² = 0.166
- fraction inside = 0.166 / 0.49 ≈ **34%**

So roughly a third of your "misses" aim through the rim (more, once you count the ball's own radius — an offset a hair beyond 0.23 can still swish). The scatter distribution and the make region overlap; that overlap is the bug. The `y=0` component makes it worse by putting every miss at exactly make height.

## Fix

Sample the offset from an **annulus** whose inner radius clears the rim, using polar coordinates instead of a box:

```gdscript
const RIM_RADIUS := 0.23
const BALL_RADIUS := 0.12          # set to your actual ball radius
const MISS_MIN := RIM_RADIUS + BALL_RADIUS + 0.02   # inner edge: ball can't fit through
const MISS_MAX := 0.50                               # outer scatter bound

var angle := randf() * TAU
# sqrt keeps points area-uniform instead of clustering at the inner ring
var r := sqrt(randf_range(MISS_MIN * MISS_MIN, MISS_MAX * MISS_MAX))
var offset := Vector3(cos(angle) * r, 0.0, sin(angle) * r)
var target := rim_pos + offset
```

Key change: `MISS_MIN > RIM_RADIUS + BALL_RADIUS`, so no sampled target can pass through the hoop. The `+ BALL_RADIUS` margin matters — a target at exactly the rim radius still lets the ball edge catch and fall in.

If you want misses that rattle out (hit rim, bounce away) as a separate flavor, generate those explicitly with their own logic — don't leave it to the tail of a box distribution.

## How to verify

1. **Unit/statistical test on the generator** — sample the miss target 10,000× and assert the horizontal distance from `rim_pos` for every sample is `>= MISS_MIN`:

   ```gdscript
   for i in 10000:
       var t := make_miss_target(rim_pos)
       var d := Vector2(t.x - rim_pos.x, t.z - rim_pos.z).length()
       assert(d >= MISS_MIN)
   ```
   Run it against the **old** code first: it should fail on ~34% of samples (the red proof the bug exists). Against the new code: zero failures.

2. **End-to-end scoring check** — force 100 consecutive misses (stub the make/miss roll to always-miss) and assert the score counter stays 0 and the make-detector never fires. Before the fix this fires ~1 in 3; after, never.

3. **Eyeball it** — spawn a debug marker at each computed target and shoot a batch of misses; every marker should sit visibly outside the rim ring, none inside it.

One thing I couldn't check: the actual `BALL_RADIUS` and whether your make-detection keys off the ball passing the rim plane vs. an Area3D trigger. Plug in the real ball radius, and if makes are detected by a trigger volume wider than 0.23, widen `MISS_MIN` to clear *that* instead.
