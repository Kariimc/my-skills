---
name: tests-bite
description: Enforces that every new test provably fails when the guard it covers is removed — the revert→red→restore→green ritual — so test suites catch real regressions instead of passing vacuously. Use when writing or reviewing ANY test, in any language, especially tests guarding money paths, data integrity, or security checks.
---

# Tests-Bite

A test that passes against broken code is worse than no test — it's false
confidence. Every test you write must be PROVEN to bite, once, before you ship it.

**The ritual (non-negotiable for money/data/security paths):**
1. Write the test against the FIXED code → green.
2. Revert the guard it covers (stash the fix / comment the check) → run → **must go RED**.
3. Restore the fix → green again.
4. Paste the red-run output in your PR/report. That paste is the proof; a claim
   without it doesn't count.

## pytest template
```python
def test_credit_never_negative(db):
    """BITE-PROOF: reverting the remaining>=amount guard in consume_ai_credit
    makes this fail (verified 2026-07-06, output in PR)."""
    seed_credits(db, user_id=U, amount=1)
    assert consume(db, U, 1) is True
    assert consume(db, U, 1) is False        # second consume must be rejected
    assert credits_of(db, U) == 0            # never driven negative
```

## jest template
```ts
test("replayed webhook is idempotent (BITE-PROOF: remove event-id dedupe → fails)", async () => {
  const evt = signedEvent({ id: "evt_1", type: "entitlement.granted" });
  await handle(evt);
  await handle(evt);                          // exact replay
  expect(await entitlementCount(user)).toBe(1);
});
```

Scope note: prove-the-bite once per guard, not per run — the docstring/name
records that it was done and when. For trivial pure-function tests the ritual
is optional; for anything touching money, auth, storage, or deletion it is
mandatory.
