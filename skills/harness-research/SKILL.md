---
name: harness-research
description: >-
  The Research/Verify Harness — fan out parallel searches, fetch sources,
  adversarially verify each claim, then synthesize a cited answer. Every
  non-trivial claim is checked against a source before it ships; nothing is
  asserted from memory. Use when the user wants to research, investigate,
  compare options, analyze a market or competitor, or get a fact-checked,
  sourced report on any topic.
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

# Research / Verify Harness

Fan out → fetch → adversarially verify → synthesize with citations. The
discipline: no claim survives without a source, and claims are checked by an
agent other than the one that made them.

## When to use
- "Research / investigate / compare / what's the best …"
- Competitive landscape, market analysis, OSINT, technical due diligence.
- Anything where being *wrong but confident* is the failure mode.

## The loop

```
QUESTION → fan-out searches → fetch sources → VERIFY each claim → synthesize (cited)
                                                   │ refuted?
                                                   └─▶ drop or re-research
```

### 1. Scope
- If the question is underspecified (budget, region, use-case missing), ask
  2–3 clarifying questions before spending — don't guess the scope.

### 2. Fan out (multi-modal)
- Dispatch parallel searches across different angles so each is blind to the
  others: `WebSearch`, `exa-search`, `web-scraper`, `osint-research`,
  domain skills (`market-research`, `youtube-research`, `sports-scraper`, …).

### 3. Fetch
- Pull the actual sources (`WebFetch`) — read primary material, not snippets.

### 4. Verify (adversarial)
- For each material claim, spawn an independent checker prompted to **refute**
  it. Default to "unverified" when a source can't be found. Drop or re-research
  anything that fails.

### 5. Synthesize
- Write the answer with inline citations. State confidence and what's still
  unverified. A "completeness critic" pass asks: what source/angle is missing?

## Competitive pipeline shortcut
For competitor work, chain the purpose-built trio:
`competitive-platform-analysis` → `benchmark-methodology` →
`competitive-report-structure`.

## Output contract

The final answer MUST separate what's known from what isn't:

```
ANSWER:     <the synthesis — every non-trivial claim ends with [n]>
SOURCES:    [n] = <title — URL — date accessed>
CONFIDENCE: <high/medium/low per major claim, one line each>
UNVERIFIED: <claims that survived on one source or none — listed, not blended in>
MISSING:    <the angle/source a completeness pass says wasn't covered>
```

Worked example claim + source pair:
`Micro-SaaS template stores commonly monetize via one-time tiers around $99–299 [3]`
`[3] Freemius — State of Micro-SaaS 2025 — https://freemius.com/... — accessed 2026-07-03`

Hard rules for a mid-tier executor: never cite a source you didn't fetch;
a claim with no source goes under UNVERIFIED, never in ANSWER; when two
sources conflict, show both with dates instead of picking silently.

## Related
`deep-research` (full harness), `exa-search`, `iterative-retrieval`,
`research-ops`.
