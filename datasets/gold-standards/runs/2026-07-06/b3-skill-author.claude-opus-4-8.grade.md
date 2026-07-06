① **Correctness — 2/2.** Valid frontmatter: `name: plan-gate` plus a description closing on a proper trigger — `"Use when about to make any non-trivial edit — code, config, migration, doc — before the first change."` All five plan lines present and labeled: `**Goal**`, `**Unknowns**`, `**Success criteria**`, `**Step order**`, `**Rollback**`.

② **Root-cause depth — 2/2.** The unknowns line forks both ways correctly: `"Code holds it → READ IT NOW. Only the user holds it → STOP, ask that one question, wait."` Code-holds → read now; user-holds → stop and ask. Fork intact.

③ **Scope discipline — 2/2.** Stays a plan gate throughout. No generic productivity advice, no added ceremonies; the closing section names one on-topic anti-pattern — `"'while I'm here I'll also refactor X.' If X isn't in the plan, it's a new task: note it, don't do it."` The surrounding framing about duplication is delivery, not smuggled into the skill body.

④ **Verifiability — 2/2.** The worked example's done bar is an observable red/green check: `"Done bar: new test `miss_offset_outside_rim` is red on old code, green on fix."`

⑤ **Compression — 2/2.** Skill body is executable-by-reading — `"No edit before the plan. Write these five lines, in order, then execute them"` — no essays inside the skill, no repeated ideas. The failure mode `"Half-understood changes and silent scope drift"` names distinct concerns rather than restating.

TOTAL: 10/10
