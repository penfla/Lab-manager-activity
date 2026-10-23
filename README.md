<!-- License-Identifier: PolyForm-Noncommercial-1.0.0 · Copyright (c) 2026 Flavio Pendolino · https://polyformproject.org/licenses/noncommercial/1.0.0 -->

# SENAITE LIMS — deploy per PC aziendali Windows

© Flavio Pendolino, 2026. Questo documento è distribuito con licenza CC BY-NC 4.0 (creativecommons.org/licenses/by-nc/4.0)

```
Author: Flavio Pendolino
Version: 0.1.0
License: PolyForm Noncommercial 1.0.0
Commercial use: penfla@me.com
Purpose: deploy riproducibile di SENAITE LIMS su Windows con accesso multi-PC (LAN o cloud)
Method: Docker Desktop (WSL2) + stack ZEO/client dall'immagine ufficiale senaite/senaite; script PowerShell
Disclaimer: validate the results against your own reference samples before any analytical, engineering, safety or regulatory use.
Third-party components: SENAITE core/lims/docker (GPL-2.0), Plone, Zope/ZODB, Docker, Caddy (Apache-2.0)
Scientific references: n/a
AI disclosure: questo strumento esegue calcoli deterministici; non genera contenuto tramite IA generativa (art. 50 AI Act non applicabile).
```

**Nota licenze:** `upstream/*` (SENAITE, https://www.senaite.com) resta **GPL-2.0** (submodule, non modificato). Solo `deploy/` e questo README sono sotto la licenza indicata sopra.

## Architettura

SENAITE (Plone/Zope, Python) non è supportato nativamente su Windows. Si installa **su un solo host Windows** (PC o server) tramite Docker Desktop + WSL2; gli altri PC accedono **dal browser**. Non si condivide un file DB tra PC: ZODB (`Data.fs`) su share SMB/OneDrive si corrompe con accessi concorrenti. Il multiutente è gestito dal server ZEO.

| Scenario | Come | Note |
|---|---|---|
| **Server LAN** (consigliato) | `install.ps1` sull'host; client → `http://<IP-host>:8080` | IP fisso/DNS interno; firewall solo profili Domain/Private |
| **Cloud** | VM Linux/Windows con Docker + `docker-compose.cloud.yml` | HTTPS Let's Encrypt via Caddy, `SENAITE_BIND=127.0.0.1` |
| **Cartella comune / cloud sync** | Solo per **backup** (`BACKUP_DIR` = UNC `\\server\share\senaite` o cartella OneDrive/SharePoint sincronizzata) | Non usare come storage live |

## Installazione (host LAN)

Prerequisiti: Windows 10/11 Pro o Server 2022, virtualizzazione abilitata, ≥4 core, ≥8 GB RAM, [Docker Desktop](https://www.docker.com/products/docker-desktop/) in esecuzione (avvio automatico + servizio all'avvio del PC).

```powershell
git clone --recurse-submodules <url-di-questo-repo>
cd Lab-manager-activity\deploy\windows
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Port 8080
```

Lo script crea `deploy\.env` (password admin casuale), apre la porta nel firewall, scarica `senaite/senaite:v2.6.0` e avvia il stack. Primo accesso: `admin` + password da `.env` → *Add new SENAITE Site* (id `senaite`).

## Cloud

```bash
cd deploy && cp .env.example .env   # SENAITE_BIND=127.0.0.1, SENAITE_DOMAIN=lims.tuodominio.it, password
docker compose -f docker-compose.yml -f docker-compose.cloud.yml up -d
```

DNS A/AAAA verso la VM; porte 80/443 aperte. Il `Caddyfile` riscrive via VirtualHostMonster (`/VirtualHostBase/https/<dominio>:443/senaite/VirtualHostRoot`); sito con id `senaite`. Dati sanitari/campioni di terzi: valutare GDPR, regione del cloud e DPA col provider.

## Operatività

| Azione | Comando (`deploy\windows`) |
|---|---|
| Backup a freddo (~1 min di fermo) | `.\backup.ps1` |
| Backup notturno 02:00 | `.\register-backup-task.ps1 -At 02:00` (admin) |
| Restore | `.\restore.ps1 -Archive <file.tar.gz>` |
| Aggiornamento | cambiare `SENAITE_VERSION` in `.env` → backup → `.\update.ps1` → upgrade add-on da UI |
| Secondo client ZEO | `docker compose --profile scale up -d` (porta 8081; serve bilanciatore) |

Limiti noti: stack non testato su Windows in questa sessione (build in ambiente Linux: solo validazione `docker compose config`); backup a freddo, non incrementale; password admin in `.env` (proteggere con ACL NTFS); nessun SSO/LDAP preconfigurato. Per produzione regolamentata (ISO 17025, GLP) serve IQ/OQ/PQ e validazione del sistema.

## Riferimenti

- SENAITE: https://www.senaite.com · https://github.com/senaite/senaite.core · https://github.com/senaite/senaite.lims
- Immagine/stack: https://github.com/senaite/senaite.docker · https://hub.docker.com/r/senaite/senaite
- Docs: https://www.senaite.com/docs · Community: https://community.senaite.org
