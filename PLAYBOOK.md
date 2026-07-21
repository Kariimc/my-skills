# PLAYBOOK — PROVEN ROADS. READ BEFORE WORKING. USE THESE INSTEAD OF INVENTING.
Format: WHEN (precondition) → DO (exact method) → PROOF (the evidence it worked).
Sibling of FAILURES.md. That ledger bans dead roads; this one hands over live ones.

ENTRY BAR — an entry is only legal if it has all three:
1. A PRECONDITION. Never "always do X." A method without its trigger becomes cargo cult.
2. An EXACT method — real command, real flags, real path. No paraphrase.
3. A MEASURED PROOF — output, number, or verified state. No "seemed to work."
An entry that fails its own precondition test gets a FAILURES.md entry and is struck here.

## P-01 GitHub API rate-limited (60/hr anon)
WHEN: Reading a PUBLIC repo's contents and the REST API returns 403 / rate-limit.
DO: `curl -sL "https://codeload.github.com/<user>/<repo>/tar.gz/HEAD" | tar xz`
PROOF: Full my-skills tree (416 skills, 68 agents) pulled with quota already exhausted, 2026-07-06.

## P-02 GitHub HTML/avatars when the API is out
WHEN: Need org page data or an avatar and the API is rate-limited.
DO: `curl -sL <url> -H "User-Agent: Mozilla/5.0"`, or build the avatar URL directly:
`https://avatars.githubusercontent.com/u/<org_id>?s=280&v=4`
PROOF: shift9-studio org assets pulled during the shift9.dev build, 2026-07-14.

## P-03 Any local command that could exceed ~25s
WHEN: Builds, installs, gate suites, my-skills commits (.githooks run 90s+), long clones.
DO: Detach — `Start-Process -FilePath <exe> -ArgumentList <args> -RedirectStandardOutput <file> -NoNewWindow`
then poll with a SHORT read of the output file in a later call, same turn.
PROOF: The inverse is F-02 — inline long calls silently wedge that server's channel until app restart.

## P-04 Writing any config/JSON on Windows
WHEN: Writing claude_desktop_config.json or any file a parser reads.
DO: `[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))`
PROOF: Set-Content/Out-File on PS5 emits a UTF-8 BOM → `Unexpected token '﻿'`. No-BOM write parses clean.

## P-05 One local MCP tool call times out
WHEN: A Desktop Commander or Windows-MCP call hangs past its timeout once.
DO: The BRIDGE is down — all local servers with it. Do NOT switch to the other
local server (it is already dead). Say so in ONE line, finish via non-local
channels (web, API, chat), name the one fix: full tray-exit + relaunch of
Claude Desktop.
PROOF: F-42 — shared client-side bridge, upstream bug (anthropics/claude-code
#66726 et al.). Corrected 2026-07-17; the old "switch servers" road wasted a
second 4-minute hang every time (see F-01).

## P-06 Running a multi-statement script on Windows
WHEN: Anything longer than one statement, or any bash invoked from PowerShell.
DO: Write the script to a file with a direct file-write tool, then execute it as two
plain tokens: `bash C:\path\to\script.sh`.
NEVER pass the script as a quoted string argument through a layered shell.
PROOF: The quoted-argument form was proven dead 4x — args get silently mangled and
commands no-op or half-run. File-then-two-tokens has never failed.

## P-07 Enumerating Kariim's repos for anything
WHEN: Any task that asks "what repos exist" or touches shift9.dev / just-a-pinch.
DO: Enumerate the `Kariimc` user AND the `shift9-studio` org. shift9.dev's source is
`shift9-studio/.github` — a pnpm+Turborepo monorepo, workspace root `shift9/`
(`apps/shift9-dev` → shift9.dev, `apps/just-a-pinch` → pinch.shift9.dev).
PROOF: User-scoped enumeration returns a complete-looking list that silently omits it.

## P-08 Judging whether a video frame is actually sharp
WHEN: Need to verify frame quality and the `view` tool won't render extracted frames.
DO: PIL + numpy Laplacian variance on the grayscale array — `lap.var()`.
PROOF: ~247 on a sharp final frame vs ~72 on a motion-blurred one, shift9.dev intro
work 2026-07-14. The gap is wide enough to decide on.

## P-09 Encoding a short web hero/intro clip
WHEN: Producing an MP4 that must autoplay inline and seek instantly.
DO: `ffmpeg -i <in> -t <secs> -c:v libx264 -crf 18 -preset medium -an -movflags +faststart <out>`
PROOF: Produced the correct shipped `intro.mp4` for shift9.dev, 2026-07-14.

## P-10 Registering a Claude Code hook on Windows
WHEN: Adding or fixing any hook entry in settings.json on this machine.
DO: Use exactly one interpreter form — `C:/PROGRA~1/Git/bin/bash.exe`.
PROOF: The only form that has ever executed; other paths/quoting silently no-op.

## P-11 Committing in my-skills
WHEN: Any commit to this repo — its `.githooks` gate suite runs 90s+.
DO: Detach the commit (P-03 pattern) and verify with a short `git log -1 --oneline`
read in a later call, same turn. Branch `claude/...`, PR ready-for-review, never push
to main, never self-merge without Kariim's explicit approval.
PROOF: Inline commits here exceed the ~25s relay ceiling and wedge the channel (F-02).

## P-12 Making a new skill findable by the finder
WHEN: Any new skill lands in skills/ — find-skills.py reads the committed
skills/finding-skills/index.json, NOT the live tree, so a new skill is
invisible to it until reindex.
DO: From repo root: `python skills/finding-skills/tool/build-index.py` then
`mv index.json skills/finding-skills/index.json` (no out-path arg = it writes
./index.json junk at cwd). Prove with `find-skills.py "<representative task>"`.
PROOF: 3d-master-modeler absent from finder results until reindex; ranked #1
(score 13) for "generate a 3d model in code with blender" after, 2026-07-21.
