# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
param([Parameter(Mandatory)][string]$Archive)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$Archive = (Resolve-Path $Archive).Path
if ((Read-Host "Sovrascrivere TUTTI i dati correnti con $Archive ? (si/no)") -ne 'si') { return }
Stop-PolyLab
Invoke-InDistro @('true')   # riavvia la distro per accedere al filesystem
Copy-Item $Archive "\\wsl.localhost\$Distro\tmp\restore.tar.gz"
Invoke-InDistro @('sh', '-c', 'rm -rf /data/* && tar xzf /tmp/restore.tar.gz -C /data && chown -R 500:500 /data && rm /tmp/restore.tar.gz')
wsl.exe --terminate $Distro
Start-PolyLab
