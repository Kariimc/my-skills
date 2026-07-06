# Loops

Bounded, repeatable agent workflows. Every loop file declares seven fields —
a loop missing any of them does not run:

**Outcome** (one sentence) · **Trigger** (schedule/event/manual) · **Scope**
(what it may read/change; everything else off-limits) · **Act** (one bounded,
reversible step per cycle) · **Verify** (the observable check, same every run) ·
**Stop** (terminal states: success / clean no-op / blocked / stagnated) ·
**Escalate** (what goes to Kariim, and how).

House rules: no loop sends external messages, force-pushes, deletes data, or
spends money without a human approval step. A loop that errors or exhausts its
budget reports that state by name — never as success. Two consecutive failed
cycles on the same item = stagnated → escalate, never a third silent retry.
