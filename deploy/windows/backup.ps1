# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
<#
 Backup a freddo del volume dati (Data.fs + blobstorage): arresta ~1 min i servizi, archivia, riavvia.
 Destinazione = BACKUP_DIR da .env: cartella locale, share UNC LAN o cartella OneDrive/SharePoint sincronizzata.
#>
$ErrorActionPreference = 'Stop'
$deploy = Split-Path -Parent $PSScriptRoot
Set-Location $deploy
$cfg = @{}
Get-Content .env | Where-Object { $_ -match '^\s*[A-Z_]+=' } | ForEach-Object { $k,$v = $_ -split '=',2; $cfg[$k.Trim()] = $v.Trim() }
$dest = $cfg['BACKUP_DIR']; $keep = if ($cfg['BACKUP_KEEP']) { [int]$cfg['BACKUP_KEEP'] } else { 14 }
if (-not $dest) { throw "BACKUP_DIR non impostato in .env" }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$name = "senaite-$(Get-Date -Format 'yyyyMMdd-HHmmss').tar.gz"
$project = (docker compose config --format json | ConvertFrom-Json).name
$tmp = Join-Path $env:TEMP 'senaite-backup'; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
docker compose stop instance instance2 zeo
try {
    docker run --rm -v "${project}_senaite_data:/data:ro" -v "${tmp}:/out" alpine tar czf "/out/$name" -C /data .
    if ($LASTEXITCODE -ne 0) { throw "tar fallito" }
    Copy-Item (Join-Path $tmp $name) $dest
} finally {
    docker compose start zeo instance
    Remove-Item (Join-Path $tmp $name) -ErrorAction SilentlyContinue
}
Get-ChildItem $dest -Filter 'senaite-*.tar.gz' | Sort-Object LastWriteTime -Descending | Select-Object -Skip $keep | Remove-Item
Write-Host "Backup: $(Join-Path $dest $name)"
