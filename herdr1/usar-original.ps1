# Volta o comando `herdr` do sistema para o Herdr original (desfaz usar-herdr2.ps1).
. (Join-Path $PSScriptRoot 'common.ps1')

$saved = Join-Path $Herdr2Root 'original-path.txt'
$original = if (Test-Path $saved) { (Get-Content $saved -Raw).Trim() } else {
    $d = Get-ChildItem "$env:USERPROFILE\.herdr\packages\standalone\releases" -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $d) { throw "Instalacao original do Herdr nao encontrada." }
    $d.FullName
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$kept = @($userPath -split ';' | Where-Object { $_ -and $_ -ne $Herdr2Current -and $_ -notmatch '\\\.herdr\\packages\\standalone\\' })
[Environment]::SetEnvironmentVariable('Path', (($original -split ';') + $kept) -join ';', 'User')

Write-Host "[path] 'herdr' voltou para o original: $original" -ForegroundColor Green
Write-Host "[path] Abra um terminal novo para valer. Ir para o Herdr2: usar-herdr2.ps1" -ForegroundColor Yellow
