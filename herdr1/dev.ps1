# Herdr1 TESTE: detecta mudanca no codigo -> compila -> abre o Herdr1 isolado (.sandbox).
# Uso:  dev.ps1          (vigia o codigo; a cada alteracao recompila e reabre)
#       dev.ps1 -Once    (compila e abre uma vez)
#       dev.ps1 -Fast    (build debug, mais rapido que release)
param([switch]$Once, [switch]$Fast)
. (Join-Path $PSScriptRoot 'common.ps1')

$buildProfile = if ($Fast) { 'debug' } else { 'release' }
$exe = Join-Path $Herdr1Repo "target\$buildProfile\herdr.exe"
Assert-Zig
New-Item -ItemType Directory -Force "$Herdr1Sandbox\config", "$Herdr1Sandbox\state" | Out-Null

function Stop-SandboxHerdr {
    # Fecha SO o herdr.exe compilado aqui. Herdr original e HERDR2 nunca sao tocados.
    Get-Process herdr -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq $exe } |
        ForEach-Object { try { $_.Kill(); $_.WaitForExit(3000) | Out-Null } catch {} }
}

function Get-SourceStamp {
    $files = @(Get-ChildItem (Join-Path $Herdr1Repo 'src'), (Join-Path $Herdr1Repo 'crates') -Recurse -File -Include *.rs, *.toml -ErrorAction SilentlyContinue)
    $files += Get-Item (Join-Path $Herdr1Repo 'Cargo.toml'), (Join-Path $Herdr1Repo 'build.rs') -ErrorAction SilentlyContinue
    ($files | Measure-Object LastWriteTimeUtc -Maximum).Maximum
}

function Invoke-DevBuild {
    Stop-SandboxHerdr
    Remove-Item Env:HERDR1_BUILD -ErrorAction SilentlyContinue
    $cargoArgs = @('build'); if (-not $Fast) { $cargoArgs += '--release' }
    Write-Host "[dev] compilando ($buildProfile)..." -ForegroundColor Cyan
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $ok = Invoke-Cargo $cargoArgs
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("[dev] build {0} em {1:N0}s" -f $(if ($ok) { 'OK' } else { 'FALHOU' }), $sw.Elapsed.TotalSeconds) -ForegroundColor $color
    return $ok
}

function Start-SandboxHerdr {
    # Janela nova, ambiente isolado. Limpa HERDR_* herdado (senao: "nested herdr is disabled").
    $cmd = @"
Get-ChildItem Env:HERDR_* | ForEach-Object { Remove-Item "Env:`$(`$_.Name)" }
`$env:XDG_CONFIG_HOME='$Herdr1Sandbox\config'
`$env:XDG_STATE_HOME='$Herdr1Sandbox\state'
`$env:HERDR_SOCKET_PATH='$Herdr1Sandbox\herdr.sock'
`$env:HERDR_CLIENT_SOCKET_PATH='$Herdr1Sandbox\herdr-client.sock'
`$Host.UI.RawUI.WindowTitle='HERDR1 TESTE (isolado)'
& '$exe'
Write-Host "[herdr1 saiu com codigo `$LASTEXITCODE]" -ForegroundColor Yellow
"@
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    Start-Process powershell -ArgumentList '-NoLogo', '-NoExit', '-EncodedCommand', $enc | Out-Null
    Write-Host "[dev] Herdr1 TESTE aberto em janela isolada." -ForegroundColor Green
}

$last = Get-SourceStamp
if (Invoke-DevBuild) { Start-SandboxHerdr }
if ($Once) { return }

Write-Host "[dev] vigiando alteracoes em herdr-src (Ctrl+C para sair)..." -ForegroundColor Yellow
while ($true) {
    Start-Sleep -Milliseconds 1000
    if ((Get-SourceStamp) -ne $last) {
        Start-Sleep -Milliseconds 1500   # debounce: espera o editor terminar de salvar
        $last = Get-SourceStamp
        if (Invoke-DevBuild) { Start-SandboxHerdr }
    }
}
