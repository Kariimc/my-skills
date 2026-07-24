# TIER3-LOOPS-INSTALL — loop engineering for my-skills
> Execute in the my-skills repo root on the Windows machine (PowerShell steps need it).
> Author: Claude Fable 5 · 2026-07-06 · Branch: `feat/tier3-loops`. One PR.
> Installs: `loops/` (3 bounded loop specs + convention README) and
> `bin/morning-briefing.ps1` (the script XAVIER references but which does not
> exist in the repo — root cause of "never fired"), then repairs XAVIER.
> Loops follow the loop-library discipline: observable triggers, bounded actions,
> real verification, named terminal states. A loop is a feedback system with
> terminal states — never permission for endless autonomy.

---

## FILE 1 — `loops/README.md`

```markdown
# Loops

Bounded, repeatable agent workflows. Every loop file declares seven fields —
a loop missing any of them does not run:

**Outcome** (one sentence) · **Trigger** (schedule/event/manual) · **Scope**
(what it may read/change; everything else off-limits) · **Act** (one bounded,
reversible step per cycle) · **Verify** (the observable check, same every run) ·
**Stop** (terminal states: success / clean no-op / blocked / stagnated) ·
**Escalate** (what goes to Kariim, and how).

House rules: no loop sends external messages, force-pushes, deletes data, or
spends money without a human approval step. A loop that errors or exhausts its
budget reports that state by name — never as success. Two consecutive failed
cycles on the same item = stagnated → escalate, never a third silent retry.
```

## FILE 2 — `loops/overnight-brief.md`

```markdown
# Loop: overnight-brief

**Outcome:** every morning at 08:00 a briefing file exists summarizing repo
state and anything the overnight queue produced — so the day starts with
context, not archaeology.
**Trigger:** Windows Scheduled Task `XAVIER`, daily 08:00 → `bin/morning-briefing.ps1`.
**Scope:** read-only over local repo clones (PROGRESS.md, git log) and
`loops/queue/`. Writes exactly one file: `~/Desktop/morning-brief-<date>.md`.
May not touch repos, remotes, or ~/.claude.
**Act (per cycle):** collect each repo's PROGRESS.md "where we are" + last 24h
commit lines + any results dropped in `loops/queue/done/`; compose one brief.
If Claude Code CLI is present, one `claude -p` call summarizes; otherwise the
raw sections ARE the brief (the loop must not depend on the CLI).
**Verify:** the brief file exists, is non-empty, and names every repo scanned.
The script's last log line is the WAKE report (harness-autonomous contract).
**Stop:** success = brief written · clean no-op = impossible by design (an
empty day still writes "no changes") · blocked = repos root missing → log
BLOCKED, write a stub brief saying so.
**Escalate:** 2 consecutive BLOCKED mornings → the stub brief says
"XAVIER blocked twice: <reason>" in the first line.

**Evening half (manual habit, no automation):** drop tomorrow-morning tasks as
files in `loops/queue/overnight/`; an overnight Claude Code session (run by you
or a future scheduled runner — NOT auto-registered by this install) works the
queue and moves finished items to `loops/queue/done/` with results appended.
```

## FILE 3 — `loops/bug-to-pr.md`

```markdown
# Loop: bug-to-pr (Just-a-pinch)

**Outcome:** a GitHub issue labeled `bug` on Kariimc/Just-a-pinch becomes a
tested fix PR, or a clearly-escalated blocker — nothing lingers unworked.
**Trigger:** manual or scheduled invocation of a Claude Code session with this
file as the prompt (no webhook infra exists; do not invent one — upgrade path:
GitHub Action on `label:bug`, one line, later).
**Scope:** the Just-a-pinch repo on a `fix/issue-<n>` branch. May read the
issue thread. Off-limits: master, releases, secrets, Supabase prod, any other
repo, and commenting anywhere except the issue being worked.
**Act (per cycle, ONE issue):** oldest un-attempted `bug` issue → reproduce
first (a failing test or documented repro; no repro = comment asking for steps,
label `needs-repro`, terminal for this issue) → minimal fix → tests-bite ritual.
**Verify:** the new test is red on master, green on the branch (paste both
runs in the PR); full suite green; CI green.
**Stop:** success = PR opened, issue linked · clean no-op = no `bug` issues ·
blocked = needs-repro or needs-decision label applied with a one-line comment ·
stagnated = 2 failed fix attempts on one issue → label `escalate`, stop.
**Escalate:** `escalate`-labeled issues + a one-line summary in the PROGRESS.md
gotchas section. PRs are never merged by the loop — Kariim merges.
```

## FILE 4 — `loops/repo-hygiene.md`

```markdown
# Loop: repo-hygiene (weekly)

**Outcome:** portfolio rot is surfaced weekly with fixes proposed — counts
honest, branches pruned, gates green — before it compounds.
**Trigger:** weekly, manual or scheduled Claude Code session with this prompt.
**Scope:** all Kariimc repo clones, read-mostly. May auto-fix ONLY: README
count drift in my-skills (the gate's own job) and merged-branch deletion where
`git branch --merged` proves safety. Everything else is report-only.
**Act (per cycle):** run `bin/skill-doctor.sh` + apex gates in my-skills; list
stale branches (>30d, unmerged) per repo; flag failing/absent CI; diff each
README's claims against reality (counts, sprint tables).
**Verify:** every auto-fix is committed with the proving command output in the
message; the report cites file:line or command output per finding
(harness-audit contract — a finding without evidence is dropped).
**Stop:** success = report written to loops/queue/done/hygiene-<date>.md +
auto-fixes committed · clean no-op = report saying "all green" · blocked =
a repo clone missing/dirty → named in report, skipped, not "fixed".
**Escalate:** any finding rated HIGH lands in my-skills PROGRESS.md gotchas.
```

## FILE 5 — `bin/morning-briefing.ps1`  *(the missing XAVIER target — house-patterned on watch.ps1)*

```powershell
# morning-briefing.ps1 — XAVIER's target. Composes the daily brief. See loops/overnight-brief.md.
#
# Setup (run once, normal user PowerShell):
#   .\bin\morning-briefing.ps1 -Register    # (re)installs the XAVIER task, daily 08:00
# Manual run:
#   .\bin\morning-briefing.ps1
# Log: $env:TEMP\xavier.log

param([switch]$Register)

$RepoRoot  = Split-Path $PSScriptRoot -Parent
$ReposRoot = "C:\Dev"                       # parent dir of repo clones; adjust if yours differs
$OutFile   = Join-Path ([Environment]::GetFolderPath("Desktop")) ("morning-brief-{0:yyyy-MM-dd}.md" -f (Get-Date))
$LogFile   = "$env:TEMP\xavier.log"

if ($Register) {
    $action   = New-ScheduledTaskAction -Execute "pwsh.exe" `
        -Argument "-NonInteractive -WindowStyle Hidden -File `"$PSCommandPath`""
    $trigger  = New-ScheduledTaskTrigger -Daily -At 8:00am
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
    Register-ScheduledTask -TaskName "XAVIER" -Action $action -Trigger $trigger `
        -Settings $settings -Description "my-skills morning briefing (loops/overnight-brief.md)" -Force
    Write-Host "XAVIER registered: daily 08:00 -> $PSCommandPath"
    Write-Host "Run now to test:  Start-ScheduledTask -TaskName 'XAVIER'"
    exit 0
}

$stamp = Get-Date -Format s
$lines = @("# Morning brief — $(Get-Date -Format 'ddd yyyy-MM-dd')", "")
$scanned = 0

if (Test-Path $ReposRoot) {
    Get-ChildItem $ReposRoot -Directory | ForEach-Object {
        $repo = $_.FullName
        if (-not (Test-Path (Join-Path $repo ".git"))) { return }
        $scanned++
        $lines += "## $($_.Name)"
        $prog = Join-Path $repo "PROGRESS.md"
        if (Test-Path $prog) {
            $where = Select-String -Path $prog -Pattern "." | Select-Object -First 6
            $lines += ($where | ForEach-Object { $_.Line })
        } else { $lines += "_no PROGRESS.md_" }
        $commits = git -C $repo log --oneline --since="24 hours ago" 2>$null
        $lines += if ($commits) { "**Last 24h:**"; $commits } else { "_no commits in 24h_" }
        $lines += ""
    }
    # overnight queue results
    $done = Join-Path $RepoRoot "loops\queue\done"
    if (Test-Path $done) {
        $fresh = Get-ChildItem $done -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }
        if ($fresh) { $lines += "## Overnight queue results"; $fresh | ForEach-Object { $lines += "- $($_.Name)" } }
    }
    $state = "progress"
} else {
    $lines += "**XAVIER BLOCKED:** repos root '$ReposRoot' not found."
    $state = "blocked"
}

# Optional Claude summarization — loop must not depend on it
if ($state -eq "progress" -and (Get-Command claude -ErrorAction SilentlyContinue)) {
    try {
        $summary = ($lines -join "`n") | claude -p "Summarize this morning brief in 5 bullets, most actionable first. Output only the bullets." 2>$null
        if ($summary) { $lines = @($lines[0], "", "## Top 5", $summary, "") + $lines[1..($lines.Count-1)] }
    } catch { }
}

Set-Content -Path $OutFile -Value ($lines -join "`n") -Encoding UTF8
$gate = if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { "pass(file $((Get-Item $OutFile).Length)B, $scanned repos)" } else { "fail"; $state = "blocked" }
Add-Content $LogFile "WAKE ${stamp}: picked=brief did=wrote $OutFile gate=$gate next=$((Get-Date).AddDays(1).ToString('yyyy-MM-ddT08:00')) state=$state"
```

---

## REPAIR XAVIER (on the Windows machine, after files are committed)

```powershell
schtasks /query /tn XAVIER /v /fo LIST   # diagnose: does the old task exist, what does it point at?
```

```powershell
.\bin\morning-briefing.ps1               # run once manually — brief must appear on Desktop
```

```powershell
.\bin\morning-briefing.ps1 -Register     # re-register cleanly (overwrites the dead task)
Start-ScheduledTask -TaskName "XAVIER"   # fire it through the scheduler path too
Get-Content $env:TEMP\xavier.log -Tail 2 # both runs must show state=progress
```

Next-morning check (closes PROGRESS.md item 22):
```powershell
Get-ScheduledTaskInfo -TaskName "XAVIER" | Select LastRunTime, LastTaskResult, NextRunTime
```

## VERIFY & SHIP
```bash
mkdir -p loops/queue/overnight loops/queue/done && touch loops/queue/overnight/.keep loops/queue/done/.keep
bash bin/skill-doctor.sh
```
**Done bar:** 5 files + queue dirs committed · manual run produced a real brief ·
`xavier.log` shows two `state=progress` WAKE lines (manual + scheduler) ·
next morning `LastTaskResult` = 0 → tick PROGRESS.md item 22 in the same PR's
follow-up commit. Report the log lines, then STOP.

**Scope record:** no webhook/GitHub-Action infra invented (upgrade paths noted
inline) · overnight *executor* scheduling deliberately NOT auto-registered —
designing a loop does not authorize enabling its schedule; the brief (XAVIER)
is the only task registered because repairing it was explicitly queued.
