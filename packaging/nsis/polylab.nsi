; License-Identifier: PolyForm-Noncommercial-1.0.0
; Copyright (c) 2026 Flavio Pendolino
; https://polyformproject.org/licenses/noncommercial/1.0.0
;
; Installer per-utente PolyLab LIMS (Windows 11/10), nessun privilegio admin.
; Build: makensis -DVERSION=0.3.0 -DOUTFILE=PolyLabLIMS-Setup.exe polylab.nsi
; Silent: PolyLabLIMS-Setup.exe /S   (rootfs: polylab-rootfs.tar.gz accanto all'exe, altrimenti download da Releases)

!ifndef VERSION
  !define VERSION "0.0.0"
!endif
!ifndef OUTFILE
  !define OUTFILE "PolyLabLIMS-Setup.exe"
!endif
!define APPNAME "PolyLab LIMS"
!define UNKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\PolyLabLIMS"

Unicode true
Name "${APPNAME}"
OutFile "${OUTFILE}"
RequestExecutionLevel user
InstallDir "$LOCALAPPDATA\PolyLabLIMS"
BrandingText "${APPNAME} ${VERSION} | (c) 2026 Flavio Pendolino | PolyForm Noncommercial 1.0.0"

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "(c) 2026 Flavio Pendolino - PolyForm Noncommercial 1.0.0"
VIAddVersionKey "FileDescription" "PolyLab LIMS (SENAITE) per-user installer"

!include "MUI2.nsh"
!include "LogicLib.nsh"
!define MUI_WELCOMEPAGE_TEXT "Installa ${APPNAME} (basato su SENAITE, https://www.senaite.com) nel profilo utente, senza privilegi di amministratore.$\r$\n$\r$\nRichiede WSL2 gia' attivo e circa 3 GB di spazio. Se accanto a questo file e' presente polylab-rootfs.tar.gz viene usato, altrimenti viene scaricato (circa 1 GB).$\r$\n$\r$\nSoftware non commerciale (PolyForm Noncommercial 1.0.0); componenti SENAITE sotto GPL-2.0."
!define MUI_FINISHPAGE_TEXT "Installazione completata. Il browser si apre su http://localhost:8080. Credenziali: $INSTDIR\credenziali.txt"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Italian"

Function .onInit
  nsExec::ExecToStack 'wsl.exe --status'
  Pop $0
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "WSL non e' attivo su questo PC. L'abilitazione di WSL richiede una tantum l'IT (comando: wsl --install). Installazione annullata." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Section "Install"
  SetOutPath "$PLUGINSDIR\pkg"
  File "..\windows\*.ps1"
  StrCpy $1 ""
  IfFileExists "$EXEDIR\polylab-rootfs.tar.gz" 0 +2
    StrCpy $1 '-Rootfs "$EXEDIR\polylab-rootfs.tar.gz"'
  DetailPrint "Installazione distro WSL2 (alcuni minuti)..."
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\pkg\install.ps1" -AutoStart $1'
  Pop $0
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Installazione fallita (codice $0). Vedere il dettaglio nella finestra." /SD IDOK
    Abort
  ${EndIf}
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "${UNKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "${UNKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNKEY}" "Publisher" "Flavio Pendolino"
  WriteRegStr HKCU "${UNKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKCU "${UNKEY}" "NoModify" 1
SectionEnd

Section "Uninstall"
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\bin\Uninstall-PolyLab.ps1" -Force -KeepFiles'
  DeleteRegKey HKCU "${UNKEY}"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
SectionEnd
