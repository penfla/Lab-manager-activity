#!/bin/bash
# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
# Avvio SENAITE standalone (singolo client, filestorage locale in /data) dentro WSL2.
set -e
cd /home/senaite/senaitelims
mkdir -p /data/filestorage /data/blobstorage
# Password admin applicata solo prima della creazione del database (inituser di Zope)
if [ -f /opt/polylab/password ] && [ ! -s /data/filestorage/Data.fs ]; then
  chown -R senaite:senaite /data
  gosu senaite bin/instance adduser admin "$(cat /opt/polylab/password)" || true
fi
exec /docker-entrypoint.sh start
