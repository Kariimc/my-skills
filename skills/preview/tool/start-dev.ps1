# start-dev.ps1 - start a project's dev server on a free port, hidden, and wait
# for it to actually answer. Prints a machine-readable result block.
#
#   PREVIEW_URL=http://localhost:5173
#   PREVIEW_PID=12345
#   PREVIEW_LOG=C:\proj\.preview\dev-server.log
#
# On failure it prints PREVIEW_FAILED plus the server's own stderr and exits 1.
# No visible console window is ever created.
[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [int]$TimeoutSeconds = 45
)
$ErrorActionPreference = 'Stop'

function Fail($msg) { Write-Output "PREVIEW_FAILED $msg"; exit 1 }

$pkgPath = Join-Path $ProjectRoot 'package.json'
if (-not (Test-Path $pkgPath)) { Fail "no package.json at $ProjectRoot" }
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json

# --- 1. pick the dev command: "dev" first, then "start" ---------------------
$scriptName = $null
if ($pkg.scripts) {
    $names = $pkg.scripts.PSObject.Properties.Name
    if ($names -contains 'dev')        { $scriptName = 'dev' }
    elseif ($names -contains 'start')  { $scriptName = 'start' }
}
if (-not $scriptName) { Fail "package.json has neither a 'dev' nor a 'start' script" }
Write-Output "PREVIEW_SCRIPT=$scriptName ($($pkg.scripts.$scriptName))"

# --- 2. pick a free port ----------------------------------------------------
function Test-PortFree([int]$p) {
    $l = $null
    try { $l = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $p); $l.Start(); return $true }
    catch { return $false } finally { if ($l) { $l.Stop() } }
}
$port = 0
foreach ($c in 5173..5250) { if (Test-PortFree $c) { $port = $c; break } }
if ($port -eq 0) { Fail "no free port in 5173-5250" }

$previewDir = Join-Path $ProjectRoot '.preview'
New-Item -ItemType Directory -Force $previewDir | Out-Null
$outLog = Join-Path $previewDir 'dev-server.log'
$errLog = Join-Path $previewDir 'dev-server.err.log'
Remove-Item $outLog, $errLog -ErrorAction SilentlyContinue

# --- 3. detect the package manager actually used by this project ------------
$pm = 'npm'
if     (Test-Path (Join-Path $ProjectRoot 'pnpm-lock.yaml')) { $pm = 'pnpm' }
elseif (Test-Path (Join-Path $ProjectRoot 'yarn.lock'))      { $pm = 'yarn' }
elseif (Test-Path (Join-Path $ProjectRoot 'bun.lockb'))      { $pm = 'bun'  }
$pmExe = (Get-Command "$pm.cmd" -ErrorAction SilentlyContinue).Source
if (-not $pmExe) { $pmExe = (Get-Command $pm -ErrorAction SilentlyContinue).Source }
if (-not $pmExe) { Fail "package manager '$pm' is not on PATH" }

# PORT covers most Node servers; --port covers vite/next/astro style CLIs.
$env:PORT = "$port"
$env:BROWSER = 'none'          # stop the dev server opening a real browser
$argList = @('run', $scriptName, '--', '--port', "$port")

# -WindowStyle Hidden + redirected streams => no console window ever appears.
$proc = Start-Process -FilePath $pmExe -ArgumentList $argList `
        -WorkingDirectory $ProjectRoot -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $outLog -RedirectStandardError $errLog

# --- 4. poll until it answers, or give up -----------------------------------
$url = "http://localhost:$port"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$ready = $false
while ((Get-Date) -lt $deadline) {
    if ($proc.HasExited) { break }
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { $ready = $true; break }
    } catch {
        # A refused connection means "not up yet"; anything else that produced an
        # HTTP status means the server IS answering, which is all we need.
        if ($_.Exception.Response) { $ready = $true; break }
    }
    Start-Sleep -Milliseconds 700
}

if (-not $ready) {
    Write-Output "PREVIEW_FAILED dev server did not answer $url within $TimeoutSeconds seconds"
    Write-Output "--- dev server stderr ---"
    if (Test-Path $errLog) { Get-Content $errLog -Tail 60 } else { Write-Output "(empty)" }
    Write-Output "--- dev server stdout ---"
    if (Test-Path $outLog) { Get-Content $outLog -Tail 30 } else { Write-Output "(empty)" }
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    exit 1
}

Write-Output "PREVIEW_URL=$url"
Write-Output "PREVIEW_PID=$($proc.Id)"
Write-Output "PREVIEW_LOG=$outLog"
Write-Output "PREVIEW_ERRLOG=$errLog"
Write-Output "PREVIEW_DIR=$previewDir"
exit 0
