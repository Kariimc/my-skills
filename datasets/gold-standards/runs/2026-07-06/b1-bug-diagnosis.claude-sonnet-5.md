## Root cause

Miss offset is sampled as independent uniform X/Z in a square `[-0.35, 0.35]²`, but the "does it go in" check is presumably `offset.length() < rim_radius` (0.23). For a uniform square sample, the offset's radius `r` is uniform-in-disk for `r < 0.35` (whole circle of radius `r` fits inside the square), so:

```
P(land inside rim | miss branch) = π·0.23² / 0.7² ≈ 0.339
```

**~34% of "miss" shots land inside the rim's own radius** — the ball's target point is still within the hoop opening, so it visually goes in even though the game logic flagged it a miss.

It's worse than that: regulation ball radius is ~0.12 m and rim radius is 0.23 m (matches your value — these are real-world dimensions). A shot only visually clears the rim if the ball's *center* misses by more than `rim_radius + ball_radius ≈ 0.35`. That's exactly the *upper bound* of your sampling range — so even the "corner" samples (max offset ≈ 0.35 on one axis, but often less on the diagonal) rarely clear it. Nearly every miss sample is at or inside the clearance threshold.

## Fix

Sample in polar coordinates with an explicit minimum clearance, instead of a uniform square:

```gdscript
const RIM_RADIUS := 0.23
const BALL_RADIUS := 0.12          # pull from your ball's actual collision shape
const MIN_MISS_CLEARANCE := RIM_RADIUS + BALL_RADIUS + 0.05   # buffer so it doesn't graze
const MAX_MISS_OFFSET := 0.6       # tune for how "wild" a miss can look

func _miss_target(rim_pos: Vector3) -> Vector3:
    var angle := randf_range(0.0, TAU)
    var radius := randf_range(MIN_MISS_CLEARANCE, MAX_MISS_OFFSET)
    var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
    return rim_pos + offset
```

This guarantees every sampled miss offset is strictly outside `rim_radius + ball_radius`, so the ball can never visually pass through the hoop while flagged as a miss.

## Verify

1. **Statistical check** — sample the function 10,000 times, assert `offset.length() > RIM_RADIUS + BALL_RADIUS` for all of them (should be 100%, vs. the current ~34%/66% split depending on which threshold you check against).
2. **In-game** — force the miss branch repeatedly (cheat/debug flag) and watch several reps in-editor; confirm none of them visually swish or drop through cleanly.
3. **Regression guard** — add the length assertion as an actual unit test (GUT or a `assert()` in a debug build) so a future change to the sampling can't silently reintroduce overlap with the rim radius.

I don't have `shot.gd` open in this session (no access to that project directory from here) — if you want me to apply this directly, point me at the file/repo path and I'll patch it in place.
