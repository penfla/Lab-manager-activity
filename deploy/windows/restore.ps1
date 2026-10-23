# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
param([Parameter(Mandatory)][string]$Archive)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$Archive = (Resolve-Path $Archive).Path
$project = (docker compose config --format json | ConvertFrom-Json).name
if ((Read-Host "Sovrascrivere TUTTI i dati correnti con $Archive ? (si/no)") -ne 'si') { return }
docker compose down
docker run --rm -v "${project}_senaite_data:/data" -v "${Archive}:/in.tar.gz:ro" alpine sh -c "rm -rf /data/* && tar xzf /in.tar.gz -C /data"
docker compose up -d
