# watch.ps1 — auto-commit + sync whenever skills/commands/agents/rules change.
#
# Setup (run once in PowerShell as your normal user):
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#   .\bin\watch.ps1 -Register    # installs a Task Scheduler job that runs at login
#
# To run manually in the foreground:
#   .\bin\watch.ps1
#
# Logs:  $env:TEMP\my-skills-watch.log

param(
    [switch]$Register   # pass -Register to install the scheduled task, then exit
)

$RepoRoot  = Split-Path $PSScriptRoot -Parent
$WatchDirs = @("skills","commands","agents","rules") | ForEach-Object { Join-Path $RepoRoot $_ }
$LogFile   = "$env:TEMP\my-skills-watch.log"
$ClaudeDir = "$env:USERPROFILE\.claude"

# ── register as a Task Scheduler job and exit ─────────────────────────────────
if ($Register) {
    $action  = New-ScheduledTaskAction `
        -Execute "pwsh.exe" `
        -Argument "-NonInteractive -WindowStyle Hidden -File `"$PSCommandPath`""
    # fall back to Windows PowerShell if pwsh (PowerShell 7) isn't installed
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        $action = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NonInteractive -WindowStyle Hidden -File `"$PSCommandPath`""
    }
    $trigger  = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask `
        -TaskName  "my-skills-watch" `
        -Action    $action `
        -Trigger   $trigger `
        -Settings  $settings `
        -RunLevel  Limited `
        -Force | Out-Null
    Write-Host "Scheduled task 'my-skills-watch' registered. It will start at next login."
    Write-Host "To start it now: Start-ScheduledTask -TaskName 'my-skills-watch'"
    exit 0
}

# ── sync + commit function ────────────────────────────────────────────────────
function Sync-AndCommit {
    Set-Location $RepoRoot

    # Stage watched dirs
    foreach ($d in @("skills","commands","agents","rules")) {
        if (Test-Path $d) { git add $d 2>$null }
    }

    # Nothing staged? bail
    $staged = git diff --cached --name-only
    if (-not $staged) { return }

    # Build commit message
    $added    = (git diff --cached --name-only --diff-filter=A | Measure-Object -Line).Lines
    $modified = (git diff --cached --name-only --diff-filter=M | Measure-Object -Line).Lines
    $deleted  = (git diff --cached --name-only --diff-filter=D | Measure-Object -Line).Lines
    $msg = "auto:"
    if ($added    -gt 0) { $msg += " $added added" }
    if ($modified -gt 0) { $msg += " $modified modified" }
    if ($deleted  -gt 0) { $msg += " $deleted deleted" }
    $msg += " [watch.ps1]"

    git commit -m $msg --no-verify 2>&1 | Out-Null
    $ts = Get-Date -Format "HH:mm:ss"
    Add-Content $LogFile "[$ts] committed: $msg"

    # Sync to ~/.claude — mirror what session-start.sh does
    $dirs = @(
        @{ src = "skills";   dst = "$ClaudeDir\skills" },
        @{ src = "commands"; dst = "$ClaudeDir\commands" },
        @{ src = "agents";   dst = "$ClaudeDir\agents" }
    )
    foreach ($pair in $dirs) {
        $src = Join-Path $RepoRoot $pair.src
        if (Test-Path $src) {
            New-Item -ItemType Directory -Force -Path $pair.dst | Out-Null
            Copy-Item "$src\*" $pair.dst -Recurse -Force
        }
    }

    # Concatenate rules/*.md -> ~/.claude/CLAUDE.md
    $rulesDir = Join-Path $RepoRoot "rules"
    if (Test-Path $rulesDir) {
        $rules = Get-ChildItem "$rulesDir\*.md" | Where-Object { $_.Name -ne "README.md" } | Sort-Object Name
        if ($rules) {
            ($rules | Get-Content -Raw) -join "`n`n" | Set-Content "$ClaudeDir\CLAUDE.md" -Encoding UTF8
        }
    }

    Add-Content $LogFile "[$ts] synced to $ClaudeDir"

    # Best-effort push
    git push origin HEAD 2>&1 | Out-Null
    Add-Content $LogFile "[$ts] pushed to origin"
}

# ── filesystem watcher ────────────────────────────────────────────────────────
$watchers = @()
foreach ($dir in $WatchDirs) {
    if (-not (Test-Path $dir)) { continue }
    $w = New-Object System.IO.FileSystemWatcher
    $w.Path                = $dir
    $w.IncludeSubdirectories = $true
    $w.NotifyFilter        = [System.IO.NotifyFilters]::FileName `
                           -bor [System.IO.NotifyFilters]::LastWrite `
                           -bor [System.IO.NotifyFilters]::DirectoryName
    $w.EnableRaisingEvents = $true
    $watchers += $w
}

$ts = Get-Date -Format "HH:mm:ss"
Add-Content $LogFile "[$ts] watching: $($WatchDirs -join ', ')"
Write-Host "Watching for changes. Log: $LogFile  |  Ctrl-C to stop."

# Debounce: coalesce rapid writes into one commit
$lastEvent = [datetime]::MinValue
$debounceMs = 2000

while ($true) {
    $changed = $false
    foreach ($w in $watchers) {
        $result = $w.WaitForChanged([System.IO.WatcherChangeTypes]::All, 500)
        if (-not $result.TimedOut) { $changed = $true }
    }

    if ($changed) {
        $lastEvent = [datetime]::UtcNow
    }

    # Fire once the debounce window has passed
    if ($lastEvent -ne [datetime]::MinValue) {
        $elapsed = ([datetime]::UtcNow - $lastEvent).TotalMilliseconds
        if ($elapsed -ge $debounceMs) {
            $lastEvent = [datetime]::MinValue
            Sync-AndCommit
        }
    }
}
