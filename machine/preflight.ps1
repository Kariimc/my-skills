<#
    preflight.ps1 - what this machine can and cannot do, proven not remembered.

        preflight.ps1 doctor    report the state of everything; change nothing
        preflight.ps1 install   install anything missing from the baseline
        preflight.ps1 ledger    per kind of work: installed / missing / blocked
                                behind an account rather than an install

    Every run writes a snapshot to %USERPROFILE%\.claude\stack-state.json so a
    future session reads the environment instead of probing for it.

    Unity / Unreal / Blender: detected only. If present, its MCP server is
    registered for Claude Code at user scope and verified. If absent, one line
    says so and the script moves on. Nothing multi-gigabyte is ever installed.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('doctor', 'install', 'ledger')]
    [string]$Mode = 'doctor'
)

$ErrorActionPreference = 'Continue'
$SkillsRepo  = 'C:\Users\Kariim\Dev\my-skills'
$StatePath   = "$env:USERPROFILE\.claude\stack-state.json"

# A shell started before a tool was installed carries a stale PATH and would
# report a present tool as MISSING. Read PATH fresh from the registry first, so
# doctor never reports a false negative.
$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' +
            [Environment]::GetEnvironmentVariable('PATH','User')

function Head($t) { Write-Host ""; Write-Host "=== $t ===" }
function Line($k, $v) { Write-Host ("  {0,-24} {1}" -f $k, $v) }

# ── probes ──────────────────────────────────────────────────────────────────
function Get-ToolVersion([string]$exe, [string]$argline) {
    $c = Get-Command $exe -ErrorAction SilentlyContinue
    if (-not $c) { return $null }
    try {
        $v = (& $exe $argline.Split(' ') 2>&1 | Select-Object -First 1)
        if (-not $v) { $v = 'present' }
        return [string]$v
    } catch { return 'present' }
}

function Find-App([string[]]$globs) {
    foreach ($g in $globs) {
        $hit = Get-Item $g -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

# ── the Step 2 baseline ─────────────────────────────────────────────────────
$Baseline = @(
    @{ name = 'git';     exe = 'git';     arg = '--version'; winget = 'Git.Git' }
    @{ name = 'gh';      exe = 'gh';      arg = '--version'; winget = 'GitHub.cli' }
    @{ name = 'ripgrep'; exe = 'rg';      arg = '--version'; winget = 'BurntSushi.ripgrep.MSVC' }
    @{ name = 'jq';      exe = 'jq';      arg = '--version'; winget = 'jqlang.jq' }
    @{ name = 'fd';      exe = 'fd';      arg = '--version'; winget = 'sharkdp.fd' }
    # 7-Zip installs to Program Files and adds no PATH entry, so `7z` alone is
    # not proof of absence - fallback tells doctor and install the same truth.
    @{ name = '7zip';    exe = '7z';      arg = '';          winget = '7zip.7zip'
       fallback = @("$env:ProgramFiles\7-Zip\7z.exe") }
    @{ name = 'node';    exe = 'node';    arg = '--version'; winget = 'OpenJS.NodeJS.LTS' }
    @{ name = 'python';  exe = 'python';  arg = '--version'; winget = 'Python.Python.3.12' }
    @{ name = 'uv';      exe = 'uv';      arg = '--version'; winget = 'astral-sh.uv' }
    @{ name = 'cmake';   exe = 'cmake';   arg = '--version'; winget = 'Kitware.CMake' }
    @{ name = 'pnpm';    exe = 'pnpm';    arg = '--version'; npm = 'pnpm' }
    @{ name = 'turbo';   exe = 'turbo';   arg = '--version'; npm = 'turbo' }
    @{ name = 'vercel';  exe = 'vercel';  arg = '--version'; npm = 'vercel' }
)

# The single source of truth for "is this tool here?" - used by doctor AND
# install, so they can never disagree.
function Resolve-Tool($t) {
    $v = Get-ToolVersion $t.exe $t.arg
    if ($v) { return $v }
    if ($t.fallback) {
        $p = Find-App $t.fallback
        if ($p) { return "present at $p (not on PATH)" }
    }
    return $null
}

function Get-BaselineState {
    $r = [ordered]@{}
    foreach ($t in $Baseline) { $r[$t.name] = Resolve-Tool $t }
    return $r
}

# ── creative applications: detect only, never install ───────────────────────
function Get-CreativeApps {
    $unity = Find-App @(
        "$env:ProgramFiles\Unity\Hub\Editor\*\Editor\Unity.exe",
        "$env:ProgramFiles\Unity\Editor\Unity.exe",
        "C:\Program Files\Unity Hub\Unity Hub.exe"
    )
    # The engine binary only. The Epic Games Launcher being present does NOT
    # mean Unreal is installed - that mistake made this script claim an engine
    # that was not there.
    $unreal = Find-App @(
        "$env:ProgramFiles\Epic Games\UE_*\Engine\Binaries\Win64\UnrealEditor.exe",
        "$env:ProgramFiles\Epic Games\UE_*\Engine\Binaries\Win64\UE4Editor.exe"
    )
    $blender = Find-App @(
        "$env:ProgramFiles\Blender Foundation\Blender *\blender.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\BlenderFoundation.Blender*\blender.exe"
    )
    return [ordered]@{ unity = $unity; unreal = $unreal; blender = $blender }
}

# MCP server definitions, used ONLY when the matching app is actually present.
# No entry for unreal: there is no published `unreal-mcp` package on PyPI
# (verified 2026-07-27 - uvx resolves to "not found in the package registry").
# Registering a server that cannot start is worse than none, so it is omitted
# until a real one exists.
$CreativeMcp = @{
    blender = @{ server = 'blender'; cmd = 'uvx';  args = @('blender-mcp') }
    unity   = @{ server = 'unity';   cmd = 'uvx';  args = @('unity-mcp-server') }
}

function Register-CreativeMcp($apps) {
    Head "Creative app MCP servers (detect - register - verify)"
    foreach ($k in @('unity', 'unreal', 'blender')) {
        $path = $apps[$k]
        if (-not $path) {
            Line $k "ABSENT on this machine - not installing (multi-GB app)"
            continue
        }
        Line $k "present: $path"
        $d = $CreativeMcp[$k]
        if (-not $d) {
            Line "  mcp" "no known-good MCP server package for $k - none registered"
            continue
        }
        $existing = (claude mcp list 2>&1 | Out-String)
        if ($existing -match ("(?m)^" + [regex]::Escape($d.server) + ":")) {
            Line "  mcp" "already registered - leaving it alone"
            continue
        }
        if (-not (Get-Command $d.cmd -ErrorAction SilentlyContinue)) {
            Line "  mcp" "cannot register: '$($d.cmd)' is not on PATH"
            continue
        }
        & claude mcp add --scope user $d.server -- $d.cmd @($d.args)
        Start-Sleep -Milliseconds 500
        $check = (claude mcp list 2>&1 | Out-String)
        $ok = $check -match ("(?m)^" + [regex]::Escape($d.server) + ":.*Connected")
        if ($ok) {
            Line "  mcp" "registered and CONNECTED"
        } else {
            # Never leave a dead server behind: roll the registration back and
            # say so plainly rather than reporting a capability that is not real.
            & claude mcp remove $d.server --scope user 2>&1 | Out-Null
            Line "  mcp" "FAILED to connect ($($d.cmd) $($d.args -join ' ')) - registration rolled back"
        }
    }
}

# ── the ledger: per kind of work ────────────────────────────────────────────
function Show-Ledger($base, $apps) {
    $node   = [bool]$base['node']
    $py     = [bool]$base['python']
    $andSdk = Test-Path "$env:LOCALAPPDATA\Android\Sdk"
    $jdk    = [bool](Get-Command java -ErrorAction SilentlyContinue)
    $cmake  = [bool]$base['cmake']
    $arm    = [bool](Get-Command arm-none-eabi-gcc -ErrorAction SilentlyContinue)
    $plat   = [bool](Get-Command platformio -ErrorAction SilentlyContinue)
    $pwCache= Test-Path "$env:LOCALAPPDATA\ms-playwright"
    $bpy    = $false
    if ($py) { python -c "import bpy" 2>$null; $bpy = ($LASTEXITCODE -eq 0) }

    $rows = @(
        @{ kind='web';      installed=@("node $($base['node'])","pnpm $($base['pnpm'])","turbo $($base['turbo'])","vercel CLI $($base['vercel'])", $(if($pwCache){"Playwright chromium (local)"}else{$null}));
           missing=@(); account=@('Vercel - deploys need a logged-in account (vercel login)') }
        @{ kind='Android';  installed=@($(if($jdk){"java"}else{$null}), $(if($andSdk){"Android SDK"}else{$null}));
           missing=@($(if(-not $andSdk){'Android SDK / Android Studio'}else{$null}), $(if(-not $jdk){'JDK'}else{$null}));
           account=@('Google Play Console - publishing needs a paid developer account') }
        @{ kind='Electron'; installed=@($(if($node){"node $($base['node'])"}else{$null}),"npm/pnpm");
           missing=@('electron (per-project dependency, not global)');
           account=@('Code-signing certificate - shipping a signed build needs a purchased cert') }
        @{ kind='Python';   installed=@("python $($base['python'])","uv $($base['uv'])");
           missing=@($(if(Get-Command ruff -ErrorAction SilentlyContinue){$null}else{'ruff'}), $(if(Get-Command pytest -ErrorAction SilentlyContinue){$null}else{'pytest'}));
           account=@('PyPI - publishing a package needs an account + API token') }
        @{ kind='embedded'; installed=@($(if($cmake){"cmake $($base['cmake'])"}else{$null}));
           missing=@($(if(-not $arm){'arm-none-eabi-gcc toolchain'}else{$null}), $(if(-not $plat){'PlatformIO'}else{$null}));
           account=@() }
        @{ kind='Unreal';   installed=@($(if($apps.unreal){"Unreal Engine: $($apps.unreal)"}else{$null}));
           missing=@($(if(-not $apps.unreal){'Unreal Engine (not installed - multi-GB, install by hand)'}else{$null}));
           account=@('Epic Games account - required to download the engine at all') }
        @{ kind='Unity';    installed=@($(if($apps.unity){"Unity: $($apps.unity)"}else{$null}));
           missing=@($(if(-not $apps.unity){'Unity Hub + Editor (not installed - multi-GB, install by hand)'}else{$null}));
           account=@('Unity account + licence - the Editor will not open without one') }
        @{ kind='3D';       installed=@($(if($apps.blender){"Blender: $($apps.blender)"}else{$null}), $(if($bpy){'bpy python module'}else{$null}));
           missing=@($(if(-not $apps.blender){'Blender application'}else{$null}), $(if(-not $bpy){'bpy python module (pip install bpy)'}else{$null}));
           account=@() }
    )

    Head "LEDGER - what each kind of work can actually do here"
    foreach ($r in $rows) {
        $inst = @($r.installed | Where-Object { $_ })
        $miss = @($r.missing   | Where-Object { $_ })
        $acct = @($r.account   | Where-Object { $_ })
        Write-Host ""
        Write-Host ("  " + $r.kind.ToUpper())
        if ($inst) { foreach ($i in $inst) { Write-Host "     installed : $i" } } else { Write-Host "     installed : (nothing)" }
        if ($miss) { foreach ($i in $miss) { Write-Host "     MISSING   : $i" } } else { Write-Host "     MISSING   : (nothing)" }
        if ($acct) { foreach ($i in $acct) { Write-Host "     ACCOUNT   : $i" } } else { Write-Host "     ACCOUNT   : (nothing blocked behind an account)" }
    }
    return $rows
}

# ── control-plane checks (the rest of the machine setup) ────────────────────
function Get-ControlPlane {
    $settings = "$env:USERPROFILE\.claude\settings.json"
    $s = $null
    if (Test-Path $settings) { try { $s = [IO.File]::ReadAllText($settings) | ConvertFrom-Json } catch {} }
    $stopHooks = @()
    if ($s) { foreach ($g in @($s.hooks.Stop)) { foreach ($h in @($g.hooks)) { $stopHooks += $h.command } } }
    $mcp = (claude mcp list 2>&1 | Out-String)
    return [ordered]@{
        skillsRepo          = $(if (Test-Path $SkillsRepo) { $SkillsRepo } else { $null })
        additionalDirs      = @($s.permissions.additionalDirectories)
        allowRules          = @($s.permissions.allow).Count
        verifyGateRegistered= [bool](@($stopHooks) -match 'verify-gate')
        skillsGlobal        = @(Get-ChildItem "$env:USERPROFILE\.claude\skills" -Filter SKILL.md -Recurse -File -EA SilentlyContinue).Count
        agentsGlobal        = @(Get-ChildItem "$env:USERPROFILE\.claude\agents" -Filter *.md -File -EA SilentlyContinue).Count
        previewSkill        = Test-Path "$env:USERPROFILE\.claude\skills\preview\SKILL.md"
        intentLockSkill     = Test-Path "$env:USERPROFILE\.claude\skills\intent-lock\SKILL.md"
        verifierAgent       = Test-Path "$env:USERPROFILE\.claude\agents\verifier.md"
        skCommand           = Test-Path "$env:USERPROFILE\bin\sk.cmd"
        playwrightMcp       = [bool]($mcp -match '(?m)^playwright:.*Connected')
        chromeDevtoolsMcp   = [bool]($mcp -match '(?m)^chrome-devtools:.*Connected')
        longPaths           = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -EA SilentlyContinue).LongPathsEnabled
        userPathLength      = ([Environment]::GetEnvironmentVariable('PATH','User')).Length
    }
}

# ── install mode ────────────────────────────────────────────────────────────
function Invoke-Install {
    Head "INSTALL - filling gaps in the baseline (idempotent)"
    $any = $false
    foreach ($t in $Baseline) {
        $v = Resolve-Tool $t
        if ($v) { Line $t.name "present - skipping" ; continue }
        $any = $true
        if ($t.winget) {
            Line $t.name "missing -> winget install $($t.winget)"
            winget install --id $t.winget -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
            Line $t.name "winget exit $LASTEXITCODE"
        } elseif ($t.npm) {
            Line $t.name "missing -> npm install -g $($t.npm)"
            npm install -g $t.npm --no-fund --no-audit | Out-Null
            Line $t.name "npm exit $LASTEXITCODE"
        }
    }
    if (-not $any) { Line "result" "nothing was missing" }
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')
}

# ── main ────────────────────────────────────────────────────────────────────
Write-Host ("preflight.ps1  mode=$Mode  " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

if ($Mode -eq 'install') { Invoke-Install }

$base = Get-BaselineState
$apps = Get-CreativeApps
$cp   = Get-ControlPlane

if ($Mode -eq 'doctor' -or $Mode -eq 'install') {
    Head "BASELINE TOOLS"
    foreach ($k in $base.Keys) {
        if ($base[$k]) { Line $k $base[$k] } else { Line $k "MISSING  (preflight.ps1 install)" }
    }

    Head "CONTROL PLANE"
    Line "my-skills repo"        $(if ($cp.skillsRepo) { $cp.skillsRepo } else { 'NOT FOUND' })
    Line "additionalDirectories" $(if ($cp.additionalDirs) { $cp.additionalDirs -join ', ' } else { 'none' })
    Line "permission allow rules" $cp.allowRules
    Line "skills live globally"  $cp.skillsGlobal
    Line "agents live globally"  $cp.agentsGlobal
    Line "preview skill"         $(if ($cp.previewSkill)    { 'live' } else { 'MISSING' })
    Line "intent-lock skill"     $(if ($cp.intentLockSkill) { 'live' } else { 'MISSING' })
    Line "verifier agent"        $(if ($cp.verifierAgent)   { 'live' } else { 'MISSING' })
    Line "sk command"            $(if ($cp.skCommand)       { 'live' } else { 'MISSING' })
    Line "verify Stop gate"      $(if ($cp.verifyGateRegistered) { 'registered' } else { 'NOT REGISTERED' })
    Line "playwright MCP"        $(if ($cp.playwrightMcp)     { 'connected' } else { 'not connected' })
    Line "chrome-devtools MCP"   $(if ($cp.chromeDevtoolsMcp) { 'connected' } else { 'not connected' })
    Line "LongPathsEnabled"      $cp.longPaths
    Line "user PATH length"      ("$($cp.userPathLength) / 2047" + $(if ($cp.userPathLength -gt 1800) { '  <-- getting full' } else { '' }))

    Register-CreativeMcp $apps
}

$ledger = $null
if ($Mode -eq 'ledger') { $ledger = Show-Ledger $base $apps }

# ── snapshot, every run ─────────────────────────────────────────────────────
$snapshot = [ordered]@{
    writtenUtc   = (Get-Date).ToUniversalTime().ToString('o')
    mode         = $Mode
    machine      = $env:COMPUTERNAME
    baseline     = $base
    creativeApps = $apps
    controlPlane = $cp
}
[IO.File]::WriteAllText($StatePath, ($snapshot | ConvertTo-Json -Depth 12), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "snapshot written: $StatePath"

# A failed probe (e.g. `import bpy` returning 1) must not become this script's
# exit code. Reporting is the job; a report always succeeds.
exit 0
