---
name: preview
description: Look at a running screen without deploying anything. Starts the project's own dev server on a free port, waits until it really answers, drives it in a local Chromium through the Playwright MCP, and captures desktop/tablet/phone screenshots plus the browser's console errors. Use whenever you need to SEE a page, screen, component, route, or UI change - "show me", "what does it look like", "screenshot the page", "check the layout", "is it broken", "preview this route" - and ALWAYS instead of deploying to Vercel or anywhere else just to look at something.
---

# preview

Deploying is not a way to look at a screen. This is.

## When to use it

Any time the answer to "does it look right?" needs eyes. Never push to a host,
never ask Kariim to open a browser, never describe what the page probably looks
like. Run this and show the pictures.

## Requirements

- `playwright` and `chrome-devtools` MCP servers registered at user scope
  (they are, pointing at globally installed local copies).
- A `package.json` with a `dev` or `start` script.

## Procedure

### 1. Start the server

```
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "%USERPROFILE%\.claude\skills\preview\tool\start-dev.ps1" -ProjectRoot "<absolute project root>"
```

It picks the first free port in 5173-5250, launches the project's own package
manager (npm/pnpm/yarn/bun, chosen by which lockfile is present) with **no
visible console window**, and polls the port until it answers.

- Success prints `PREVIEW_URL=`, `PREVIEW_PID=`, `PREVIEW_LOG=`,
  `PREVIEW_ERRLOG=`, `PREVIEW_DIR=`.
- Failure prints `PREVIEW_FAILED`, then the dev server's **own stderr and
  stdout**, then stops. When that happens: print that stderr to Kariim verbatim
  and **stop**. Do not guess at the cause, do not retry blind, do not move on to
  screenshots.

Timeout is 45 seconds. Override with `-TimeoutSeconds N` only when a project is
known to be slow to boot.

### 2. Navigate

Use the Playwright MCP:

- `browser_navigate` to `<PREVIEW_URL><route>` (route defaults to `/`).
- Wait for the page to settle before capturing.

### 3. Capture three widths

For each width, resize then screenshot into the project's `.preview` folder:

| Label   | Width | Height | File |
|---------|-------|--------|------|
| desktop | 1280  | 800    | `.preview/desktop-1280.png` |
| tablet  | 768   | 1024   | `.preview/tablet-768.png`   |
| phone   | 390   | 844    | `.preview/phone-390.png`    |

- `browser_resize` to the width/height, then `browser_take_screenshot` with
  `filename` set to the absolute path above and `fullPage: true`.

### 4. Report console errors

Ask the `chrome-devtools` MCP for the page's console output
(`list_console_messages`, or `navigate_page` first if it holds its own tab) and
print **only** entries at error/warning level. If there are none, say
"no console errors" - do not stay silent, an unstated result reads as unchecked.

### 5. Print the result

Exactly this shape, nothing more:

```
URL:      http://localhost:<port><route>
desktop:  <abs>\.preview\desktop-1280.png
tablet:   <abs>\.preview\tablet-768.png
phone:    <abs>\.preview\phone-390.png
console:  <n> errors  (or: no console errors)
```

### 6. Leave the server up

Do **not** kill `PREVIEW_PID`. It stays running for the rest of the session so
the next look is instant. Note the PID in your reply so it can be stopped
deliberately later.

## Rules

- A screenshot Kariim cannot click is not a preview. If the reply is visual,
  the three files go out as a clickable artifact or preview pane, not as prose.
- Never substitute a deploy, a curated render, or a description for a real
  screenshot of the real running page.
- `.preview/` and `.playwright-mcp/` are in the global gitignore - never commit
  captures.
