# The quality floor — never negotiable

Every site clears this before it ships. Don't announce it; just clear it. This folds
together the non-negotiables from `premium-web-craft` and impeccable's craft floor.

## Accessibility

- Responsive down to a 320px phone; no horizontal scroll on the body.
- Visible keyboard focus on every interactive element — restyle focus rings, never
  remove them.
- Color contrast meets WCAG AA for text and meaningful UI.
- Decorative layers are `aria-hidden`; decorative text keeps its accessible name; no
  content is gated behind motion or hover.
- Real `alt` on meaningful images; empty `alt` on purely decorative ones.

## Motion (reduced-motion by construction)

- One `prefers-reduced-motion` gate; every effect collapses to a calm resting frame.
  Gate the effect, not the markup (no hydration mismatch).
- Animate `transform` / `opacity` / `clip-path` only. No animating layout properties.
- Drive with `requestAnimationFrame`, not per-event handlers; one shared loop/listener.
- Pause offscreen (IntersectionObserver) and on tab-hidden; cap DPR; WebGL low-power,
  single pass.
- No first-load full-page opacity fade — it hurts LCP. Run entrance transitions on
  client navigation, not first paint.

## Performance

- LCP not regressed by entrance effects; hero image sized and compressed.
- Below-the-fold images `loading="lazy"`; fonts subset and `font-display: swap`.
- No layout thrash; no giant unused CSS/JS shipped to the client.

## Runtime gotchas the compiler won't catch (verify in a real browser)

- IntersectionObserver inside `preserve-3d` / a rotated plane is unreliable —
  orchestrate reveals from a non-transformed parent (one observer + staggered variants).
- `transform` / `filter` / `perspective` on an ancestor breaks `position: fixed`
  descendants — page transitions use opacity on the content wrapper + a separate fixed
  overlay.
- `font-variation-settings` strings don't interpolate — animate a numeric CSS var or
  write the axis in rAF.
- Lenis vs CSS `scroll-behavior: smooth` conflict — let the smooth-scroll library own
  it; reduced-motion forces `auto`.
- `useReducedMotion()` is null until measured — collapse to a stable boolean.

## Verify, don't assert

Build passing is necessary but **not sufficient** — many of these only show at runtime.
Open the site headless, screenshot it, re-check with reduced motion emulated, and check
mobile width before calling it done. A picture is worth 1000 tokens.
