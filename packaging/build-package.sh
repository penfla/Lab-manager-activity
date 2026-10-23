#!/bin/bash
# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
# Costruisce dist/PolyLabLIMS-Setup.zip (script) e dist/polylab-rootfs.tar.gz (richiede Docker). Uso: ./build-package.sh [v2.6.0]
set -euo pipefail
cd "$(dirname "$0")"
V="${1:-v2.6.0}"; mkdir -p dist
docker build --build-arg SENAITE_VERSION="$V" -t polylab-rootfs:"$V" rootfs
c=$(docker create polylab-rootfs:"$V")
docker export "$c" | gzip -9 > dist/polylab-rootfs.tar.gz
docker rm "$c" >/dev/null
(cd windows && zip -qr ../dist/PolyLabLIMS-Setup.zip .)
makensis -V2 -DVERSION="${VERSION:-0.3.0}" -DOUTFILE="$PWD/dist/PolyLabLIMS-Setup.exe" nsis/polylab.nsi
ls -lh dist
