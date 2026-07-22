# Apex Gates — the manifest

The declarative source of truth for every control-plane gate. Each gate is
implemented exactly once in [`bin/apex-gates.sh`](../bin/apex-gates.sh) and runs
at every enforcement point below. `selfintegrity` cross-checks this table against
the implementation, so a gate listed here that loses its code is itself a failure.

| Gate | Implementation | Prevents (real mistake from the record) | commit | push | CI |
|---|---|---|:--:|:--:|:--:|
| Metadata integrity | `gate_doctor` | stale counts, trigger-less skills, name≠folder, overlap | ✓ | ✓ | ✓ |
| Hook safety | `gate_hooklint` | broken hooks, the heredoc-ate-stdin router bug | ✓ | ✓ | ✓ |
| Secret hygiene | `gate_secrets` | credentials / keys committed to history | ✓ | ✓ | ✓ |
| Self-integrity | `gate_selfintegrity` | the guards being deleted, gutted, or un-wired | ✓ | ✓ | ✓ |
| Ratchet checks | `gate_extra` | recurrence of any mistake captured in the ledger | ✓ | ✓ | ✓ |
| Liveness | `gate_live` | "is it actually synced & firing?" uncertainty | – | ✓ | – |

Severity: **HARD** failures block the action; **soft** issues warn only.

**Doc-only fast path:** `gate_doctor` re-scans the whole skill library (slow). A
commit or push whose change set touches no `skills/` or `agents/` files cannot
move that metadata, so doctor is **skipped** for it (the run prints
`doctor … skipped`). This is not a bypass — doctor runs the instant a skill or
agent is touched, and every other gate always runs. It exists so doc-only
commits don't wait minutes for a check that can't fail.

## Enforcement points
- **pre-commit** (`.githooks/pre-commit`) — auto-heals safe drift, then runs the
  gate suite scoped to staged files. Blocks on HARD.
- **pre-push** (`.githooks/pre-push`) — full gate suite; **warns** (does not
  block) on a direct push to `master`. Blocks on HARD.
- **CI** (`.github/workflows/apex.yml`) — mirrors the suite on every PR/push to
  `master`, so the trunk is protected even if local hooks are bypassed.

## The ratchet
New mistake classes are appended to [`MISTAKE-LEDGER.md`](./MISTAKE-LEDGER.md) and
converted into new gates by `bin/apex-ratchet.sh`. A mistake happens at most once;
then it is permanently gated here.

### The behavioral lane
The ratchet covers **behavioral** mistakes, not just repo-state ones. When an
agent violates an operating rule (ships legwork, skips a skill phase, claims
done without proof), the ratchet entry's check asserts the *machinery* that
prevents recurrence: that the relevant guard hook exists, is registered, and
still blocks its test case (`hooks/selftest-guards.sh` is the assertion
vehicle — a check can simply run the relevant selftest line). Rule-of-thumb:
a behavioral mistake ratchets into a hook + a selftest line; a repo-state
mistake ratchets into an `apex/checks/*.sh` assertion. Both land in the
mistake ledger either way. The rules→machinery inventory lives in
[`../docs/RULES-ENFORCEMENT-MAP.md`](../docs/RULES-ENFORCEMENT-MAP.md).
