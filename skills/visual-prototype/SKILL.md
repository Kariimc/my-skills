---
name: visual-prototype
description: >-
  Build a high-fidelity, fully interactive, single-file UI/UX prototype with a built-in
  "Tweak & Comment" review overlay (click-to-pin feedback, live markdown export, theme/
  brand/motion/density/viewport tweaks, and loading/empty/error/reset states). Use this
  whenever the user wants to prototype, mock up, design, wireframe, or visualize an app,
  screen, dashboard, game UI, landing page, component, or user flow they can click through
  and give feedback on — even if they don't say the word "prototype." Trigger it for "show
  me what X could look like," "make a clickable mockup," "design a UI for," "build a demo
  of this screen," or when iterating on a prototype from pasted review feedback. This is the
  default skill for visual front-end mockups meant for review and iteration, similar to
  Claude Design.
---

# Visual Prototype

You are an expert Frontend Engineer and Product Designer. Produce a high-fidelity,
interactive prototype the user can run instantly, click through, and annotate — then
iterate on it from their feedback. Every prototype ships with the same bundled review
overlay so the user always has the identical, working "Tweak & Comment" toolkit.

The value loop this skill protects:
**build → user clicks & pins feedback → user copies markdown → paste back → you iterate.**
Anything that breaks that loop (a broken overlay, a non-runnable file, lost mechanics on
iteration) is the main failure mode to avoid.

## Workflow

1. **Clarify only if blocked.** If the request is concrete enough to build, build. If a
   load-bearing detail is genuinely missing (core purpose, key screens), ask one tight
   question — don't interrogate. Reasonable assumptions beat a stalled prototype; state
   them inline.
2. **Pick the delivery format** (see below). Default to single-file HTML.
3. **Design with real tokens.** Read `references/design-tokens.md` and use a token-driven
   style so the prototype looks intentional, not templated, AND so the overlay's live
   theme/brand/motion controls actually work. Define `--brand` and honor `--motion-scale`.
4. **Build the app** with working mechanics — every button, input, tab, dropdown, and nav
   flow functions on realistic mock data. Include real `loading`, `empty`, and `error`
   branches in the markup (don't just describe them).
5. **Wire the host contract** so the overlay can drive the app: register
   `window.__proto.onState(s => /* render loading|empty|error|ready */)`, consume
   `var(--brand)` and `var(--motion-scale)`, and react to the `dark` class on `<html>`.
6. **Inject the overlay.** Paste the **entire** contents of `assets/review-overlay.html`
   verbatim, immediately before `</body>`. Do not rewrite or summarize it — it is the
   source of truth for the review tool. (`assets/starter-template.html` shows the full
   wiring if you want a shell to start from.)
7. **Deliver as a file and present it** (see Delivery). Briefly tell the user how to use
   the overlay (open ✎ bottom-right → Pins to annotate → Export to copy feedback).
8. **Iterate** when feedback comes back (see Iteration).

## Delivery format

**Default — single self-contained HTML file** (Tailwind via CDN + Alpine.js or vanilla JS).
Most reliable: it renders directly, the vanilla overlay attaches to any DOM, and it's one
artifact to iterate on. Choose this unless the user needs React.

**React/JSX** when the user explicitly wants React or a component for their codebase. Build
the component, then mount the overlay once after render via a small bootstrap effect that
injects `assets/review-overlay.html`'s markup+script into `document.body` (the overlay reads
the live DOM, so it works regardless of framework). Still honor `--brand` / `--motion-scale`
and the `__proto.onState` contract.

### Where output goes
In this environment, **write the prototype to a file** in `/mnt/user-data/outputs/` (e.g.
`prototype.html` or `Component.jsx`) and present it with the file tool so it renders and is
downloadable — don't dump a huge file inline. Keep all CSS/JS in the one file. **Never use
`localStorage`/`sessionStorage`** in the output (it fails in the artifact sandbox); the
bundled overlay is already memory-only — keep app state in memory too.

## The bundled overlay — what the user gets, automatically

Injecting `assets/review-overlay.html` gives every prototype, with zero extra work:
- **📍 Pin mode** — arm it, click any element to drop a numbered pin; captures a readable
  CSS selector + the element's text. Click a pin to edit, trash to delete.
- **📷 Region screenshot** — drag to select any region; the overlay hides itself, rasterizes
  that region (lazy-loading html2canvas from CDN on first use), and downloads a PNG the user
  can paste into chat. The exported markdown notes how many shots were taken.
- **📤 Markdown export** — compiles all pins + a global-notes box into one clean block with
  a fixed header (`## 🎯 Prototype Review Feedback`) and a one-click Copy.
- **🎚 Tweaks** — live Dark/Light, brand-color picker (`--brand`), motion Normal/Fast/Off,
  density Comfortable/Compact, viewport Mobile/Tablet/Full, element-outline debug.
- **State + reset** — buttons to simulate Ready/Loading/Empty/Error (drives
  `window.__proto.onState`) and a Reset that clears pins and restores all tweaks.

You don't reimplement any of this — paste it and wire the contract.

## Iteration contract

When the user pastes a block that begins with **`## 🎯 Prototype Review Feedback`**, treat
it as a structured change order:
- Parse each numbered pin: ``N. `selector` ("label") — requested change``. Map the selector
  to the element in the current single-file source and apply exactly that change.
- Apply the **Global notes** section as broader direction.
- If the user attached **region screenshots** (the markdown's Screenshots section flags them),
  use them as the visual ground truth for the requested changes.
- **Preserve every working mechanic, the overlay, and the host contract** unless the
  feedback explicitly says to change them. Re-emit the *complete* updated file — never a
  fragment or a diff the user has to splice.
- After applying, give a one-line summary mapping each pin number to what you changed.

For freeform feedback (not the markdown block), apply it the same way: full file back,
mechanics preserved, short change summary.

## Quality bar before you ship

- Runs instantly with no console errors; the ✎ overlay opens and pinning works.
- `--brand`, dark mode, and `--motion-scale` controls visibly affect the UI.
- `loading` / `empty` / `error` states are real and reachable via the simulator.
- Looks intentionally designed (ran the `references/design-tokens.md` checklist), not like
  a default Tailwind page.
- Single runnable file, delivered via the file tool, no browser storage.
