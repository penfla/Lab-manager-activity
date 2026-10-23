# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
. "$PSScriptRoot\common.ps1"
Start-PolyLab
if (Wait-Ready) { Start-Process $script:Url } else { Write-Warning "Nessuna risposta su $script:Url dopo 4 minuti." }
