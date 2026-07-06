① **Correctness — 2/2.** Squarely identifies the overlap: *"~34% of 'miss' shots land inside the rim's own radius — the ball's target point is still within the hoop opening, so it visually goes in even though the game logic flagged it a miss."* Matches the gold's core diagnosis.

② **Root-cause depth — 2/2.** Names the mechanism, not just "offset too small": *"Miss offset is sampled as independent uniform X/Z in a square `[-0.35, 0.35]²`"* and quantifies the overlap: *"P(land inside rim | miss branch) = π·0.23² / 0.7² ≈ 0.339"*. Per-axis square sampling vs. radial rim disk, with the same π·r² ratio the gold computes — full marks per the rubric's "quantifying the overlap" clause.

③ **Scope discipline — 1/2.** Fix is confined to the sampling function (polar form with a floor), no outcome re-rolls, no physics rewrite — good. But it imports speculative machinery the gold doesn't: *"const BALL_RADIUS := 0.12 # pull from your ball's actual collision shape"* and *"MAX_MISS_OFFSET := 0.6"* (enlarging the range vs. gold's 0.40), plus the whole *"It's worse than that…"* clearance tangent. That's unrequested expansion beyond fixing the sample space.

④ **Verifiability — 2/2.** Concrete red-on-old/green-on-new: *"sample the function 10,000 times, assert `offset.length() > RIM_RADIUS + BALL_RADIUS` for all of them (should be 100%, vs. the current ~34%/66% split)"* plus *"add the length assertion as an actual unit test … so a future change … can't silently reintroduce overlap."* Not "test it."

⑤ **Compression — 1/2.** Penalized for the muddled *"It's worse than that … Nearly every miss sample is at or inside the clearance threshold"* detour, hedging (*"presumably"*, *"should be 100%"*), a redundant third verify item, and the closing filler *"I don't have `shot.gd` open in this session … point me at the file/repo path."* Cuttable material present.

TOTAL: 8/10
