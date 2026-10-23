# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
<#
 Installazione per-utente, senza privilegi di amministratore: importa un rootfs WSL2 in %LOCALAPPDATA%.
 Prerequisito: WSL gia' abilitato sul PC (verificato da questo script).
#>
param(
    [string]$Rootfs = (Join-Path $PSScriptRoot 'polylab-rootfs.tar.gz'),
    [string]$RootfsUrl = 'https://github.com/penfla/Lab-manager-activity/releases/latest/download/polylab-rootfs.tar.gz',
    [string]$InstallDir = "$env:LOCALAPPDATA\PolyLabLIMS",
    [switch]$AutoStart
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

if (-not (Test-Wsl)) {
    throw "WSL non e' disponibile su questo PC. Senza WSL attivo l'installazione richiede un intervento una tantum dell'IT (wsl --install). Vedi README."
}
if (Test-Installed) { throw "PolyLab LIMS e' gia' installato. Usare Uninstall-PolyLab.ps1 o Update." }
if (Test-NetConnection localhost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue) {
    throw "Porta $Port gia' in uso."
}

New-Item -ItemType Directory -Force -Path "$InstallDir\bin", "$InstallDir\distro" | Out-Null
if (-not (Test-Path $Rootfs)) {
    Write-Host "Download rootfs da $RootfsUrl ..."
    $Rootfs = Join-Path $env:TEMP 'polylab-rootfs.tar.gz'
    Invoke-WebRequest -Uri $RootfsUrl -OutFile $Rootfs -UseBasicParsing
}
Write-Host 'Importazione distro WSL2 (alcuni minuti)...'
wsl.exe --import $Distro "$InstallDir\distro" $Rootfs --version 2
if ($LASTEXITCODE -ne 0) { throw 'wsl --import fallito' }

$chars = (48..57) + (65..90) + (97..122)
$pw = -join (1..20 | ForEach-Object { [char]($chars | Get-Random) })
Invoke-InDistro @('sh', '-c', "umask 077; mkdir -p /opt/polylab; printf %s '$pw' > /opt/polylab/password")
"utente: admin`npassword: $pw`nURL: $Url" | Set-Content "$InstallDir\credenziali.txt" -Encoding ascii

Get-ChildItem $PSScriptRoot -Filter *.ps1 | Where-Object Name -ne 'install.ps1' | Copy-Item -Destination "$InstallDir\bin"
$ws = New-Object -ComObject WScript.Shell
function New-Link($path, $script, $icon) {
    $l = $ws.CreateShortcut($path); $l.TargetPath = 'powershell.exe'
    $l.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstallDir\bin\$script`""
    $l.IconLocation = $icon; $l.Save()
}
$desk = [Environment]::GetFolderPath('Desktop')
New-Link "$desk\PolyLab LIMS.lnk" 'Start-PolyLab.ps1' 'shell32.dll,13'
New-Link "$desk\PolyLab LIMS - Stop.lnk" 'Stop-PolyLab.ps1' 'shell32.dll,27'
if ($AutoStart) { New-Link "$([Environment]::GetFolderPath('Startup'))\PolyLab LIMS.lnk" 'Start-PolyLab.ps1' 'shell32.dll,13' }

Write-Host "`nInstallato in $InstallDir. Credenziali: $InstallDir\credenziali.txt" -ForegroundColor Green
Write-Host 'Primo avvio: 1-3 min; poi "Add new SENAITE Site" (id: senaite).'
& "$InstallDir\bin\Start-PolyLab.ps1"
