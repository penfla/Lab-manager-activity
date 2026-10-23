# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
# Backup a freddo di /data (Data.fs + blob). Destinazione: cartella locale, share UNC LAN o cartella OneDrive sincronizzata.
param([Parameter(Mandatory)][string]$Dest, [int]$Keep = 14)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$name = "polylab-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar.gz"
Stop-PolyLab
try {
    wsl.exe -d $Distro -u root --exec tar czf "/tmp/$name" -C /data .
    if ($LASTEXITCODE -ne 0) { throw 'tar fallito' }
    Copy-Item "\\wsl.localhost\$Distro\tmp\$name" $Dest
    Invoke-InDistro @('rm', '-f', "/tmp/$name")
} finally { Start-PolyLab }
Get-ChildItem $Dest -Filter 'polylab-*.tar.gz' | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep | Remove-Item
Write-Host "Backup: $(Join-Path $Dest $name)"
