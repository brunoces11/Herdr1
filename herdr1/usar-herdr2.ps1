# Faz o comando `herdr` do sistema apontar para WCONFIG\HERDR2\current (PATH do usuario).
# Reversivel com usar-original.ps1. Vale para terminais abertos DEPOIS da troca.
. (Join-Path $PSScriptRoot 'common.ps1')

if (-not (Test-Path (Join-Path $Herdr2Current 'herdr.exe'))) { throw "HERDR2 vazio. Rode deploy.ps1 primeiro." }

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$entries = @($userPath -split ';' | Where-Object { $_ })
$original = $entries | Where-Object { $_ -match '\\\.herdr\\packages\\standalone\\' }

New-Item -ItemType Directory -Force $Herdr2Root | Out-Null
Set-Content (Join-Path $Herdr2Root ("path-backup-{0}.txt" -f (Get-Date -Format 'yyyyMMddHHmmss'))) $userPath -Encoding utf8
if ($original) { Set-Content (Join-Path $Herdr2Root 'original-path.txt') ($original -join ';') -Encoding utf8 }

$kept = $entries | Where-Object { $_ -notmatch '\\\.herdr\\packages\\standalone\\' -and $_ -ne $Herdr2Current }
[Environment]::SetEnvironmentVariable('Path', (@($Herdr2Current) + $kept) -join ';', 'User')

Write-Host "[path] 'herdr' agora aponta para $Herdr2Current" -ForegroundColor Green
Write-Host "[path] Herdr original preservado em: $($original -join ', ')" -ForegroundColor DarkGray
Write-Host "[path] Abra um terminal novo para valer. Voltar: usar-original.ps1" -ForegroundColor Yellow
