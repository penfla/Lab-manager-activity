# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
# Rimuove TUTTO, dati inclusi. Eseguire prima Backup-PolyLab.ps1.
. "$PSScriptRoot\common.ps1"
if ((Read-Host 'Eliminare PolyLab LIMS e tutti i suoi dati? (si/no)') -ne 'si') { return }
if (Test-Installed) { Stop-PolyLab; wsl.exe --unregister $Distro | Out-Null }
$desk = [Environment]::GetFolderPath('Desktop'); $startup = [Environment]::GetFolderPath('Startup')
Remove-Item "$desk\PolyLab LIMS*.lnk", "$startup\PolyLab LIMS.lnk" -ErrorAction SilentlyContinue
$dir = Split-Path -Parent $PSScriptRoot
Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -Command Start-Sleep 3; Remove-Item -Recurse -Force '$dir'"
