# add-bin-to-path.ps1 - put %USERPROFILE%\bin on the USER PATH, exactly once.
#
# Called by install-global.sh. Not a standalone installer - it does one job that
# bash cannot do safely on Windows (setx truncates a PATH over 1024 characters
# and would silently destroy it).
#
# Idempotent: run it a hundred times and the PATH gains one entry, total.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$bin = Join-Path $env:USERPROFILE 'bin'
New-Item -ItemType Directory -Force $bin | Out-Null

$path  = [Environment]::GetEnvironmentVariable('PATH', 'User')
if (-not $path) { $path = '' }
$parts = @($path -split ';' | Where-Object { $_ })

$already = @($parts | Where-Object { $_.TrimEnd('\') -ieq $bin.TrimEnd('\') })
if ($already.Count -gt 0) {
    Write-Output "  PATH: $bin already present ($($already.Count) entry) - unchanged"
} else {
    [Environment]::SetEnvironmentVariable('PATH', (($parts + $bin) -join ';'), 'User')
    Write-Output "  PATH: added $bin"
}

$after = @(([Environment]::GetEnvironmentVariable('PATH','User') -split ';') |
           Where-Object { $_.TrimEnd('\') -ieq $bin.TrimEnd('\') })
Write-Output ("  PATH: $bin now appears $($after.Count) time(s); PATH is " +
              ([Environment]::GetEnvironmentVariable('PATH','User')).Length + " chars")
if ($after.Count -ne 1) { Write-Error "expected exactly one entry, found $($after.Count)"; exit 1 }
exit 0
