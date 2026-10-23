# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
#Requires -RunAsAdministrator
param([string]$At = '02:00')
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\backup.ps1`""
Register-ScheduledTask -TaskName 'SENAITE Backup' -Action $a -Trigger (New-ScheduledTaskTrigger -Daily -At $At) `
    -RunLevel Highest -User 'SYSTEM' -Force | Out-Null
Write-Host "Task 'SENAITE Backup' registrato alle $At."
