# PolyLab LIMS

LIMS per laboratori, basato su [SENAITE](https://www.senaite.com) (open source, Plone/Zope), con pacchetti di installazione per PC aziendali Windows. Powered by SENAITE — SENAITE è un marchio dei rispettivi titolari; PolyLab LIMS non è un prodotto ufficiale SENAITE.

> Nome proposto: **PolyLab LIMS**. Alternative: *LabForge LIMS*, *BenchTrack LIMS*, *SampleDesk LIMS*. Il nome è un solo valore (`$Distro` in `packaging/windows/common.ps1`, titolo di questo README): cambiarlo è banale.

## Opzioni di installazione

SENAITE 2.x gira su **Python 2.7 + Plone 5.2**: non esiste una build nativa Windows. Tutte le opzioni usano Linux in un contenitore o in WSL2.

| Opzione | Admin Windows | Multi-PC | Quando |
|---|---|---|---|
| **A. Pacchetto per-utente (WSL2)** — `packaging/` | **No**, se WSL è già attivo | Solo con 1 passaggio IT (firewall), vedi sotto | PC aziendali senza diritti admin |
| **B. Docker Desktop (LAN)** — `deploy/` | Sì (Docker Desktop) | Sì, ZEO | Server/PC host gestito dall'IT |
| **C. Cloud (VM + HTTPS)** — `deploy/docker-compose.cloud.yml` | No (lato client: solo browser) | Sì | Accesso da sedi diverse |

Una cartella condivisa (SMB/OneDrive) **non** può ospitare il database live (`Data.fs` di ZODB si corrompe con accessi concorrenti): serve solo come destinazione dei backup.

## A. Installazione senza privilegi admin

Il pacchetto importa una distro WSL2 dedicata in `%LOCALAPPDATA%\PolyLabLIMS` (nessun UAC, nessuna scrittura in `Program Files` o nel registro di sistema, nessun servizio).

**Prerequisito reale:** WSL2 già abilitato (`wsl --status` senza errori; di serie su molti Windows 11). Se manca, l'abilitazione della funzionalità Windows richiede **una tantum** l'IT (`wsl --install`) — non aggirabile senza admin. Le policy aziendali (AppLocker, blocco PowerShell, virtualizzazione disattivata nel BIOS) possono impedire l'installazione.

**Installer eseguibile (Windows 11/10)** — da [Releases](https://github.com/penfla/Lab-manager-activity/releases): `PolyLabLIMS-Setup.exe` (NSIS, `RequestExecutionLevel user`: nessun UAC).

- Doppio clic: verifica WSL, scarica `polylab-rootfs.tar.gz` (~1 GB; se il file è già accanto all'exe viene usato, utile offline), importa la distro WSL2, genera la password, crea icone Desktop e avvio al login, apre http://localhost:8080 (primo avvio 1–3 min). Credenziali in `%LOCALAPPDATA%\PolyLabLIMS\credenziali.txt`; poi *Add new SENAITE Site* (id `senaite`).
- Distribuzione IT/silent: `PolyLabLIMS-Setup.exe /S`.
- Disinstallazione: *Impostazioni → App* (voce per-utente) oppure `Uninstall-PolyLab.ps1`. **Elimina anche i dati**: fare prima il backup.
- Alternative: `PolyLabLIMS-Bootstrap.cmd [-BaseUrl \\server\share\polylab]` (scarica da share interna / repo privato), oppure zip + `Install.cmd`.
- L'exe non è firmato: SmartScreen/antivirus possono avvisare. Per la distribuzione aziendale firmarlo (code signing).

| Azione | Script (in `%LOCALAPPDATA%\PolyLabLIMS\bin`) |
|---|---|
| Avvio / arresto | icone sul Desktop, `Start-PolyLab.ps1` / `Stop-PolyLab.ps1` |
| Backup (a freddo, ~1 min) | `Backup-PolyLab.ps1 -Dest "\\server\share\polylab"` (anche cartella locale o OneDrive sincronizzata) |
| Restore | `Restore-PolyLab.ps1 -Archive <file.tar.gz>` |
| Disinstallazione completa | `Uninstall-PolyLab.ps1` |

**Accesso da altri PC (modalità A):** l'istanza ascolta su `localhost` del PC host. Per esporla in LAN servono diritti admin una tantum (regola firewall in ingresso + WSL mirrored networking, Windows 11 22H2+): l'IT esegue `enable-lan-access.ps1`. Senza questo passaggio ogni PC ha un'istanza **separata** (dati non condivisi). Per condividere dati senza interventi IT sul PC host, usare l'opzione C. Modalità A è single-client (niente ZEO): adatta a team piccoli.

**Costruzione del pacchetto:** tag `v*` → GitHub Actions ([`build-package.yml`](.github/workflows/build-package.yml)) esegue `packaging/build-package.sh` (immagine [senaite/senaite](https://hub.docker.com/r/senaite/senaite) + wrapper → `polylab-rootfs.tar.gz`; zip degli script).

## B. Server LAN con Docker Desktop

Prerequisiti: Windows 10/11 Pro o Server 2022, ≥4 core, ≥8 GB RAM, [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```powershell
git clone --recurse-submodules https://github.com/penfla/Lab-manager-activity
cd Lab-manager-activity\deploy\windows
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Port 8080   # admin
```

Crea `deploy\.env` (password casuale), regola firewall (profili Domain/Private), avvia ZEO + client. Gli altri PC aprono `http://<IP-host>:8080`. Backup: `backup.ps1` / `register-backup-task.ps1 -At 02:00` (destinazione `BACKUP_DIR` in `.env`: locale, UNC o OneDrive); restore: `restore.ps1`; aggiornamento: `SENAITE_VERSION` in `.env` → backup → `update.ps1`. Secondo client: `docker compose --profile scale up -d`.

## C. Cloud

```bash
cd deploy && cp .env.example .env   # SENAITE_BIND=127.0.0.1, SENAITE_DOMAIN=lims.tuodominio.it, password
docker compose -f docker-compose.yml -f docker-compose.cloud.yml up -d
```

DNS verso la VM, porte 80/443 aperte; HTTPS Let's Encrypt via [Caddy](https://caddyserver.com). Dati di terzi: valutare GDPR, regione e DPA col provider.

## Limiti noti

- Pacchetti e script **non testati su Windows** in questa sessione (autore dell'ambiente: Linux, nessun daemon Docker); il rootfs non è stato costruito. Primo test: build via workflow e install su un PC pilota.
- Password admin applicata via `inituser` di Zope solo alla creazione del DB; in caso di dubbio cambiarla da *Users and Groups*.
- Arresto: SIGTERM a Zope + `wsl --terminate`; backup a freddo non incrementali; nessun SSO/LDAP.
- Uso regolamentato (ISO 17025, GLP/GMP): serve validazione del sistema (IQ/OQ/PQ).

## Riferimenti

- SENAITE: https://www.senaite.com · https://github.com/senaite/senaite.core · https://github.com/senaite/senaite.lims · https://github.com/senaite/senaite.docker
- WSL (import distro, networking): https://learn.microsoft.com/windows/wsl/use-custom-distro · https://learn.microsoft.com/windows/wsl/networking

---

## Licenza e informazioni

```
Author: Flavio Pendolino
Version: 0.3.0
License: PolyForm Noncommercial 1.0.0
Commercial use: penfla@me.com
Purpose: distribuzione di un LIMS (SENAITE) su PC aziendali Windows, con o senza privilegi admin, accesso multi-PC (LAN/cloud)
Method: rootfs WSL2 per-utente dall'immagine ufficiale senaite/senaite; in alternativa stack Docker ZEO/client; script PowerShell
Disclaimer: validate the results against your own reference samples before any analytical, engineering, safety or regulatory use.
Third-party components: SENAITE core/lims/docker (GPL-2.0), Plone, Zope/ZODB, Docker, WSL, Caddy (Apache-2.0)
Scientific references: n/a
AI disclosure: questo strumento esegue calcoli deterministici; non genera contenuto tramite IA generativa (art. 50 AI Act non applicabile).
```

- `deploy/`, `packaging/`, `.github/` e questo README: [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/), © 2026 Flavio Pendolino. Uso commerciale: penfla@me.com.
- `upstream/*` (SENAITE, submodule non modificati) e l'immagine `senaite/senaite`: **GPL-2.0**. La compatibilità con una licenza non commerciale va verificata prima di ridistribuire il rootfs (che contiene codice GPL) a terzi.

© 2026 Flavio Pendolino | [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/)
