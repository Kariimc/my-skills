# ADR 0004 — Model-agnostic orchestration: seam, not rewrite

- **Status:** accepted 2026-07-03
- **Driver:** item #14 of the durable-leverage list — "never hostage to one
  vendor's availability again."

## Context

The control plane is Claude-Code-native end to end: the six harnesses assume
Claude Code's Skill/Agent tools, `hooks/harness-router.sh` is a Claude Code
UserPromptSubmit hook, and the gates run in git hooks + CI (vendor-neutral
already). One genuinely provider-agnostic artifact exists:
`skills/council-moa/scripts/council.py` (+ `council.ts`) — a runnable
Mixture-of-Agents engine with a dependency-injected `call(role, system, user)`
seam and built-in callers for Anthropic, OpenAI, and any OpenAI-compatible
endpoint (local models included).

## Options

1. **Port the harnesses to a provider-agnostic framework now.** Cost: weeks;
   re-platforms working, gate-tested machinery onto abstractions with no second
   user today. Classic complexity-doesn't-pay-rent.
2. **Do nothing.** Keeps the vendor coupling invisible until the day it hurts.
3. **Seam, not rewrite (chosen).** Keep the harnesses Claude-Code-native —
   that IS the platform — and formalize `council-moa`'s `call()` seam as the
   documented escape hatch. The durable assets are already vendor-neutral:
   playbooks/wiki (markdown), evals (`bin/eval-router.sh` + `datasets/` run
   with bash+python), gates (bash), ADRs, scaffolds.

## Decision

Option 3. Vendor independence lives in three layers, cheapest first:
1. **Assets** — everything in `brain/wiki`, `datasets/`, `adr/`, `.claude/evals/`
   is plain text + bash/python; portable to any agent by copy-paste.
2. **Seam** — for multi-model work, route through `council-moa`'s `call()`
   (Anthropic / OpenAI / OpenAI-compatible local). Adding a provider = one
   caller function, no orchestration change.
3. **Port price list** (what moving a harness would actually cost): router →
   trivial (pure regex, any hook system); gates → free (git-native);
   harness skills → rewrite the Skill/Agent dispatch layer only, the loop
   *logic* is prose any agent framework can follow.

## Consequences

- No day-6 rewrite; switching cost is bounded and written down.
- The eval suite (182-case router dataset) doubles as the acceptance test for
  any future port.
- Accepted risk: harness *ergonomics* (auto-routing, parallel subagents) are
  lost on other platforms until someone pays the port price.

**Revisit trigger:** Claude Code access becomes unreliable/unavailable, or a
second agent platform is in weekly use, or council-moa's seam gets a third
call site (then extract it to a shared lib).
