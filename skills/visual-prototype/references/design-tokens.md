# Design Tokens & Anti-Default Playbook

Read this when building or refining the *look* of a prototype. The goal: high-fidelity
output that feels intentionally designed, never like a Tailwind starter template. For
deeper aesthetic direction also consult the `frontend-design` skill.

## The "templated default" smell — avoid these
- Tailwind `blue-500` / `indigo-600` as the accent on everything.
- Pure `#000` text on pure `#fff`, all `gray-*` neutrals.
- Uniform `rounded-lg` + `shadow-md` on every card with no hierarchy.
- One font weight, one size jump, centered everything.
- Default system focus rings and no hover/active states.

## 1. Color — pick a point of view, then commit
Define a real token set on `:root` and reference it everywhere (so the overlay's brand
picker works by overriding one variable):

```css
:root{
  --brand:#6366f1;                 /* the ONE accent; overlay overrides this live */
  --brand-fg:#ffffff;
  --bg:#fafaf9; --surface:#ffffff; --surface-2:#f4f4f5;
  --text:#1c1c22; --text-muted:#6b7280; --border:#e7e5e4;
  --success:#16a34a; --warn:#d97706; --danger:#dc2626;
  --radius:14px; --shadow:0 1px 2px rgba(0,0,0,.04),0 8px 24px rgba(0,0,0,.06);
}
html.dark{
  --bg:#0b0d12; --surface:#13161d; --surface-2:#1a1e27;
  --text:#e7e9ee; --text-muted:#9aa0ad; --border:#262a34; --shadow:0 8px 28px rgba(0,0,0,.5);
}
```
Use one warm or one cool neutral family consistently — don't mix. Give the accent a real
identity (a violet, a teal, a clay) rather than stock blue.

## 2. Type — one scale, real hierarchy
Use a modular scale (~1.25 ratio) and at least two weights. Tighten heading letter-spacing.
```
display 30/36 700 · h1 24/30 700 · h2 19/26 600 · body 15/22 400 · small 13/18 500 · label 11/16 600 uppercase
```
Prefer a distinctive but safe stack: `"Inter"`, `"Geist"`, or a serif display for headings
paired with a clean sans body. Body line-height ≥1.5; headings ≤1.25.

## 3. Spacing & layout
- Stick to a 4px rhythm (4/8/12/16/24/32/48). No arbitrary `13px`.
- Generous outer padding; let content breathe. Max content width ~720–1100px for reading.
- Establish hierarchy with *space and weight*, not borders everywhere.

## 4. Elevation, radius, motion
- Two shadow levels max (resting + raised). Consistent `--radius` across siblings.
- Motion: 150–250ms, ease-out for enters. **Multiply every duration by `var(--motion-scale)`**
  so the overlay's motion control works:
  `transition: transform calc(180ms * var(--motion-scale)) ease;`
- Add hover AND active states to anything clickable. Custom focus-visible ring in `--brand`.

## 5. Polish checklist (run before declaring "hi-fi")
- [ ] Accent is a chosen color, applied via `--brand`, not hardcoded per element.
- [ ] Dark mode actually re-themes (overlay toggle flips `html.dark`).
- [ ] Empty / loading / error states are real, not placeholder text.
- [ ] Interactive elements have hover + active + focus-visible.
- [ ] Type scale is consistent; no orphan font sizes.
- [ ] Spacing follows the 4px rhythm.
- [ ] Durations respect `var(--motion-scale)`.
