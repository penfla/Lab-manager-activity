# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
$script:Distro = 'PolyLabLIMS'
$script:Port   = 8080
$script:Url    = "http://localhost:$script:Port"

function Test-Wsl {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
    wsl.exe --status *> $null
    return ($LASTEXITCODE -eq 0)
}
function Test-Installed { ((wsl.exe -l -q) -replace "`0", '') -contains $script:Distro }
function Invoke-InDistro { param([string[]]$Cmd) wsl.exe -d $script:Distro -u root --exec @Cmd }
function Wait-Ready {
    param([int]$TimeoutSec = 240)
    $end = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $end) {
        try { Invoke-WebRequest -Uri $script:Url -UseBasicParsing -TimeoutSec 3 | Out-Null; return $true } catch { Start-Sleep 3 }
    }
    return $false
}
function Start-PolyLab {
    if (-not (Test-NetConnection localhost -Port $script:Port -InformationLevel Quiet -WarningAction SilentlyContinue)) {
        Start-Process wsl.exe -WindowStyle Hidden -ArgumentList @('-d', $script:Distro, '-u', 'root', '--exec', '/opt/polylab/run.sh')
    }
}
function Stop-PolyLab {
    Invoke-InDistro @('pkill', '-TERM', '-f', 'zope.conf') 2>$null
    Start-Sleep 10
    wsl.exe --terminate $script:Distro 2>$null
}
