# morning-briefing.ps1 - XAVIER's target. Composes the daily brief. See loops/overnight-brief.md.
#
# Setup (run once, normal user PowerShell):
#   .\bin\morning-briefing.ps1 -Register    # (re)installs the XAVIER task, daily 08:00
# Manual run:
#   .\bin\morning-briefing.ps1
# Log: $env:TEMP\xavier.log

param([switch]$Register)

$RepoRoot  = Split-Path $PSScriptRoot -Parent
$ReposRoot = "C:\Users\Kariim\Dev"          # parent dir of repo clones (this machine; house rule: never C:\Dev)
$OutFile   = Join-Path ([Environment]::GetFolderPath("Desktop")) ("morning-brief-{0:yyyy-MM-dd}.md" -f (Get-Date))
$LogFile   = "$env:TEMP\xavier.log"

if ($Register) {
    # This machine ships Windows PowerShell 5.1 (powershell.exe), not pwsh 7 - register with the interpreter that exists.
    # -ExecutionPolicy Bypass: Task Scheduler starts a clean powershell.exe whose effective
    # policy is Restricted (all scopes Undefined on this machine) and would refuse to run a
    # .ps1; Bypass lets the scheduled run execute this local, trusted script.
    $action   = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $trigger  = New-ScheduledTaskTrigger -Daily -At 8:00am
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
    Register-ScheduledTask -TaskName "XAVIER" -Action $action -Trigger $trigger `
        -Settings $settings -Description "my-skills morning briefing (loops/overnight-brief.md)" -Force
    Write-Host "XAVIER registered: daily 08:00 -> $PSCommandPath"
    Write-Host "Run now to test:  Start-ScheduledTask -TaskName 'XAVIER'"
    exit 0
}

$stamp = Get-Date -Format s
$lines = @("# Morning brief - $(Get-Date -Format 'ddd yyyy-MM-dd')", "")
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

# Optional Claude summarization - loop must not depend on it
if ($state -eq "progress" -and (Get-Command claude -ErrorAction SilentlyContinue)) {
    try {
        $summary = ($lines -join "`n") | claude -p "Summarize this morning brief in 5 bullets, most actionable first. Output only the bullets." 2>$null
        if ($summary) { $lines = @($lines[0], "", "## Top 5", $summary, "") + $lines[1..($lines.Count-1)] }
    } catch { }
}

Set-Content -Path $OutFile -Value ($lines -join "`n") -Encoding UTF8
$gate = if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { "pass(file $((Get-Item $OutFile).Length)B, $scanned repos)" } else { "fail"; $state = "blocked" }
Add-Content $LogFile "WAKE ${stamp}: picked=brief did=wrote $OutFile gate=$gate next=$((Get-Date).AddDays(1).ToString('yyyy-MM-ddT08:00')) state=$state"
