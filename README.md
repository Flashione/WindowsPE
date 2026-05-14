# WinPE Build Guide

Diese Anleitung beschreibt, wie das WinPE fuer WimTools lokal gebaut wurde.

Wichtig: Das PE enthaelt nicht die eigentlichen WimTools-Skripte. Im PE liegt nur `startnet.cmd`. Die Tools liegen spaeter auf der externen beschreibbaren USB-Datenpartition unter `\WimTools`.

`X:` ist das WinPE-RAM-Laufwerk. WimTools liegt niemals fest unter `X:\WimTools`.

## 1. Microsoft-Komponenten installieren

Installiere auf der Windows-Build-VM die offiziellen Microsoft-Komponenten:

```text
Windows ADK:
https://go.microsoft.com/fwlink/?linkid=2337875

Windows PE Add-on:
https://go.microsoft.com/fwlink/?linkid=2337681
```

Beim ADK wird nur diese Komponente benoetigt:

```text
Deployment Tools
```

Danach das Windows PE Add-on installieren.

## 2. Build-Shell starten

Starte als Administrator:

```text
Deployment and Imaging Tools Environment
```

Nicht eine normale CMD verwenden, ausser die ADK-Umgebung ist geladen. Ja, Windows macht sogar die Shell zur Stolperfalle.

## 3. WinPE-Arbeitsstruktur erstellen

```bat
copype amd64 C:\WinPE_amd64
```

Dadurch entsteht ungefaehr:

```text
C:\WinPE_amd64\
├── fwfiles\
├── media\
│   ├── EFI\
│   ├── boot\
│   └── sources\
│       └── boot.wim
└── mount\
```

## 4. boot.wim mounten

```bat
Dism /Mount-Image ^
 /ImageFile:C:\WinPE_amd64\media\sources\boot.wim ^
 /Index:1 ^
 /MountDir:C:\WinPE_amd64\mount
```

## 5. WinPE Optional Components einbauen

```bat
set OC=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs
set MOUNT=C:\WinPE_amd64\mount

Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-WMI.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-NetFx.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-Scripting.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-PowerShell.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-DismCmdlets.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-StorageWMI.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-SecureStartup.cab"
Dism /Add-Package /Image:%MOUNT% /PackagePath:"%OC%\WinPE-SecureBootCmdlets.cab"
```

Eingebaute Komponenten:

```text
WinPE-WMI
WinPE-NetFx
WinPE-Scripting
WinPE-PowerShell
WinPE-DismCmdlets
WinPE-StorageWMI
WinPE-SecureStartup
WinPE-SecureBootCmdlets
```

Paketstand pruefen:

```bat
Dism /Image:C:\WinPE_amd64\mount /Get-Packages | findstr /i "WinPE"
```

Erwartete Richtung:

```text
Microsoft-Windows-WinPE-Package
Microsoft-Windows-WinPE-LanguagePack-Package en-US
WinPE-WMI-Package
WinPE-NetFx-Package
WinPE-Scripting-Package
WinPE-PowerShell-Package
WinPE-DismCmdlets-Package
WinPE-StorageWMI-Package
WinPE-SecureStartup-Package
WinPE-SecureBootCmdlets-Package
```

## 6. startnet.cmd ersetzen

Ersetze in der gemounteten WIM diese Datei:

```text
C:\WinPE_amd64\mount\Windows\System32\startnet.cmd
```

mit:

```text
WindowsPE\startnet.cmd
```

Beispiel:

```bat
copy /y WindowsPE\startnet.cmd C:\WinPE_amd64\mount\Windows\System32\startnet.cmd
```

Die wichtige Logik in `startnet.cmd`:

```text
1. wpeinit ausfuehren
2. High Performance Powerplan setzen
3. Alle Laufwerksbuchstaben nach \WimTools\WIMTOOLS.TAG durchsuchen
4. Gefundenes Laufwerk als USBROOT verwenden
5. \WimTools\startup.cmd vom gefundenen Laufwerk starten
6. Bei Fehlern eine CMD offen halten
```

## 7. boot.wim committen

```bat
Dism /Unmount-Image /MountDir:C:\WinPE_amd64\mount /Commit
```

Danach liegt der fertige PE-Bootteil hier:

```text
C:\WinPE_amd64\media
```

## 8. Auf USB-Stick kopieren

Die FAT32-Bootpartition bekommt den Inhalt von:

```text
C:\WinPE_amd64\media
```

Also typischerweise:

```text
FAT32 BOOT:
\EFI\
\boot\
\sources\boot.wim
\bootmgr
\bootmgr.efi
```

Die eigentlichen Tools kommen auf die NTFS-Datenpartition:

```text
NTFS WIMTOOLS:
\WimTools\WIMTOOLS.TAG
\WimTools\startup.cmd
\WimTools\common\set-power.cmd
\WimTools\Restore\WimApply.cmd
\WimTools\Restore\Images\
\WimTools\Capture\WimCapture.cmd
\WimTools\drivers\
\WimTools\StickCreator\
```

FAT32 ist nur fuer Boot. NTFS ist fuer Skripte, Images, Captures und Logs.

## 9. Marker-Datei

`startnet.cmd` sucht nach:

```text
\WimTools\WIMTOOLS.TAG
```

Die Datei kann leer sein. Der Inhalt wird nicht gelesen.

Beispielinhalt:

```text
WimTools marker file.
This file only has to exist.
The content is ignored by startnet.cmd.
```

## 10. Test-Checkliste

```text
1. Vom USB-Stick booten
2. WinPE startet
3. startnet.cmd sucht WimTools
4. \WimTools\WIMTOOLS.TAG wird gefunden
5. \WimTools\startup.cmd wird gestartet
6. WimTools-Menue erscheint
```

Wenn WimTools nicht gefunden wird:

```text
- Der Ordner muss exakt WimTools heissen
- WIMTOOLS.TAG muss direkt unter \WimTools liegen
- startup.cmd muss direkt unter \WimTools liegen
- WimTools liegt auf der externen USB-Datenpartition, nicht auf X:
```
