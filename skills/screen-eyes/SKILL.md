---
name: screen-eyes
description: Lets Claude see the user's screen snips and video files without any pasting. Use whenever the user says "look", "look at my screen", "look at this", "see what I snipped", "check my screen", "the thing I just copied", or asks to watch/see/look at a video file or "the video I copied".
---

# Screen Eyes

A background watcher saves every screenshot/snip the user takes into C:\Users\Kariim\Dev\claude-eyes\captures\.

The user's own keys (each: press, a dim overlay appears, drag a box, release; the helper then auto-types into Claude Code even if it isn't focused):
- **Alt+X** = still snip -> saves to captures\latest.png, auto-types "look".
- **Alt+C** = video of the boxed screen region (up to 10s; the user can click the REC badge to stop early) -> extracts frames under frames\_clip\, auto-types "look at the video".
Copying an image/video file in Explorer still works too.

## "look" / "look at my screen" / "see this"
1. Read the image at C:\Users\Kariim\Dev\claude-eyes\captures\latest.png.
2. "the last few" -> read the newest timestamped PNGs in that folder (names sort by time).
3. Self-heal: if latest.png is missing or clearly stale for a fresh snip, run C:\Users\Kariim\Dev\claude-eyes\start-eyes.bat yourself, wait 3 seconds, then remind the user the snip key is Alt+X. Never tell the user to start anything manually.

## Watch a video
1. Given a path, run:  python C:\Users\Kariim\Dev\claude-eyes\eyes_video.py "<path>" --frames 12   (use --frames 24 for long or dense videos).
2. It prints a frames folder and a sheet.png. Read sheet.png (a grid of timestamped stills); open individual frame PNGs in that folder when detail matters.
3. "the video I just copied" / an Alt+C screen clip -> the frames are already extracted; use the newest folder under C:\Users\Kariim\Dev\claude-eyes\frames\ (Alt+C clips land in frames\_clip\). Read its sheet.png.
4. Frames are stills only - no audio.

## Rule
Never ask the user to paste, upload, or describe a screenshot. Read the files above instead.
