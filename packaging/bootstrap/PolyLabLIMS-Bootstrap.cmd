<# :
@REM License-Identifier: PolyForm-Noncommercial-1.0.0
@REM Copyright (c) 2026 Flavio Pendolino
@REM https://polyformproject.org/licenses/noncommercial/1.0.0
@echo off
setlocal
set "SELF=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF); & ([scriptblock]::Create($s)) %*"
set RC=%errorlevel%
if not "%POLYLAB_NOPAUSE%"=="1" pause
exit /b %RC%
#>
# License-Identifier: PolyForm-Noncommercial-1.0.0
# Copyright (c) 2026 Flavio Pendolino
# https://polyformproject.org/licenses/noncommercial/1.0.0
#
# Installer automatico PolyLab LIMS (per-utente, senza admin): scarica pacchetto + rootfs e installa.
# -BaseUrl accetta URL https o percorso locale/UNC (\\server\share\polylab) con gli stessi file di una Release.
param(
    [string]$BaseUrl = 'https://github.com/penfla/Lab-manager-activity/releases/latest/download',
    [switch]$NoAutoStart
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$work = Join-Path $env:TEMP 'polylab-setup'
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Get-Asset([string]$Name) {
    $dst = Join-Path $work $Name
    Write-Host "Scarico $Name ..."
    if ($BaseUrl -match '^https?://') { Invoke-WebRequest -Uri "$BaseUrl/$Name" -OutFile $dst -UseBasicParsing }
    else { Copy-Item (Join-Path $BaseUrl $Name) $dst }
    return $dst
}
try {
    $zip = Get-Asset 'PolyLabLIMS-Setup.zip'
    $rootfs = Get-Asset 'polylab-rootfs.tar.gz'
    $pkg = Join-Path $work 'pkg'
    Expand-Archive $zip -DestinationPath $pkg -Force
    Move-Item $rootfs (Join-Path $pkg 'polylab-rootfs.tar.gz')
    $a = @{}; if (-not $NoAutoStart) { $a.AutoStart = $true }
    & (Join-Path $pkg 'install.ps1') @a
} catch {
    Write-Host "ERRORE: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}
