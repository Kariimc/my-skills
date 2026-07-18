---
name: screen-eyes
description: Lets Claude Code or Codex see the user's screen, camera, snips, and video files without any pasting. Two paths - local snips saved to disk (Windows hotkeys) and a live cross-platform vision bridge (Gemini). Use whenever the user says "look", "look at my screen", "look at this", "see what I snipped", "check my screen", "what's on my screen (right now / live)", "the thing I just copied", "read my screen", "watch/see/look at a video", "analyze the clip/recording", or asks Claude to "say / speak / read aloud" something back to them.
---

# Screen Eyes

Claude gets sight two ways. Prefer whichever is running; when both are, the live
bridge is best for "right now / live" and the disk snips are best for a frame the
user deliberately captured with a hotkey.

## Path A - local snips on disk (Windows hotkeys)

A background watcher saves every screenshot/snip the user takes into
`C:\Users\Kariim\Dev\claude-eyes\captures\`.

The user's own keys. After a capture, a small Anthropic-styled overlay asks whether
to send it to **Claude** (desktop app) or **Claude Code**, then it auto-types into
that window even if another app is focused:
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

## Rule
Never ask the user to paste, upload, or describe a screenshot. Read the disk files or
query the bridge above instead.
