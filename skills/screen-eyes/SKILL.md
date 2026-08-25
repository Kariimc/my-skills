---
name: screen-eyes
description: Lets Claude Code or Codex see the user's screen, camera, snips, and video files without any pasting. Two paths - local snips saved to disk (Windows hotkeys) and a live cross-platform vision bridge (Gemini). Use whenever the user says "look", "look at my screen", "look at this", "see what I snipped", "check my screen", "what's on my screen (right now / live)", "the thing I just copied", "read my screen", "watch/see/look at a video", "analyze the clip/recording", or asks Claude to "say / speak / read aloud" something back to them.
---

> **Local note (this machine, not upstream). Read this instead of Paths A, B and C
> below, which describe hotkeys and a Gemini bridge that are not installed here.**
>
> Sight is live and it works five ways. Prefer whichever fits.
>
> **1. Kariim showed you something.** He presses Win+Shift+S and drags a box. A
> background watcher writes it to `C:\Users\Kariim\Dev\claude-eyes\captures\latest.png`.
> On "look", "look at my screen", "look at this", "see this": just Read that file.
>
> **2. You are DOING something visual - watch yourself do it (his order,
> 2026-08-24).** Before acting on anything on the real desktop (Godot, Blender,
> an app, a window), open the stream eye:
>
> ```
> python C:/Users/Kariim/Dev/claude-eyes/live.py start
> ```
>
> While you work, glance at any moment by Reading
> `C:/Users/Kariim/Dev/claude-eyes/captures/live-latest.png` - it is always
> the current instant. When the step is done, `python .../live.py stop` prints a
> timestamped contact sheet of everything that changed during the run; Read it
> and judge the sequence, not just the end state. `--window "Godot"` follows one
> window, `--every 3` slows the tick, and it stops itself after 30 minutes so a
> forgotten run can never eat the disk. Idle moments are not stored - history
> keeps only frames where the picture actually changed.
>
> **3. You need one still, full detail, or should NOT ask him for a snip.** Take
> the picture yourself. This is the default when checking your own work, judging
> a visual, confirming an app state, or debugging something on screen:
>
> ```
> powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File C:/Users/Kariim/Dev/claude-eyes/shot.ps1 -Mode full
> ```
>
> `-Mode full` every monitor · `-Mode monitor -Monitor 2` one screen ·
> `-Mode window -Window "Godot"` one window by part of its title ·
> `-Mode region -Region "300,200,900,600"` an exact box. It prints the path it
> wrote on the last line, and always updates `captures\latest.png`. Never ask
> Kariim to send a screenshot of something you could photograph yourself.
>
> **4. You need true motion.** `record.ps1 -Seconds 10` records an mp4 (hidden,
> ffmpeg), then `python C:/Users/Kariim/Dev/claude-eyes/frames.py <clip> --changes`
> cuts it into stills at the moments something happened. Works on any video file
> Kariim hands over too.
>
> **5. You need to judge it properly, not just glance.** A large image is scaled
> down before you see it, and that is where texture, hairlines and small type
> die. No eye can name an exact colour either. So before ruling on any visual,
> run the measuring tools:
>
> ```
> python C:/Users/Kariim/Dev/claude-eyes/look.py report <image>
> ```
>
> `tiles` cuts it into overlapping pieces read at 1:1 so nothing is ever
> shrunk; read every tile. `colour` gives the real palette, the foreground
> found by brightness rather than area, and WCAG contrast. `colour --at X Y`
> gives one pixel exactly. `light` gives dynamic range in stops, where the
> light sits, warm or cool cast, blown highlights, crushed blacks. `texture`
> maps where the fine detail is and names the busiest region to crop.
>
> **The harsh-critic law applies to what you SAW, not what you assumed.** A
> verdict on a visual that was never tiled or measured is not a verdict.
>
> **Two boundaries.** Work inside the in-app browser pane is seen with the
> pane's own screenshot tool; the desktop eye cannot see into it. And in a
> sandbox, a VM, or any box with no desktop (his order, 2026-08-24): there is
> still no working blind - every image or asset produced there is Read back
> with your own vision before it is called done, code is proven by running it
> and reading the true output, a render is rendered and looked at. **Not
> available here:** the Gemini bridge and text-to-speech. Say so plainly rather
> than improvising.

# Screen Eyes

Claude gets sight two ways. Prefer whichever is running; when both are, the live
bridge is best for "right now / live" and the disk snips are best for a frame the
user deliberately captured with a hotkey.

## Path A - local snips on disk (Windows hotkeys)

A background watcher saves every screenshot/snip the user takes into
`C:\Users\Kariim\Dev\claude-eyes\captures\`.

The user's own keys. After a capture, a small Anthropic-styled overlay asks whether to
send it to **Claude** (desktop app), **Claude Code** (local terminal), or **Cloud chat**
(a cloud Claude session, via the bridge tunnel - see Path C). The two local targets
auto-type into that window even if another app is focused:
- **Alt+C** = snip a still -> drag a box -> saves to `captures\latest.png`, sends "look".
- **Alt+X** = record the whole screen -> a live overlay HUD records until the clip hits
  Claude's size limit (or a second Alt+X stops it) -> extracts frames to `frames\_rec\`
  and, for Claude Code, uploads the clip to the bridge for Gemini. Sends "look at the
  video" (chat) or "watch the recording" (Claude Code).
Copying an image/video file in Explorer works too; copied videos auto-extract and
auto-type "look at the video".

### "look" / "look at my screen" / "see this"
1. Read the image at `C:\Users\Kariim\Dev\claude-eyes\captures\latest.png`.
2. "the last few" -> read the newest timestamped PNGs in that folder (names sort by time).
3. Self-heal: if `latest.png` is missing or clearly stale for a fresh snip, run
   `C:\Users\Kariim\Dev\claude-eyes\start-eyes.bat` yourself, wait 3 seconds, then
   remind the user the snip key is Alt+C. Never tell the user to start anything manually.

### "watch the recording" (Alt+X, Claude Code)
An Alt+X recording uploads the real clip to the bridge. On "watch the recording" / "watch
what just happened", call `GET http://localhost:3000/api/eyes/video/describe?q=<question>`
and read `.description` (Gemini's smooth-motion read). Frames are also on disk under
`C:\Users\Kariim\Dev\claude-eyes\frames\_rec\sheet.png` as a fallback if the bridge is down.

### Watch a video (disk)
1. Given a path, run: `python C:\Users\Kariim\Dev\claude-eyes\eyes_video.py "<path>" --frames 12`
   (use `--frames 24` for long or dense videos).
2. It prints a frames folder and a `sheet.png`. Read `sheet.png` (a grid of timestamped
   stills); open individual frame PNGs in that folder when detail matters.
3. "the video I just copied" / an Alt+C screen clip -> the frames are already extracted;
   use the newest folder under `C:\Users\Kariim\Dev\claude-eyes\frames\` (Alt+C clips land
   in `frames\_clip\`). Read its `sheet.png`.
4. Frames are stills only - no audio.

## Path B - live vision bridge (cross-platform, Gemini)

`claude-eyes\bridge\` runs a local server on `http://localhost:3000` that holds the
user's live screen/camera feed in memory (streamed from the browser dashboard or a
`bridge\integration\` streamer script). It analyzes frames and clips with Gemini and
can speak back with TTS. This works on macOS/Linux too, where the Windows hotkeys don't.

Use the bridge when the user asks about their screen "right now / live", is not on
Windows, or when `captures\latest.png` isn't available. No API key is needed (the build
uses AI Studio's managed server-side Gemini); it just needs a stream active - the
dashboard open and sharing, or a streamer running.

### "what's on my screen right now" / live look
- Fetch a Gemini description of the live frame (includes Google Search grounding when relevant):
  `curl -s "http://localhost:3000/api/eyes/describe?q=<url-encoded question>"` -> read `.description`.
- Or pull the raw live frame and read it yourself: `http://localhost:3000/api/eyes/latest.png`.
- If it returns 503 "no active stream", nothing is feeding the screen - tell the user to
  double-click their Claude Eyes desktop icon (runs `open-eyes.bat`), which starts a
  background streamer of their ACTUAL live screen automatically (no browser, no Share
  Screen click). The browser dashboard (localhost:3000, Share Screen) is an alternative,
  and `bridge\integration\` has manual streamers too. No API key needed.

### "analyze the clip / recording I just made"
- After the user records a clip in the dashboard, get a chronological analysis:
  `curl -s "http://localhost:3000/api/eyes/video/describe?q=<url-encoded question>"` -> read `.description`.
  This is true temporal video analysis (motion, transitions, sequence), not stills.

### "say / speak / read aloud" - talk back to the user
- Make the dashboard speak (Gemini TTS): POST to `http://localhost:3000/api/eyes/action`
  with JSON `{"message":"<text>","type":"tts"}`. The open dashboard plays it aloud.

### MCP (autonomous, no curl)
When the bridge is registered as an MCP server (`node bridge/dist/server.cjs --mcp`, or
`tsx bridge/server.ts --mcp` in dev; see `bridge/README.md`), these tools are available
directly and are the preferred way to use Path B:
- `get_screen_description` - describe/transcribe the live screen or camera.
- `get_video_analysis` - chronological analysis of the last recorded clip.
- `trigger_audio_alert` - speak a message aloud on the dashboard.

## Path C - cloud delivery (when THIS chat is a cloud Claude Code session)

The Windows capture layer delivers to a Claude window on the user's PC. When the user is
chatting with Claude Code in the CLOUD, that local delivery can't reach this chat - it's
an architecture gap, not a bug. The bridge + a tunnel close it: picking **Cloud chat** in
the send-to overlay uploads the capture to the bridge (`/api/eyes/upload`), and a
Cloudflare quick tunnel (`eyes_tunnel.py`, no account/key) exposes the bridge on a public
`https://<name>.trycloudflare.com` URL.

Getting the URL (the "cloud link"): the user pastes it to you once per session - it's on
their clipboard after launch and `open-eyes.bat` prints it (also in
`captures\tunnel.txt`). Remember it for the rest of the session; you don't need it re-sent
per capture.

### "look" / "watch the recording" from a cloud session
1. Use the tunnel base URL the user gave you (call it BRIDGE).
2. Pull the frame and read it yourself - keyless, you have vision:
   `curl -s "<BRIDGE>/api/eyes/latest.png" -o /tmp/eye.png`, then read `/tmp/eye.png`.
   An Alt+X recording arrives the same way: its frame contact-sheet is uploaded as
   `latest.png`, and the raw clip is uploaded too (for the Gemini path below).
3. Optional richer read (needs the bridge's Gemini, i.e. a key/managed context):
   `curl -s "<BRIDGE>/api/eyes/describe?q=<url-encoded question>"` -> read `.description`;
   `.../video/describe?q=...` for temporal motion on a recording.
4. If the fetch fails at the proxy (403 / connection refused / TLS block), THIS cloud
   environment's outbound network policy can't reach the tunnel. Say so plainly - do NOT
   claim you saw anything. The fix is on the user's side: run the session in a
   Claude-Code-on-web environment whose network policy allows arbitrary outbound, or use a
   local Claude Code (which reaches the tunnel directly). Local snips (Path A) still work.

## Rule
Never ask the user to paste, upload, or describe a screenshot. Read the disk files or
query the bridge above instead. (The one exception: the cloud link URL in Path C, which
the user pastes once per session so a cloud session knows where the tunnel is.)
