# Verification

Four standing rules. They bind on every surface, every session, turn 1 and turn
100 alike.

## Deploying is not a way to look at a screen

To see a page, a screen, a component, a route, or any visual change, use the
`preview` skill. It starts the project's own dev server on a free port, drives a
local Chromium, and captures desktop (1280), tablet (768) and phone (390)
screenshots plus the browser's console errors — all locally, with nothing
published. Pushing to Vercel or any host in order to *look* at something is a
violation, not a shortcut.

## Deploy only when Kariim says deploy

The word has to come from him, for this thing, now. A deploy is an
outside-world, hard-to-reverse action: earlier approval of a different deploy
never carries over, and "it's ready" is not permission. Build it, show it with
`preview`, and wait.

## Never report work as done without pasted output from the verify script

"Done", "fixed", "working", "passing" — each requires the actual output of
`verify` (`~/.claude/hooks/verify-gate.sh --run`), pasted, showing the checks
that ran. The Stop gate enforces this automatically, but the duty is yours
before the gate ever fires. If a check could not run, say exactly that and say
why — an unverifiable claim is written as "unverified", never asserted.

## Every paste-able instruction is complete or it is not an instruction

Anything Kariim is meant to paste, run, or click states, every time:

- **Surface** — which machine or app this happens on.
- **Repo** — which repository.
- **Branch** — which branch he must be on.
- **Folder** — the exact absolute folder to be in.
- **Where to paste** — the exact place: which terminal, which field, which pane.
- **Every on-screen choice by name** — the literal button, menu item, checkbox,
  or dropdown value he will see, spelled as it appears.
- **What done looks like** — the observable result that means it worked.

If a field genuinely does not apply, write that it does not apply. **Omitting it
is the failure** — a missing field reads as an oversight and sends him back to
ask. Silence is never the same as "not applicable".
