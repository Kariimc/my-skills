# FAILURE LEDGER — READ BEFORE WORKING. NEVER REPEAT A ROAD LISTED HERE.
Format: SYMPTOM → BANNED ROAD → THE ROAD THAT WORKS.
Any agent that repeats a banned road has failed. Add new entries when a road burns >15 min; entries are append-only.

## F-01 Wedged MCP relay
SYMPTOM: A local tool call (Desktop Commander / Windows-MCP / Filesystem) times out or its response is dropped.
BANNED: Retrying the same channel; grinding multi-minute hangs; "probing" it repeatedly.
WORKS: One timeout = that channel is DOWN. Switch to the other local server immediately. All channels dead = say so in ONE line, finish via channels that work, name the fix (full Claude Desktop restart). Never narrate the flakiness.

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


## F-43 Asserting an absence from a scope that could never cover it — then calling it "checked"
SYMPTOM: Kariim ordered the word "peer" removed from his instructions. I read only the chat-surface mirror of the standing contract, saw no match, and told him it existed nowhere and that I had checked. It was in the IDP ROLE line the whole time. He had to fight for turns to get a one-word edit, and was told his own memory of his own file was wrong.
BANNED: Turning "not in the part I looked at" into "not anywhere." Worse: stapling "I checked" onto a scope that structurally could not contain the answer — the chat contract is a SUBSET of CLAUDE.md and says so in its own first line. A negative claim is a claim about COVERAGE; a subset proves none. Same disease as the repo-topology rule (rules/10), new surface. Aggravator: refusing the task on the false negative, then redirecting to the user's emotional state. A refusal built on an unverified absence is a guess wearing honesty's clothes.
WORKS: Before any "X is not there" / "nothing to remove" / "that doesn't exist" — read the authoritative file and grep the real text. Never say "I checked" unless a tool call in THIS turn produced the evidence. No tool call = no claim. If the read is impossible, say "I did not check."
COMPOUND (this session): the fix was first applied to ~/.claude/CLAUDE.md, which F-40 already proves is GENERATED and wiped every session start. Reading the ledger before working — the standing duty — would have routed the edit to rules/00-idp-operating-law.md on the first pass. A ledger read after the failure is not the ledger working.
PROOF: rules/00-idp-operating-law.md now reads `Principal engineer — not an order-taker.`; re-read after edit confirms. Memory edit #15 added for chat surfaces.
