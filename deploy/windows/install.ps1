# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
#Requires -RunAsAdministrator
<#
 Installa SENAITE sul PC/server Windows che fara' da host (Docker Desktop + WSL2:
 https://docs.docker.com/desktop/setup/install/windows-install/). Gli altri PC usano il browser.
#>
param([int]$Port = 8080, [switch]$NoFirewall)
$ErrorActionPreference = 'Stop'
$deploy = Split-Path -Parent $PSScriptRoot
Set-Location $deploy

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker non trovato. Installare Docker Desktop (WSL2): https://www.docker.com/products/docker-desktop/ poi rieseguire."
}
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker Desktop non in esecuzione. Avviarlo e rieseguire." }

if (-not (Test-Path .env)) {
    $chars = (48..57) + (65..90) + (97..122)
    $pwd = -join (1..20 | ForEach-Object { [char]($chars | Get-Random) })
    (Get-Content .env.example) -replace 'CAMBIAMI', $pwd -replace '^SENAITE_PORT=.*', "SENAITE_PORT=$Port" |
        Set-Content .env -Encoding ascii
    Write-Host "Creato .env. Password admin: $pwd  (salvarla in un password manager)" -ForegroundColor Yellow
}

if (-not $NoFirewall) {
    if (-not (Get-NetFirewallRule -DisplayName 'PolyLab LIMS' -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName 'PolyLab LIMS' -Direction Inbound -Protocol TCP `
            -LocalPort $Port -Profile Domain,Private -Action Allow | Out-Null
    }
}

docker compose pull
docker compose up -d
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -ne 'WellKnown' -and $_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress
Write-Host "`nSENAITE avviato. Primo avvio: 1-3 min." -ForegroundColor Green
Write-Host "Locale : http://localhost:$Port"
Write-Host "LAN    : http://${ip}:$Port   (da usare sugli altri PC)"
Write-Host "Primo accesso: utente admin, password in .env; poi 'Add new SENAITE Site' con id 'senaite'."
