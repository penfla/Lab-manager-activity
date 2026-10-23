# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
# Aggiorna: modificare SENAITE_VERSION in .env, eseguire backup.ps1, poi questo script.
# Dopo il pull, in SENAITE: Site Setup > Add-ons / Upgrades (https://github.com/senaite/senaite.core/blob/2.x/CHANGES.rst).
Set-Location (Split-Path -Parent $PSScriptRoot)
docker compose pull
docker compose up -d
