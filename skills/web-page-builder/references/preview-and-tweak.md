# View & tweak — the "point at it and change it" loop

The user wants to look at the site and change things by pointing at them, the way
Chase AI demonstrates. There are two surfaces; both keep the user out of the terminal.

## Primary: the `visual-prototype` Tweak & Comment overlay

The default and most reliable. It works in any browser and in the Artifact pane.

1. Build (or export) the page as a **single self-contained HTML file**.
2. Inject the review overlay per the `visual-prototype` skill (paste
   `assets/review-overlay.html` verbatim right before `</body>`, and wire the host
   contract: honor `--brand`, `--motion-scale`, and the `dark` class).
3. Deliver the file so it renders, and publish it as an Artifact so the user can click
   it side-by-side with chat.
4. The user arms **📍 Pin mode**, clicks any element, types the change, and hits
   **📤 Export** — one markdown block starting `## 🎯 Prototype Review Feedback`.
5. The user pastes that block back. Parse each pin
   (`` N. `selector` ("label") — requested change ``), map the selector to the source,
   apply exactly that change, and **re-emit the complete updated file** (never a diff
   the user has to splice). Preserve every working mechanic and the overlay.
6. Give a one-line summary mapping each pin number to what changed.

This is the loop to reach for by default: it needs nothing installed, survives the
Artifact sandbox (memory-only, no `localStorage`), and gives the user pins + region
screenshots + live theme/motion/brand tweaks for free.

## Deeper: impeccable `live` (in-browser variant generation)

When the user wants to pick an element **in the running site** and have variants
generated in place — closer to a design tool than a review overlay — use the vendored
impeccable skill's `live` mode:

- It starts a local live server, opens the site, and lets the user select an element.
- It generates visual alternatives for that element and applies the chosen one to the
  real source.
- Best for local dev with a running app; needs Node and a browser session.

Route here only when the pin-and-paste loop isn't enough — otherwise the overlay is
faster and works everywhere.

## Which to use

- Shareable mockup, remote review, or Artifact → **visual-prototype overlay**.
- Local running app, wants in-browser variant generation → **impeccable `live`**.
- Either way: never hand over a result the user has to describe changes to blind. The
  preview is the deliverable at step 4.
