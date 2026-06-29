# run.ps1 — run the council using council.config.json (+ .env if present).
# Usage:  .\run.ps1 "Should we adopt microservices?"
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Question)
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

# load .env into the process environment, if present
$envFile = Join-Path $dir ".env"
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
      [Environment]::SetEnvironmentVariable($matches[1], $matches[2].Trim())
    }
  }
}

if (-not $Question) { Write-Host 'Usage: .\run.ps1 "your question"'; exit 1 }
python (Join-Path $dir "council.py") ($Question -join ' ') --config (Join-Path $dir "council.config.json")
