# The build loop — in detail

This is the end-to-end method the front door runs. Each step names the skill or tool
that owns it. The user never types a command; you run them.

## 1. Reference — start from taste, not a blank page

- Load `library/index.json`. Pick the 1–3 cards closest to the brief (by mood, not
  by industry — a fintech site can take its motion from a fashion house).
- If the library is empty, say so in one line and offer to harvest: "Your taste
  library is empty — send me the URLs (or your bookmarks export) and I'll build cards
  first." Never fabricate a reference.
- Read each chosen card's palette, type, motion notes, and layout signature. These are
  **inputs to** direction, not a spec to copy. Copying a reference 1:1 is failure; the
  job is to metabolize it into something specific to this brief.

## 2. Direction — commit to one POV before any CSS

Run this the way `frontend-design` does:

- Name one concrete subject, its audience, and the page's single job.
- Draft a compact token system: **color** (4–6 named hex), **type** (a characterful
  display face + a body face + optional utility face), **layout** (a concept in one
  sentence + an ASCII wireframe), **signature** (the one memorable element).
- Review the draft against the brief: if any part reads like the default you'd
  produce for any similar page, revise it and say what changed and why.
- AI-slop clusters to avoid unless the brief explicitly asks: cream `#F4F1EA` + serif +
  terracotta; near-black + single acid-green/vermilion; hairline broadsheet with zero
  radius. Legit for some briefs, defaults for none.
- Only after the direction is confirmed do you write code — derive every color and
  type decision from the committed tokens.

### Build wide, don't one-shot

Chase AI's core move: don't one-shot a single design and hope. **Generate several
directions wide, then narrow.** For anything where the look matters:

- Draft 2–4 genuinely different directions (not three shades of the same idea) — vary
  the signature, the type personality, the layout DNA.
- Prototype the top 2–3 far enough to judge them for real (a hero + one section each),
  not just describe them.
- Put them side by side, pick the strongest, and fold the best ideas from the runners-up
  into it. For a rigorous version, run the `harness-quality` judge panel.
- Then commit to the winner and take it all the way. Going wide early is cheaper than
  polishing the wrong direction late.

## 3. Build — implement for real

- Use `web-implementation` for a production site/app, or `web-artifacts-builder` for a
  shareable single-file claude.ai artifact.
- Build with the brief's **real** content and subject matter. If there's no copy,
  write it (see frontend-design's writing guidance) — templated copy makes a design
  feel as generic as templated layout.
- Watch CSS specificity: type-selectors (`.section`) vs element-selectors can cancel
  paddings/margins between sections. This bites most often on section rhythm.

## 4. View & tweak — hand over something the user can point at

See `preview-and-tweak.md`. The default is the `visual-prototype` Tweak & Comment
overlay: the user pins elements, exports one markdown block, you apply each pin
exactly and re-emit the whole file. For local in-browser variant generation, use
impeccable `live`.

## 5. Polish — run impeccable until it clears the floor

Invoke the vendored `impeccable` skill's passes:

- `impeccable audit` — technical quality (a11y, perf, responsive).
- `impeccable critique` — UX heuristic review with scoring.
- `impeccable polish` — final pass before shipping.
- Targeted: `bolder` / `quieter` (dial the intensity), `typeset`, `layout`, `colorize`,
  `distill`, `harden` (errors, i18n, edge cases), `animate`.

Loop until the audit is clean and the critique scores well. Screenshot as you go —
"a picture is worth 1000 tokens."

## 6. Motion — award tier, safe by construction

Run `premium-web-craft`'s loop: research the *current* award winners live, name the
concrete technique, propose in tiers, build tokens before effects, gate reduced-motion
from the start, verify in a real headless browser. Every effect in `quality-floor.md`'s
non-negotiables. Cut any effect that doesn't earn its frame budget.

## 7. Assets & deploy

- **Assets:** `assets.md` — generate hero imagery/video/3D via Higgsfield; never ship
  placeholder or lorem imagery when the brief needs real assets.
- **Deploy:** `deploy.md` — pick the path (Vercel MCP for a Next.js/static app,
  Higgsfield's `deploy_website` for its own bundles, or `web-deployment` for Docker/CI).
  Deploy is the one step you confirm with the user before running (it's outward-facing).

## Scope discipline

Match effort to the ask. "Make it nicer" → a few high-leverage moves (tokens, smooth
scroll, one real reveal, an impeccable `polish`). "Build me an award-tier site" → the
full loop with signature motion and a verification pass. Always keep the floor.
