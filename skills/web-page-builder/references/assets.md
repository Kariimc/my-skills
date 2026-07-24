# Assets — real imagery, video, and 3D via Higgsfield

A committed direction usually needs real assets: a hero image or video, a texture, a
3D object, a background loop. Never ship lorem imagery or a gray box where the brief
calls for a real asset. Generate them with the Higgsfield MCP tools (the user's account
is active).

## Which tool

- **`generate_image`** — hero art, backgrounds, textures, product shots, section
  imagery. Describe the subject in the site's committed visual language (palette, mood,
  era, material), not generic terms.
- **`generate_video`** — hero loops, ambient motion, background reels. Keep it short and
  loopable; respect the reduced-motion floor (offer a static poster frame).
- **`generate_3d`** — turn an image into a GLB mesh for a WebGL/Three.js hero.
- **Edit existing assets** instead of regenerating: `upscale_image` / `upscale_video`
  (to 2K/4K), `outpaint_image` (extend/uncrop for a full-bleed hero), `reframe` (change
  a video's aspect ratio), `remove_background` (cutouts), `motion_control`.
- **Unsure which model?** Call `models_explore(action:'recommend')` with the goal and
  input before generating.

## Workflow

1. Decide from the direction exactly which assets the page needs and at what aspect
   ratios / sizes. List them before generating so you don't over-produce.
2. Generate, then **look at the result** (read the image back) before placing it. If it
   doesn't match the committed language, regenerate with a sharper prompt — don't settle
   for an off-brand asset because it's "close."
3. Optimize for the web: correct dimensions, compressed, `loading="lazy"` below the
   fold, a real `alt`, and a poster frame for any video hero.
4. Keep generated assets with the project and reference them by real path — never leave
   a placeholder `src`.

## Higgsfield's own site tooling (optional)

Higgsfield also exposes `create_website` / `deploy_website` and related tools. When the
user wants Higgsfield to host the whole thing, call `get_website_creation_instructions`
first and follow that flow. For a hand-built site, prefer the deploy paths in
`deploy.md` and use Higgsfield only for the assets.
