# DEPLOY do Herdr1 -> HERDR2 (ambiente de trabalho).
# Compila o commit atual em release e publica em WCONFIG\HERDR2\current\herdr.exe.
# Exige codigo commitado, para que todo executavel publicado seja rastreavel a um commit.
# Uso: deploy.ps1            (padrao: exige arvore limpa)
#      deploy.ps1 -Keep 8    (quantas versoes antigas manter em HERDR2\releases; padrao 5)
param([int]$Keep = 5)
. (Join-Path $PSScriptRoot 'common.ps1')

function Step($msg) { Write-Host "[deploy] $msg" -ForegroundColor Cyan }

# 1. Codigo commitado?
Push-Location $Herdr1Repo
try {
    $dirty = git status --porcelain
    if ($dirty) { throw "Ha alteracoes nao commitadas em herdr-src. Faca commit antes do deploy:`n$($dirty -join "`n")" }
    $sha = (git rev-parse --short HEAD).Trim()
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    git fetch -q origin 2>$null
    $ahead = (git rev-list --count "origin/$branch..HEAD" 2>$null)
    if ($ahead -and [int]$ahead -gt 0) { Write-Host "[deploy] aviso: $ahead commit(s) ainda nao enviados ao GitHub (git push)." -ForegroundColor Yellow }
} finally { Pop-Location }

$build = "{0}-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmm'), $sha
Step "build $build (branch $branch)"

# 2. Compila release marcado com HERDR1_BUILD
Assert-Zig
$env:HERDR1_BUILD = $build
$sw = [Diagnostics.Stopwatch]::StartNew()
$ok = Invoke-Cargo @('build', '--release', '--locked')
Remove-Item Env:HERDR1_BUILD -ErrorAction SilentlyContinue
if (-not $ok) { throw "Compilacao falhou. Nada foi publicado; HERDR2 continua como estava." }
Step ("compilado em {0:N0}s" -f $sw.Elapsed.TotalSeconds)

$built = Join-Path $Herdr1Repo 'target\release\herdr.exe'
$reported = (& $built --version).Trim()
if ($reported -notlike "*herdr1 $build*") { throw "Executavel nao reporta a versao esperada ($build): '$reported'" }

# 3. Guarda a versao em releases\<build>
$releaseDir = Join-Path $Herdr2Root "releases\$build"
New-Item -ItemType Directory -Force $releaseDir, $Herdr2Current | Out-Null
Copy-Item $built (Join-Path $releaseDir 'herdr.exe') -Force

# 4. Publica em current. Um .exe em execucao nao pode ser sobrescrito no Windows,
#    mas pode ser renomeado: processos abertos seguem no antigo, novos usam o novo.
$currentExe = Join-Path $Herdr2Current 'herdr.exe'
if (Test-Path $currentExe) {
    Rename-Item $currentExe ("herdr.exe.old-{0}" -f (Get-Date -Format 'yyyyMMddHHmmss'))
}
Copy-Item $built $currentExe
Set-Content (Join-Path $Herdr2Current 'BUILD.txt') "$reported`r`ncommit $sha`r`nbranch $branch`r`ndeploy $(Get-Date -Format s)" -Encoding utf8
Add-Content (Join-Path $Herdr2Root 'deploy-log.txt') "$(Get-Date -Format s)  $reported" -Encoding utf8

# 5. Limpeza: .old que nao estejam em uso e releases alem de $Keep
Get-ChildItem $Herdr2Current -Filter 'herdr.exe.old-*' | ForEach-Object { try { Remove-Item $_.FullName -Force -ErrorAction Stop } catch {} }
Get-ChildItem (Join-Path $Herdr2Root 'releases') -Directory | Sort-Object Name -Descending | Select-Object -Skip $Keep |
    ForEach-Object { try { Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop } catch {} }

Write-Host "[deploy] OK: $reported publicado em $currentExe" -ForegroundColor Green
$running = Get-Process herdr -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Herdr2Current\herdr.exe.old-*" }
if ($running) {
    Write-Host "[deploy] O Herdr2 aberto continua na versao anterior ate ser reiniciado (feche o Herdr e rode 'herdr server stop', depois abra de novo)." -ForegroundColor Yellow
}
