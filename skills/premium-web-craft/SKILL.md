---
name: premium-web-craft
description: Research the current award-winning web (Awwwards / FWA / CSS Design Awards / Godly + top motion studios) and apply bleeding-edge, accessible visual + motion techniques to any project; optionally harvest them into a reusable component library. Use for high-end animations/transitions, elevating a site to award tier, studying how the best sites are built, or building a UI/UX library. Every effect ships reduced-motion-safe, performant, and accessible — no slop.
---

# Premium Web Craft

A loop for taking a site to award-tier visuals: research the live state of the art, audit, propose in tiers, build, tune, verify in a real browser, harvest. The gates apply to every effect.

## The loop
1. **Research (live, not memory).** Award winners change monthly — WebSearch the *current* ones and name the concrete technique behind each ("scroll-velocity flowmap on a WebGL plane", not "nice animations"). Cross-check sources; discard hype.
2. **Audit.** Read the current tokens/motion/reduced-motion story. Name what's cheap and why (usually: one duration, one easing, one reveal everywhere; no page transitions; nothing reacts to scroll velocity).
3. **Propose in tiers** (below). Short menu, recommended first move, let the user pick scope.
4. **Build** tokens before components; gate reduced-motion from the start.
5. **Tune** magnitudes; fix any LCP/perf regression you introduce.
6. **Verify in a real browser** (headless). Build passing is necessary but NOT sufficient — many of these bugs only show at runtime. Re-check with reduced motion emulated.
7. **Harvest** reusable pieces into a documented library (tokens, the reduced-motion gate, hooks, components).

## Non-negotiables (every effect)
- **Reduced motion:** one gate; every effect collapses to a calm resting frame. Gate the effect, not the markup (no hydration mismatch).
- **Performance:** rAF not per-event; cap DPR; pause offscreen (IntersectionObserver) and on tab-hidden; one shared listener/loop; animate transform/opacity/clip-path only. WebGL: low-power, single pass.
- **Accessibility:** restyle focus rings, never remove; decorative layers aria-hidden; decorative text keeps its accessible name; no content gated behind motion.
- **No slop:** restraint over noise; if an effect doesn't earn its frame budget, cut it.

## Technique menu
- **Tier 1 — foundation (do first):** a motion token scale (durations fast/base/slow/boot + an easing set + a stagger token); physics smooth scroll (Lenis, off under reduced motion) which unlocks scroll velocity as an input; a reveal vocabulary (rise / clip-path scan / mask-up / fade) with a staggered group instead of one fade everywhere.
- **Tier 2 — interaction:** magnetic elements (spring pull + inertia); a real custom cursor (multi-layer lag, velocity squash-stretch, docking onto targets, click pulse); entry-aware button fill sweeps; shimmer skeletons.
- **Tier 3 — signatures:** scroll-velocity-coupled variable-font type; WebGL hero fields (ordered dither/halftone, cursor flowmap wake, scroll drift, click ripple); displacement / RGB-shift / feedback shaders; page transitions (View Transitions API first); scrubbed scrollytelling (GSAP ScrollTrigger or native scroll-driven CSS); tasteful decode/mask text; grain/dither textures; hero parallax.

Prefer modern CSS-native versions (View Transitions, `animation-timeline: scroll()/view()`) where support allows; fall back to JS otherwise.

## Where to research (pull live, current year)
Arbiters: Awwwards (Site of the Year + animation/transitions/gsap/webgl collections), FWA, CSS Design Awards, Godly. Studios to mine: Active Theory, Lusion, Resn, basement.studio, Bruno Simon, Olivier Larose. Techniques are taught at Codrops (tympanus.net), web.dev (View Transitions, scroll-driven animations), and the Lenis / GSAP / Three.js / React Three Fiber docs.

## Runtime gotchas the compiler won't catch
- IntersectionObserver inside `preserve-3d` / a rotated plane is unreliable — orchestrate reveals from a non-transformed parent (one observer + staggered variants), not per-child observers.
- `transform`/`filter`/`perspective` on an ancestor breaks `position: fixed` descendants — page transitions use opacity on the content wrapper + a separate fixed overlay.
- `fontVariationSettings` strings don't interpolate — animate a numeric CSS var or write the axis in rAF.
- A first-load full-page opacity fade hurts LCP — skip it on first paint; run transitions only on client navigation.
- Lenis vs CSS `scroll-behavior: smooth` conflict — let Lenis own it; reduced-motion forces auto.
- `useReducedMotion()` is null until measured — collapse to a stable boolean.

## Scope to the ask
"Make it nicer" → a few high-leverage moves (tokens, smooth scroll, a real reveal). "Award tier" → the full loop with signature WebGL/scroll/cursor work and a verification pass. Always keep the gates.
