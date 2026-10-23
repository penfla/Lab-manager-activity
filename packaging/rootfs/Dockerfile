# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
# Rootfs WSL2 di PolyLab LIMS = immagine ufficiale SENAITE (https://hub.docker.com/r/senaite/senaite) + wrapper.
ARG SENAITE_VERSION=v2.6.0
FROM senaite/senaite:${SENAITE_VERSION}
COPY wsl.conf /etc/wsl.conf
COPY run.sh /opt/polylab/run.sh
RUN chmod 755 /opt/polylab/run.sh
