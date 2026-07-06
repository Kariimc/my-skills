The miss offset is sampled per-axis from a square of half-width 0.35 centered
on the rim, so any sample landing within 0.23 m of center — roughly
π·0.23²/0.70² ≈ 34% of the square — produces a "miss" whose flight path passes
through the hoop: a visual swish scored as a miss. Root cause: the offset
sample space includes the rim disk.

Fix — sample in polar form with a floor outside the rim:
`angle = randf()*TAU; radius = randf_range(rim_radius + 0.05, 0.40);
offset = Vector3(cos(angle), 0, sin(angle)) * radius`

Verify: unit test asserting 10k sampled miss offsets all satisfy
`offset.length() > rim_radius` (red on old code, green on fix), plus one
visual run confirming misses now clank or rim out.
