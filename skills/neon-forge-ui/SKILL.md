---
name: neon-forge-ui
description: Expert agent for the Neon Forge UI library — a bespoke dark-mode React component workbench (React 19 + TanStack Start, Tailwind v4, motion/react, deployed as a Cloudflare Worker on Higgsfield). Produces new interactive components, live demos, and copyable snippets that match the library's exact conventions. Use when the user wants to add or edit a Neon Forge component, run or preview the library locally, add a category, or deploy/push it.
---

# Neon Forge UI Library Agent

You manage, expand, and maintain Neon Forge UI — a single owner's bespoke dark-mode component library. It is a live deployed workbench where every component has an interactive demo and a copyable snippet. Aesthetic: bleeding-edge dark tech, motion-forward, expert-level. NO generic components.

- **Local clone:** `C:\Dev\neon-forge-ui` (the app lives under `app/`). Private Higgsfield git repo; pushing needs the `http.extraHeader` auth token from the handoff doc.
- **Stack:** React 19 + TanStack Start (SSR → single-file Cloudflare Worker), Tailwind v4 (`@theme` in `styles.css`, no `tailwind.config.js`), `motion/react` (Framer Motion v12) for ALL physics, `lucide-react` for icons (sparingly). Package manager: `bun`.
- **Never install:** `framer-motion` (use `motion/react`), `gsap`, `three.js`.

> ⚠️ The original `NEON_FORGE_HANDOFF.md` is STALE on file names and component count. This skill reflects the real codebase. Trust this skill over the handoff.

---

## Ground truth: where components live

The grid is driven by **`app/src/lib/components-registry-v2.ts`** (NOT `components-registry.ts`):

```ts
import { COMPONENTS as BASE_COMPONENTS, type ComponentDef } from "./components-registry";
const NEW_COMPONENTS: ComponentDef[] = [ /* newer components */ ];
export const ALL_COMPONENTS: ComponentDef[] = [...BASE_COMPONENTS, ...NEW_COMPONENTS];
```

- **Demos:** newer ones live in `app/src/components/demos2.tsx`, older ones in `demos.tsx`. Both start with `"use client"`.
- **Registration:** `app/src/components/component-card.tsx` — the `LiveDemo` `demos` record maps slug → demo JSX, with imports from `./demos2`.
- The library already has ~70 components. **Always grep existing slugs before adding** — most of the handoff backlog (#25–#100) is already built:

```bash
grep -hoE 'slug: "[^"]+"' app/src/lib/components-registry.ts app/src/lib/components-registry-v2.ts | sort
```

---

## How to add a component (4 edits + verify)

### 1. Write the demo in `demos2.tsx`
Signature MUST be `export function XxxDemo({ accent }: { accent: string })`. Use the accent prop; use `motion/react` for physics. demos2.tsx already imports `useState, useRef, useCallback, useEffect, useId` (react) and `motion, AnimatePresence, useMotionValue, useSpring, useTransform, useAnimationFrame, useInView` (motion/react) — reuse those, don't re-import.

```tsx
// Cursor-tracking: motion values, NEVER useState for continuous values.
export function MagnetTileDemo({ accent }: { accent: string }) {
  const ref = useRef<HTMLButtonElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const sx = useSpring(x, { stiffness: 150, damping: 15 });
  const sy = useSpring(y, { stiffness: 150, damping: 15 });
  const move = (e: React.MouseEvent) => {
    const r = ref.current!.getBoundingClientRect();
    x.set((e.clientX - r.left - r.width / 2) * 0.4);
    y.set((e.clientY - r.top - r.height / 2) * 0.4);
  };
  return (
    <motion.button
      ref={ref}
      onMouseMove={move}
      onMouseLeave={() => { x.set(0); y.set(0); }}
      // MotionValues AND css in ONE style object — never two style props.
      style={{ x: sx, y: sy, background: `${accent}18`, border: `1px solid ${accent}60` }}
      className="px-6 py-3 rounded-full font-medium text-white"
    >
      Pull me
    </motion.button>
  );
}
```

### 2. Add a registry entry to `NEW_COMPONENTS` in `components-registry-v2.ts`
The `snippet` is what users copy — it must be standalone, real, working TSX (include its own minimal imports), not pseudocode.

```ts
{
  slug: "magnet-tile",                 // kebab-case, unique
  name: "Magnet Tile",
  category: "buttons",                 // buttons|cards|effects|navigation|typography|forms
  description: "Pulls toward the cursor with spring physics.",
  keywords: ["magnet", "hover", "spring", "motion"],
  snippet: `"use client";
import { useRef } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";

export function MagnetTile({ accent }: { accent: string }) {
  /* ...real working code... */
}`,
},
```

### 3. Register the demo in `component-card.tsx`
Add the import to the `from "./demos2"` block, then one line to the `LiveDemo` `demos` record:

```tsx
import { /* ...existing... */ MagnetTileDemo } from "./demos2";
// inside LiveDemo's `demos` record:
"magnet-tile": <MagnetTileDemo accent={accent} />,
```

### 4. Verify
```bash
cd app && bun run typecheck && bun run build
```

---

## Local preview (the gotcha)

`bun run dev` (`vite dev`) returns **HTTP 500** — `ssr.noExternal: true` in `vite.config.ts` (required for the Worker build) breaks Vite's dev SSR runner. Do NOT try to "fix" it by editing noExternal; that trades one crash for another. The correct local preview serves the real production Worker:

```bash
cd app
bun run build
bun x wrangler dev --port 8787 --local   # → http://localhost:8787 (press b to open)
```

---

## The 8 design rules (NEVER break)

1. **Dark only.** Page `#050608`, surface `#0B0D12`. No light mode.
2. **Single accent via prop.** Always use the `accent` prop; never hardcode `#4D7CFF` or `#39D353` in demos.
3. **No AI purple/rainbow gradients.** One accent max.
4. **`motion/react` only for physics.** Continuous values → `useMotionValue` + `useSpring`, never `useState`.
5. **No duplicate `style` props.** Merge MotionValues + CSS into ONE `style` object. Don't cast a style object containing MotionValues `as React.CSSProperties`.
6. **No generic components.** Every component is visually distinctive.
7. **Snippets are real, runnable code** — minimal imports, no pseudocode.
8. **`font-mono`** for code, labels, keyboard keys, and uppercase tracking tags.

**SSR-safe:** never touch `window`/`document`/`localStorage`/`navigator` at module top level or during render — only inside effects/handlers or guarded with `typeof window !== "undefined"`. Clean up intervals/timeouts/rAF/listeners.

---

## Adding a category

Beyond buttons/cards/effects/navigation/typography/forms:
1. `components-registry.ts`: add to the `ComponentCategory` union and the `CATEGORIES` array.
2. `component-card.tsx`: add a color to the `CATEGORY_COLORS` record.
The sidebar and grid auto-update.

## Do NOT change

`app/packages/` (vendored), `app/src/module/` (design inspector), `app/src/server.ts` (Worker entry), `app/wrangler.jsonc` (platform-owned), `app/app.manifest.json` (only for D1/R2/KV opt-in).

## Deploy

Pushing is outward-facing — a `git push` to `main` triggers a live Higgsfield deploy. **Confirm with the owner before pushing.** After push: tell the owner "Push done — deploy when ready." Preview URL: `https://preview--hidden-glow-736.higgsfield.app`.

See also: `premium-web-craft`, `motion-ui`, `accessibility`.

---

## LOOP PROTOCOLS

### Context-First Loop
→ ASSESS before writing a component: which category, is the slug already taken (grep first), what interaction does it demonstrate. If unclear: ask ONE targeted question → gather → reassess.
→ PROCEED only when you know the slug is unique and the interaction is concrete.

### Verify-Refine-Deliver (VRD) Loop
→ GENERATE demo + snippet → SELF-CHECK against the 8 design rules + the Quality Gate → run `bun run typecheck && bun run build` → IDENTIFY failures → REFINE → RE-VERIFY.
→ Max 3 iterations; surface specific blockers if unresolved.
→ DELIVER only when typecheck + build pass and the component renders at `http://localhost:8787`.

### Regression Guard
→ After edits, confirm the existing component count is unchanged + N and no existing slug/demo broke (the grid still renders all prior components).
→ Document: files changed (the 3 component files), why, rollback path = `git checkout -- <file>` (uncommitted) or revert the commit. NEVER push without owner confirmation.

---

## Quality Gate

Before delivering a component, verify ALL:
- [ ] `bun run typecheck` passes (no TS errors)
- [ ] `bun run build` passes (client + SSR bundles emit)
- [ ] Renders correctly at `http://localhost:8787` via `wrangler dev` (HTTP 200, demo visible)
- [ ] Slug is unique (grepped both registry files) and entry added to `NEW_COMPONENTS`
- [ ] Demo accepts `accent: string` and uses it — no hardcoded `#4D7CFF`/`#39D353`
- [ ] No `useState` for continuous motion values; no duplicate `style` props
- [ ] Demo + snippet imported/registered in `component-card.tsx` `LiveDemo`
- [ ] `snippet` is standalone, real, copyable code with minimal imports
- [ ] SSR-safe (no unguarded `window`/`document`; effects clean up)
- [ ] All imports use `motion/react`, not `framer-motion`

---

## CHANGELOG

### v1.0.0 — 2026-06-29
- Created from the NEON_FORGE_HANDOFF, corrected against the live codebase:
  real registry is `components-registry-v2.ts` (`ALL_COMPONENTS`), demos in `demos2.tsx`, ~70 components built.
- Documented the `vite dev` 500 gotcha and the `wrangler dev` local-preview path.
- Encoded the 4-file add flow, 8 design rules, SSR-safety, and a domain quality gate.
