# Caminhos e utilitarios compartilhados pelos scripts do Herdr1.
$ErrorActionPreference = 'Stop'
$Herdr1Repo    = Split-Path $PSScriptRoot -Parent                 # ...\WCONFIG\HERDR1\herdr-src
$Herdr1Root    = Split-Path $Herdr1Repo -Parent                   # ...\WCONFIG\HERDR1
$WConfigRoot   = Split-Path $Herdr1Root -Parent                   # ...\WCONFIG
$Herdr1Sandbox = Join-Path $Herdr1Root '.sandbox'
$Herdr2Root    = Join-Path $WConfigRoot 'HERDR2'
$Herdr2Current = Join-Path $Herdr2Root 'current'
$ZigPath       = Join-Path $env:LOCALAPPDATA 'zig-0.16.0\zig-x86_64-windows-0.16.0\zig.exe'

function Assert-Zig {
    if (-not (Test-Path $ZigPath)) {
        throw "Zig 0.16.0 nao encontrado em $ZigPath (o Herdr exige exatamente a 0.16.0)."
    }
    $env:ZIG = $ZigPath
}

function Invoke-Cargo([string[]]$CargoArgs) {
    # stderr do cargo (warnings) nao pode abortar o script no PowerShell 5.1
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        Push-Location $Herdr1Repo
        & cargo @CargoArgs
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
        $ErrorActionPreference = $prev
    }
}
