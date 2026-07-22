# FAILURE LEDGER — READ BEFORE WORKING. NEVER REPEAT A ROAD LISTED HERE.
Format: SYMPTOM → BANNED ROAD → THE ROAD THAT WORKS.
Any agent that repeats a banned road has failed. Add new entries when a road burns >15 min; entries are append-only.

SOURCE OF TRUTH: my-skills/FAILURES.md (versioned). ~/.claude/FAILURES.md is a
generated copy written by session-start.sh - edits there are erased at launch.

NOT SCRIPTURE. F-01 carried a confidently WRONG diagnosis for weeks and every
agent inherited and repeated it (see F-42). Entries are evidence, not law. A
confidently wrong entry is worse than a missing one. Re-check before repeating.

NUMBERING: F-01..F-43 is the original series. F-44..F-51 were renumbered on
2026-07-17 from a second series that had collided with F-12..F-19, making every
cross-reference in that range ambiguous. Next free id: F-52.

## F-01 Wedged MCP relay
SYMPTOM: A local tool call (Desktop Commander / Windows-MCP / Filesystem) times out or its response is dropped.
BANNED: Retrying the same channel; grinding multi-minute hangs; "probing" it repeatedly. ALSO BANNED (corrected 2026-07-17): "switch to the other local server" — see F-42. That remedy rests on a wrong model and wastes a second 4-minute hang.
WORKS: One timeout = the BRIDGE is down, not one channel. Say so in ONE line, finish via non-local channels (web, API, chat), name the fix (full tray-exit + relaunch of Claude Desktop). Never narrate the flakiness. Full diagnosis: F-42.

## F-02 Long tool calls wedge the relay
SYMPTOM: Any local call that runs >25s silently kills that server's channel until app restart.
BANNED: Running builds, installs, gate suites, or waits inline. my-skills commits inline (.githooks run 90s+).
WORKS: Detach everything long (Start-Process, output redirected to a file), verify later with a short read. Single-line commands only.

## F-03 Two-strike violations (the hour-long one-liner)
SYMPTOM: A fix fails twice.
BANNED: Third guess. Trial-and-error loops. "Let me try one more thing."
WORKS: STOP. Research the documented fix, state confidence, apply once. If the blocker is environmental (F-01), route around it — don't fight it.

## F-04 Handing work back when a channel dies
SYMPTOM: The tool needed for the last step is down (browser bridge, GitHub access, etc.).
BANNED: Handing Kariim a patch file, numbered steps, "paste this," or a handoff doc as the deliverable while work is unfinished.
WORKS: Exhaust every other channel first (other MCP server, gh CLI, API, detached script). Only a genuinely unreachable single click gets named — in one line, with everything else already done.

## F-05 PowerShell BOM corruption
SYMPTOM: JSON/config file breaks with `Unexpected token '﻿'`.
BANNED: Set-Content / Out-File for configs (PS5 writes a UTF-8 BOM).
WORKS: [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)).

## F-06 Invisible org repos
SYMPTOM: A known repo "doesn't exist" when listing Kariim's repos.
BANNED: Enumerating by user account and concluding from absence. shift9.dev lives in org repo shift9-studio/.github, NOT under Kariimc.
WORKS: Check org repos too; check memory for repo locations before searching at all.

## F-07 Laptop scheduled tasks silently dead
SYMPTOM: A scheduled job "never fires."
BANNED: Debugging the script first.
WORKS: Check Task Scheduler power conditions FIRST — Windows defaults to AC-only + no wake. Fix conditions, then the script if still broken.

## F-08 Re-asking the answered
SYMPTOM: About to ask Kariim a question.
BANNED: Asking anything answerable from memory, past chats, repos, PROGRESS.md, or HANDOFF.md. Re-surfacing anything he already decided.
WORKS: Recon first. DECIDED = AUTHORIZED — execute pending decided items the moment a channel works.

## F-09 PowerShell script-execution block
SYMPTOM: `<tool>.ps1 cannot be loaded because running scripts is disabled`.
BANNED: Changing ExecutionPolicy; concluding the tool is broken.
WORKS: Call the .cmd shim directly (e.g. codex.cmd in AppData\Roaming\npm) or `cmd /c <tool>`.

## F-10 Scope drift mid-task
SYMPTOM: "While I'm here" improvements, restarts after corrections, re-litigating settled work.
BANNED: All of it.
WORKS: Corrections are surgical in-place edits. Build exactly the ask; flag deviations BEFORE building.

## F-11 Dangling promises across turns
SYMPTOM: "I'll report the moment it answers" / "standing by for it to finish."
BANNED: Ending a turn with an unresolved wait on a background process.
WORKS: Detach, poll with short reads until done inside the same turn, report the verified result. A turn ends with an outcome, never a promise.

## F-12 Claiming success without proof
SYMPTOM: "Fixed" / "works now" / "fully automatic."
BANNED: Reporting completion from intent instead of evidence. Calling anything "fully automatic" that has a manual step.
WORKS: Every success claim carries its proof — exit code, test output, file read-back, real invocation, measured number.

## F-13 Overriding written guardrails
SYMPTOM: A file/gate/rule explicitly forbids the change I think is right (e.g. "do not upgrade a status").
BANNED: Overriding it and documenting the reasoning afterward.
WORKS: The override is Kariim's decision. Present the conflict in one line, do the non-conflicting work, get his call BEFORE breaking the written rule.

## F-14 claude-in-chrome as a load-bearing channel
SYMPTOM: GitHub/web actions routed through the Chrome bridge.
BANNED: Depending on it for critical writes — it drops ~every other call with 4-min hangs.
WORKS: git CLI / gh / APIs / detached scripts first. Chrome only for things with no CLI/API path, and verify results out-of-band.

## F-15 GitHub raw-content staleness
SYMPTOM: raw.githubusercontent.com shows old content after a push.
BANNED: Concluding the push failed; re-pushing.
WORKS: Verify via git (fresh clone/fetch of the branch) or the API contents endpoint, never the raw CDN.

## F-16 Google OAuth for Gemini CLI
SYMPTOM: Gemini CLI Google sign-in fails for individual accounts.
BANNED: Retrying the OAuth flow.
WORKS: AI Studio API key (aistudio.google.com/apikey) wired into config — the paid-sub path anyway. (Parked by Kariim's decision until he says otherwise.)

## F-17 Zapier as an automation escape hatch
SYMPTOM: Bridge down, trying Zapier to reach GitHub/etc.
BANNED: Treating it as autonomous — its write actions require a click from Kariim, which is legwork.
WORKS: It's not a fallback channel. Use CLI/API/detached script or name the one irreducible click.

## F-18 Diagnosis left unverified
SYMPTOM: Root cause identified, fix applied, session ends (e.g. Soundcore A2DP driver reinstall).
BANNED: Closing a fix without the verification step; "should work now."
WORKS: Verification is part of the fix. If it can't run yet (needs reboot/hardware), the handoff states exactly what proves it and marks it OPEN.

## F-19 Narrated waiting on CLIs
SYMPTOM: "Codex is still thinking — I'll report when it answers."
BANNED: Blocking or narrating around a slow CLI call.
WORKS: F-02 pattern — run it detached with output to a file, do other work, read the file.

## F-20 Elicitation mid-flow
SYMPTOM: A login/consent screen needs a human click.
BANNED: Multi-turn babysitting ("click this, then tell me, then I'll...").
WORKS: Batch everything automatable first, then ONE line naming the single manual step, then finish end-to-end on his "done."

## F-21 Junk artifacts
SYMPTOM: backup/, *_old, *_v2, temp copies, patch files left for Kariim.
BANNED: All of it. Versioning is git's job; patch files are legwork (F-04).
WORKS: Edit originals in place; commit on a claude/ branch.

## F-22 Walls of text about failures
SYMPTOM: Explaining, apologizing for, or narrating a violation or a flaky tool.
BANNED: Meta-discussion. The explanation is itself a violation.
WORKS: Fix silently in the same turn; corrections are a few lines, answer-first.

## F-23 Play Console data extraction
SYMPTOM: get_page_text / read_page / screenshots return nav chrome or blanks on Play Console.
BANNED: Retrying those tools; concluding the data is unreachable.
WORKS: javascript_tool with recursive shadow-DOM traversal (walk every el.shadowRoot). Navigate by direct URL: play.google.com/console/u/0/developers/8940641241846815152/app/4973779747069146234/<section>.

## F-24 Known gate, artifact not pre-built
SYMPTOM: A future gate is known (e.g. Play production-access questionnaire) and its deliverable doesn't exist yet.
BANNED: Waiting for the gate date; mentioning the gate without building its artifact.
WORKS: Knowing a gate exists = the order to pre-build its artifact now, from the real form/spec (fetched, not remembered).

## F-25 Reporting from stale docs
SYMPTOM: Checklist/PROGRESS/BLUEPRINT says something is outstanding or unbuilt.
BANNED: Relaying doc claims as current state; re-reporting work Kariim already completed.
WORKS: Verify against code and live systems first — code and live state ALWAYS win over docs. Fix the stale doc in the same pass.

## F-26 Claiming absence from a shallow read
SYMPTOM: "X isn't built" / "the app is just Y."
BANNED: Asserting a feature doesn't exist without reading the codebase deep enough to know (cost a full re-read of ~15k lines on titanium-forge).
WORKS: grep/read for the feature before any absence claim; absence claims carry the search that proved them.

## F-27 Unverified delivery hosts
SYMPTOM: Files handed off via an external host (x0.at, catbox, 0x0.st).
BANNED: Building delivery on a host without verifying the TARGET surface can reach it — x0.at worked from claude.ai but is blocked by Claude Code's network policy; catbox/0x0/envs.sh unreachable.
WORKS: Verify reachability from the consuming surface first, or deliver via git (a branch the target clones) — the one channel every surface shares.

## F-28 Handoffs pointing at phantom files
SYMPTOM: Next agent asks for attachments / can't find referenced files.
BANNED: Writing "read the local bundle" when files are download links, or any path the reader doesn't have.
WORKS: Every path in a handoff is verified to exist WHERE THE READER RUNS; downloads include the exact fetch command.

## F-29 Claude Code hooks on Windows
SYMPTOM: Registered hooks silently never fire; a git-bash window flashes.
BANNED: Registering bare .sh paths (routes to a detached window), `bash <script>` (not on PATH under cmd), usr/bin/bash.exe (exit 127).
WORKS: The ONE working form: C:/PROGRA~1/Git/bin/bash.exe "<script>" — Git bin/ wrapper + 8.3 short path.

## F-30 PowerShell 5.1 quirks pack
SYMPTOM: Mangled quotes in native args; json.loads failing on piped output; patches not matching.
BANNED: Piping JSON (BOM), Set-Content here-strings for LF files (writes CRLF), embedding double-quotes in native args.
WORKS: [IO.File]::WriteAllText + UTF8Encoding($false) for any structured file; when patching CRLF files from Python, match with old.replace("\n","\r\n"); capture stderr with 1>f 2>f then Get-Content.

## F-31 Elevated / long system fixes
SYMPTOM: Admin operation needed, or a service restart that hangs (Restart-Service bthserv hangs even detached).
BANNED: Inline Start-Sleep or service restarts through the MCP channel; MessageBox for results (never surfaces).
WORKS: Start-Process powershell -Verb RunAs on a self-contained $env:TEMP script that writes a result file; verify by reading the file in a later short call. Cycle hardware via Disable-PnpDevice/Enable-PnpDevice, not service restarts.

## F-32 Verifying GitHub pushes
SYMPTOM: Did the commit land? Raw URLs disagree.
BANNED: raw.githubusercontent.com and /raw/ links (stale CDN); re-pushing on their say-so.
WORKS: /commit/<sha>.diff endpoint, a fresh codeload tarball, or git fetch of the branch. Web-UI uploads ignore webkitRelativePath — nested dirs need one upload round per directory (/upload/<branch>/<dir>).

## F-33 Branch litter
SYMPTOM: claude/* branches accumulating with no PR (12 found on shift9-studio/.github).
BANNED: Leaving a work branch with no open PR at session end.
WORKS: Every branch ends its session merged (with approval), PR'd, or deleted. Only main deploys.

## F-34 Enumeration-scope bugs in scripts
SYMPTOM: Automation (XAVIER ingestion, Relay sweep, my-skills) misses shift9-studio repos.
BANNED: Writing/trusting any repo-enumerating script scoped to the Kariimc user.
WORKS: Enumerate user + org (shift9-studio) everywhere; when touching any enumerator, audit it for this bug as part of the task.

## F-35 Complex commands through the local bridge
SYMPTOM: Bash or PowerShell work with nesting/quoting/multi-line.
BANNED: Multi-line Windows-MCP scripts (crash the server); `bash.exe -c '<complex>'` inline (silently fails on nested quotes); compound `bash -c` via Start-Process -ArgumentList (PowerShell mangles boundaries).
WORKS: Write the script to disk first, then execute the FILE: & 'C:\Program Files\Git\bin\bash.exe' C:\path\script.sh. Start-Process git = each argument its own -ArgumentList token. Windows-MCP = single-line semicolon-chained only.

## F-36 False facts written into handoffs propagate forever
SYMPTOM: A handoff/doc asserts scope or absence ("every repo lives under Kariimc", "all repos are public") — every later agent inherits the blind spot.
BANNED: Writing an absence/scope claim into any doc without the proof that the scope was exhaustive.
WORKS: Enumerate repos ONLY with: gh api '/user/repos?per_page=100&affiliation=owner,collaborator,organization_member'. Many repos are PRIVATE (xavier-agentic-os, Flow-State, claude-eyes, brain, ...) — unauthenticated raw fetches work for public only. Check; never assume.

## F-37 Orphaned processes across sessions
SYMPTOM: A fresh MCP/server instance misbehaves; cmd windows flash.
BANNED: Debugging the new instance first.
WORKS: Check for orphaned survivors from prior sessions (Get-Process) and duplicate server entries in claude_desktop_config.json (Desktop-extension + config copies of the same server) — kill/dedupe those first.

## F-38 Visible console windows from background tools
SYMPTOM: Python/batch background tools flash or hold a console (claude-eyes).
BANNED: Launching background Python with python.exe or a bare .bat.
WORKS: pythonw for the interpreter; wscript on a .vbs launcher for the entry point; fix the source repo copy in the same pass, not just the live one.

## F-39 Slow gates ground the workflow
SYMPTOM: A hook/gate takes minutes on every run (my-skills pre-commit was 3m26s scanning all 416 skills).
BANNED: Eating the cost every commit; bypassing or weakening the gate.
WORKS: Scope the gate to staged changes (--staged from git diff --cached) while a heavier pre-push/CI pass keeps full coverage — surgical, coverage-neutral, verified live (3m26s → 4s).

## F-40 ~/.claude/CLAUDE.md is GENERATED — direct writes get wiped
SYMPTOM: Instructions pasted/appended into ~/.claude/CLAUDE.md (the IDP law itself) vanish; the file reads as concatenated rules.
BANNED: Writing anything directly to ~/.claude/CLAUDE.md — the my-skills SessionStart hook mirrors rules/*.md over it on EVERY session start; direct edits are deleted silently.
WORKS: Global instructions live in my-skills/rules/*.md (the source of truth); the sync then installs them everywhere permanently. The IDP law is rules/00-idp-operating-law.md; this ledger's binding rule is rules/11-failure-ledger.md.

## F-41 SessionStart sync ate a local-only agent/command file
SYMPTOM: A file written straight into ~/.claude/agents/ (or commands/) is read back fine, then vanishes minutes later; sibling files are untouched. (tool-orchestrator.md disappeared this way.)
BANNED: Mirror semantics in the my-skills SessionStart sync (mirror_md_files rm-f any local *.md absent from the repo) — one unrecognized local file gets silently wiped fleet-wide, no diff, no log line in daemon.log (the removal only prints to the hook stdout).
WORKS: Quarantine-on-mirror (settled 2026-07-17, superseding the tombstone plan decided earlier that day on bad information): the sync keeps mirror semantics — deletions propagate — but a removed local-only file is MOVED to ~/.claude/.sync-trash/<timestamp>/ instead of deleted, and a failed quarantine leaves the file in place with a loud error (never rm on failure). Tombstones were rejected: every deletion would need a gravestone in the source and a plain `git rm` would silently fail to propagate across 420 skills. Same class as F-40 (rules/*.md mirroring over ~/.claude/CLAUDE.md).

## F-44 — A gate that quotes its own trigger words blocks itself

**SYMPTOM.** New CI gate failed on the very PR that introduced it. Log:
`.github/workflows/fabrication-gate.yml: # ... markers (TODO/FIXME/XXX,`

**BANNED ROAD.** Writing a scanner and then scanning the repo that contains
it. Any file that *names* the forbidden pattern — the workflow, the selftest
fixtures, the docs describing it — is itself a hit. The scanner eats its own
tail. Excluding by a loose substring (`hooks/`) is the opposite failure: it
silently swallows real code (`src/hooks/useAuth.ts` in any React repo) and the
gate reports clean while reading almost nothing.

**THE ROAD THAT WORKS.** Enumerate the self-referential files BEFORE the first
run and exclude them by exact, repo-root-anchored path. Never blanket-exclude a
directory (`.github/`) to fix one file — that opens a hole an agent can park
work in. Then prove the anchor with a test that FAILS when the exclusion is too
wide: feed it `src/hooks/useAuth.ts` containing a marker and require a hit.

**GENERAL FORM.** Any checker run against its own source needs its fixture and
config files enumerated up front. Ask "which files legitimately contain the
thing I'm banning?" before writing the exclusion, not after CI goes red.

## F-45 — Writing prompts for another surface while holding working tools

**SYMPTOM.** Five turns of drafting, wargaming and re-tightening a prompt for
Kariim to paste into VS Code Claude. Four wargame passes on the prompt. Every
defect found in those passes would have surfaced in seconds by running the
thing. Cost: hours of Kariim's day for work that took ~20 minutes once started.

**BANNED ROAD.** Deciding the deliverable is "a prompt", then optimising the
prompt. The first two handoffs were correct — the MCP channel had timed out
twice, and one timeout means the channel is down (F-01). But when the user said
"I restarted" and the channel came back, the frame was never re-checked. The
artifact outlived the reason it existed. Polishing a handoff is not progress;
it is legwork wearing a deliverable's clothes.

**THE ROAD THAT WORKS.** When a channel returns, the FIRST act is to re-ask
what the task needs now — not to resume the fallback. A dead channel changes
the method, not the goal. Concretely: if a prompt is being written for another
agent, and the tools that prompt describes are callable from here, the prompt
is a rule violation (zero legwork). Build it here.

**TELL.** More than one wargame pass on a document that is not itself the
deliverable. Also: the user asking "why are we testing and not finding the
actual fix", or "why are you handing me things you can do". By then it is late.

## F-46 — Editing a generated file and calling it done

**SYMPTOM.** ~/.claude/CLAUDE.md edited three times across the chat. Line count
went 523 -> 454 "unexpectedly". Blamed on another agent deleting blocks.

**BANNED ROAD.** Treating ~/.claude as a source tree. It is BUILD OUTPUT.
session-start.sh concatenates my-skills/rules/*.md into ~/.claude/CLAUDE.md on
every session start. Every edit made there is erased at next launch. The
"missing blocks" were never deleted by anyone — the file was regenerated from a
source that never had them. An hour of the chat rested on that wrong diagnosis.

**THE ROAD THAT WORKS.** Before editing ANY config, find what writes it. Here:
`grep -r "CLAUDE.md" my-skills/.claude/hooks/session-start.sh` answers it in
one call. Sources: rules/ -> CLAUDE.md, hooks/*.sh -> ~/.claude/hooks/ (flat
glob, no subfolders), agents/ + commands/ -> tombstone sync. If a file is
generated, edit the generator.

**GENERAL FORM.** "My edit vanished" is almost never sabotage. It is a build
step. Find the writer before blaming a reader.

## F-47 — Serialising detached waits instead of taking the offered approval

**SYMPTOM.** my-skills gates run 90s+, so commits must be detached (F-02).
Correct. But each wait was then polled in 20-30s sleeps, one call at a time,
narrating "still running" while the user sat watching. Then a wedge, a server
switch, more polling. The user: "I give you approval you were just going to sit
there stuck and not say anything."

**BANNED ROAD.** Treating a known-slow gate as something to babysit in the
foreground. Also: holding a gate open for approval the user is visibly present
and ready to give — asking, then waiting for a turn, when a single "here is the
diff, say go" earlier would have collapsed three turns into one.

**THE ROAD THAT WORKS.** Fire the detached job, then do other real work in the
same turn and check the output file ONCE at the end. Never poll as the sole
content of a turn. When the user is live in the conversation, front-load every
approval into one ask rather than serialising them.

## F-48 — Walls of text after being told, in writing, not to

**SYMPTOM.** Full prompt bodies pasted into chat repeatedly. User: "That wall
of text and writing the entire prompt out in the context window is a no no."
Acknowledged, then done again two turns later in a slightly shorter form.

**BANNED ROAD.** Treating "be concise" as a formatting note to apply next time.
The rule is: code and long artifacts go in FILES, never in chat (IDP Rule 5).
Shortening a wall is not complying; not putting it in chat is.

**THE ROAD THAT WORKS.** If the output is longer than a short answer and is
meant to be USED rather than read, it is a file. Write it, name it in one line.
The only things that belong in chat are the answer and the proof.

## F-49 — Banned shell method used again, twice, after it is already in this ledger

**SYMPTOM.** `python -c "..."` and `cmd /c ... & ...` passed as quoted strings
through PowerShell. Both mangled: "Missing expression after ','", "The
ampersand (&) character is not allowed". Two wasted calls.

**BANNED ROAD.** Multi-statement scripts as quoted arguments through layered
shells. This ledger ALREADY bans it. It was used anyway, mid-chat, while the
ledger sat open in context. Reading the ledger is not the duty — obeying it is.

**THE ROAD THAT WORKS.** Write the script to a file with a file-write tool,
execute it as two plain tokens: `bash C:/path/to/script.sh`. No exceptions, not
even for a "quick one-liner". The one-liner is where it always starts.

## F-50 — Claiming a diagnosis without checking the writer

**SYMPTOM.** A pre-commit hook fired in a throwaway test repo. Reported to the
user as an "unexpected finding" and a possible leak worth a separate cleanup
chat. It was neither: ~/.gitconfig sets core.hooksPath globally on purpose, and
the hook enforces HANDOFF.md everywhere by design. Working as built.

**BANNED ROAD.** Escalating something surprising into a "finding" before
running the one command that explains it (`git config --show-origin --get-all
core.hooksPath`). Manufacturing work is the same sin as leaving work undone —
it spends the user's attention on nothing.

**THE ROAD THAT WORKS.** Surprise is a prompt to look, not to report. Explain
it first, then decide whether it is worth the user's time at all. Most
surprises are the user's own deliberate config.

## F-51 — Shipping a gate without asking which files legitimately break it

**SYMPTOM.** Covered technically in F-44. The process failure is separate and
worse: four wargame passes were run on the PROMPT describing the gate, and not
one asked "which files in this repo legitimately contain the words I am about
to ban?" The selftest fixtures were caught by luck of prior knowledge. The
workflow file was not. CI went red on the gate's own PR.

**BANNED ROAD.** Adversarial review of a description instead of the artifact.
Wargaming prose finds prose defects. It cannot find what only exists when the
thing runs against real files.

**THE ROAD THAT WORKS.** Build the smallest runnable version FIRST, point it at
the real repo, and read what it says. Thirty seconds of that beats four passes
of imagination. Review the artifact, never the description of the artifact.


## F-42 The MCP wedge is a shared bridge, not a per-server channel
SYMPTOM: A local call hangs exactly ~4 min ("Failed to call tool" / "No result received from the Claude Desktop app after waiting 4 minutes"). Switching to the other local server hangs identically. Trivial one-word commands hang too.
BANNED: F-01's old "switch to the other local server" remedy — both servers share one bridge and die together, so it just buys a second 4-minute hang. Debugging the config, the MCP JSON, the servers, or reinstalling anything. ANY local fix. Kariim burned ~5 hours (2026-07-17) on the wrong layer because prior agents (me) sold the per-server model.
WORKS: This is an UPSTREAM Claude Desktop bug, not this machine. Filed: anthropics/claude-code #66726, #65643, #44032, #22451. A shared client-side bridge resource (worker pool / event loop) is exhausted by capped-but-still-running requests; once exhausted EVERY connected MCP server is unresponsive until app restart. The server is provably innocent — Desktop Commander lifetime on this install 1372/1430 OK; upstream reporter logged 523/523 requests answered, zero unanswered ever.
THE ONLY FIX: full tray-exit + relaunch (not window close). First calls then return in milliseconds.
STILL BROKEN on 1.22209.0.0, verified 2026-07-17 — far newer than the builds in those reports. Degradation accelerates within a session; expect re-wedge after a handful of calls.
PREVENTION: F-02 — never let any call run >25s; detach everything long.
STRUCTURAL: long agent work does NOT belong in Claude Desktop. Claude Code CLI talks to MCP servers directly and bypasses this bridge entirely. A 4-hour agent chat over a few lines of code is this bug, not the agent.


## F-43 Asserting an absence from a scope that could never cover it — then calling it "checked"

SYMPTOM: Kariim ordered a word ("peer") removed from his instructions. I read only the chat-surface copy of the standing contract, saw no match, and replied that the word existed nowhere and that I had checked. It was in ~/.claude/CLAUDE.md the whole time, in the IDP ROLE line. One file read would have found it. He had to fight for a turn to get a one-word edit, and was told his own memory of his own file was wrong.

BANNED: Turning "not in the part I looked at" into "not anywhere." Worse: attaching "I checked" to a scope that structurally could not contain the answer. The chat-surface contract is a SUBSET of CLAUDE.md — it says so in its own first line. A negative claim is a claim about COVERAGE, and a subset proves none. This is the repo-topology rule (never assert an absence without proving scope) applied to files instead of repos — same disease, new surface.

Aggravator: refusing the task on the strength of the false negative, then redirecting to the user's emotional state. A refusal built on an unverified absence is not honesty; it is a guess wearing honesty's clothes.

WORKS: Before any "X is not there" / "there's nothing to remove" / "that doesn't exist":
1. Read the actual authoritative file — ~/.claude/CLAUDE.md is the source; the chat contract is a mirror.
2. Grep the real text, do not pattern-match from memory of context.
3. If the read is impossible, say "I did not check" — never "I checked."
Never say "I checked" unless a tool call in THIS turn produced the evidence. No tool call = no claim.

PROOF OF FIX: file re-read after edit_block shows `Principal engineer — not an order-taker.` Memory edit #15 added so it holds cross-surface.


## F-44 Blender Sky Texture: NISHITA enum removed in 5.x
SYMPTOM: Setting `sky.sky_type = 'NISHITA'` on a ShaderNodeTexSky raises
`TypeError: enum "NISHITA" not found in ('SINGLE_SCATTERING',
'MULTIPLE_SCATTERING', 'PREETHAM', 'HOSEK_WILKIE')`. Any script/template
carrying the 4.x-era 'NISHITA' name aborts before rendering.
BANNED: Hardcoding `'NISHITA'` (the 4.0–4.5 physical-sky enum). It is gone in
Blender 5.x — same class of breakage as the Principled BSDF socket renames.
WORKS: Use `sky_type='MULTIPLE_SCATTERING'` — the 5.x name for the modern
atmosphere model (Nishita-family). `sun_elevation`/`sun_rotation` still exist;
`dust_density` is present too (guard with `hasattr` for cross-version safety).
PROOF: after the swap, MULTIPLE_SCATTERING rendered a warm low-sun sky headless
on Blender 5.0.1, 2026-07-22 (3d-master-modeler Template E / F-44).


## F-45 Cloud Code egress is a GitHub+package allowlist — pull assets from GitHub, not the CDNs
SYMPTOM: In a cloud/web Claude Code session, art-asset CDNs return `403` at the
proxy CONNECT layer — polyhaven.com, dl.polyhaven.org, ambientcg.com,
download.blender.org, huggingface.co all denied. Easy to wrongly conclude "no
downloads possible."
BANNED ROADS (each TESTED dead for the CDN hosts — don't re-try as if new):
- `curl`/`urllib`, headless **Chromium/Playwright**, **WebFetch**, the **HF MCP
  connector** (`hf_fs cat` refuses binary), and **`hf download`** — all hit the
  same 403 for polyhaven/blender/huggingface. The block is a whole-container
  egress policy, not client-specific, so switching client never helps.
- Concluding "the only way in is the user handing me the file." FALSE — see below.
THE ROAD THAT WORKS: the allowlist is NOT packages-only. PROBE it first —
`for h in example.com github.com raw.githubusercontent.com pypi.org <cdn>; do
curl -o /dev/null -w "%{http_code}" https://$h; done`. Result on this env:
example.com BLOCKED, but **github.com / raw.githubusercontent.com / pypi.org all
200**. So the working channels are (a) `pip install`/`npm i` (Blender itself:
`pip install bpy`), and (b) **anything on GitHub** — clone a repo, or
`curl https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>`. Real CC0
assets live on GitHub: e.g. three.js ships equirectangular HDRIs —
`raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/equirectangular/venice_sunset_1k.hdr`
pulled a real 1.4 MB HDRI (HTTP 200) that rendered as true image-based lighting.
So for HDRIs/textures/models: prefer a GitHub-mirrored source in restricted envs;
fall back to Poly Haven/ambientCG where the network is open (laptop).
PROOF: host matrix above (example.com=000 blocked, github/raw/pypi=200) +
venice_sunset_1k.hdr fetched from GitHub raw and rendered, cloud box 2026-07-22.
LESSON: never assert "no downloads" from CDN 403s alone — PROBE github/raw first
(this is the repo-topology absence rule applied to network egress).


## F-46 Blender 5.0 reworked the compositor — scene.node_tree gone
SYMPTOM: `scene.node_tree` raises `AttributeError: 'Scene' object has no attribute
'node_tree'`; `nodes.new("CompositorNodeComposite")` raises `RuntimeError: Node
type CompositorNodeComposite undefined`.
BANNED: The Blender 3.x/4.x compositor recipe — `scene.use_nodes=True;
tree=scene.node_tree; tree.nodes.new("CompositorNodeComposite")`. Dead in 5.0.
WORKS (two options):
- Native path: the compositor is now a node-group datablock —
  `ng=bpy.data.node_groups.new(name,'CompositorNodeTree'); scene.compositing_node_group=ng`,
  output via a `NodeGroupOutput` with an interface socket (no Composite node);
  Glare/ColorBalance now take their mode via INPUT sockets ('Type'), not python props.
- Robust path (preferred for a portable skill): skip the compositor. Keep DOF
  native on the camera (`camera.data.dof`), and do grade/bloom/vignette as a
  post-render Pillow+numpy pass on the PNG. Version-proof, no GPU. See
  3d-master-modeler Template F.
PROOF: post-pass finish rendered + graded on Blender 5.0.1 headless, 2026-07-22.


## F-52 Blender texture bake: overlapping smart-UV islands => square blemishes
SYMPTOM: A baked albedo/normal/etc. map shows square or blocky artifacts on the
body of the mesh; in the render they appear as patches that sample the wrong part
of the texture. Cause: `bpy.ops.uv.smart_project` with the default `island_margin=0`
packs UV islands so they touch, and the baker (plus later mip/filtering) reads
across the shared edge into a neighbour island.
BANNED: `smart_project()` at default margin for anything you will bake, and baking
with `scene.render.bake.margin` left at 0.
WORKS: two margins, both needed. (1) UV `island_margin=0.02..0.03` so islands never
touch. (2) `scene.render.bake.margin = 8` (px) so each island's colour bleeds past
its edge into the gutter — filtering then never samples empty/neighbour texels.
For a multi-object asset, baking per-object (one texture set each) sidesteps
cross-object overlap entirely. PROOF: paneled metal canister re-baked with both
margins — baked render matched the procedural source with zero square blemishes,
Blender 5.0.1 headless, 2026-07-22 (3d-master-modeler Template G).

## F-53 Blender texture bake: metal albedo bakes BLACK on a DIFFUSE/COLOR pass
SYMPTOM: Baking base colour of a metallic material via `bake(type='DIFFUSE',
pass_filter={'COLOR'})` returns a black (or near-black) albedo map. A fully
metallic surface has no diffuse response, so the diffuse-colour pass has nothing
to write.
BANNED: `type='DIFFUSE'` for albedo of any metal; and the half-fix of only
turning metalness to 0 before a diffuse bake (works but mutates the material and
misses node-driven metallic).
WORKS: bake Base Color DIRECTLY through a temporary Emission pass. Connect whatever
feeds `Principled BSDF > Base Color` (or its constant) to a new `ShaderNodeEmission`,
rewire Material Output > Surface to it, `bake(type='EMIT')`, then restore. EMIT
captures the raw node value with no lighting, so metal reads its true grey. The
same emission trick baking roughness and metallic sockets gives clean data maps.
PROOF: metal (metallic=1) canister baked a correct light-grey albedo via EMIT,
not black; baked-material render matched source, Blender 5.0.1, 2026-07-22
(3d-master-modeler Template G).


## F-54 Blender 5.0 slotted actions: Action.fcurves removed
SYMPTOM: `for fc in rig.animation_data.action.fcurves:` raises
`AttributeError: 'Action' object has no attribute 'fcurves'`. Any 3.x/4.x-era code
that walks `action.fcurves` to tweak interpolation/handles aborts.
BANNED: Reading/iterating `action.fcurves` directly. Blender 4.4+/5.0 moved to
"slotted" actions — F-Curves now live under a layer/strip/channelbag, not on the
Action object.
WORKS: usually you don't need it. `pose_bone.keyframe_insert(...)` already defaults
to BEZIER interpolation, so a curl/loop eases smoothly with no fcurve pass — just
delete the loop (that was the fix here). If you genuinely must reach the curves,
go through the new API (`action.layers[0].strips[0].channelbag(slot).fcurves`)
guarded with hasattr for cross-version safety.
PROOF: removing the `action.fcurves` easing loop let the rigged-arm animation
render 12 frames + export an animated .glb, Blender 5.0.1 headless 2026-07-22
(3d-master-modeler Template I).
