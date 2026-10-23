# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
#Requires -RunAsAdministrator
# OPZIONALE, da eseguire dall'IT: espone PolyLab LIMS sulla LAN (WSL2 mirrored networking, Windows 11 22H2+ / WSL >= 2.0).
param([int]$Port = 8080)
$cfg = "$env:USERPROFILE\.wslconfig"
if (-not (Select-String -Path $cfg -Pattern 'networkingMode' -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content $cfg "`n[wsl2]`nnetworkingMode=mirrored"
}
New-NetFirewallRule -DisplayName 'PolyLab LIMS' -Direction Inbound -Protocol TCP -LocalPort $Port -Profile Domain,Private -Action Allow | Out-Null
Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow
wsl.exe --shutdown
Write-Host 'Fatto. Riavviare PolyLab LIMS; accesso da LAN: http://<nome-pc>:' $Port
