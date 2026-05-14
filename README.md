# WindowsPE

This repository contains the Windows PE boot environment documentation and the `startnet.cmd` template used by WimTools-based USB sticks.

The PE image is universal. It does not know whether the USB stick will start the full WimTools toolkit or the restore-only package. It only searches for an external startup router:

```text
\start.cmd
```

That file lives on the writable USB data partition and is provided by the tool repository that is copied to the stick.

## Design

```text
boot.wim
└── X:\Windows\System32\startnet.cmd
    └── searches C: through Z: for \start.cmd
        └── calls \start.cmd from the detected USB data partition
```

Important:

```text
X: is the WinPE RAM drive.
USB drive letters are not stable.
The tools are not stored in X:.
The PE does not hardcode WimTools or WimTools-Restore.
```

This keeps the PE reusable. The routing logic lives outside the PE in `start.cmd`, because apparently avoiding repeated `boot.wim` surgery is a thing humans must learn through pain.

## Microsoft components

Install the official Microsoft tools on the Windows build machine:

```text
Windows ADK:
https://go.microsoft.com/fwlink/?linkid=2337875

Windows PE Add-on:
https://go.microsoft.com/fwlink/?linkid=2337681
```

Required ADK feature:

```text
Deployment Tools
```

Then install the Windows PE Add-on.

## Build shell

Open as Administrator:

```text
Deployment and Imaging Tools Environment
```

## Create WinPE working directory

```bat
copype amd64 C:\WinPE_amd64
```

Created structure:

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

## Mount boot.wim

```bat
Dism /Mount-Image ^
 /ImageFile:C:\WinPE_amd64\media\sources\boot.wim ^
 /Index:1 ^
 /MountDir:C:\WinPE_amd64\mount
```

## Add WinPE optional components

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

Included components:

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

Check package state:

```bat
Dism /Image:C:\WinPE_amd64\mount /Get-Packages | findstr /i "WinPE"
```

## Replace startnet.cmd

Replace this file inside the mounted image:

```text
C:\WinPE_amd64\mount\Windows\System32\startnet.cmd
```

with the repository template:

```text
startnet.cmd
```

Example from the WindowsPE repository root:

```bat
copy /y startnet.cmd C:\WinPE_amd64\mount\Windows\System32\startnet.cmd
```

The template does this:

```text
1. Run wpeinit
2. Set high performance power plan
3. Search C: through Z: for \start.cmd
4. Call \start.cmd from the detected drive
5. Keep a command prompt open if startup fails
```

## Commit boot.wim

```bat
Dism /Unmount-Image /MountDir:C:\WinPE_amd64\mount /Commit
```

The final PE boot files are then in:

```text
C:\WinPE_amd64\media
```

## USB layout

Recommended two-partition USB layout:

```text
BOOT      FAT32   2 GB   Windows PE boot files
WIMTOOLS  NTFS    Rest   tool repository content, images, captures and logs
```

Copy the content of:

```text
C:\WinPE_amd64\media
```

to the FAT32 `BOOT` partition.

Copy the selected tool repository content, for example `wimtools` or `WimTools-Restore`, to the NTFS `WIMTOOLS` partition.

The NTFS partition must contain:

```text
\start.cmd
```

The PE loader only requires `\start.cmd`. Everything after that is handled by the external tool repository.

## Runtime examples

Full WimTools USB:

```text
NTFS WIMTOOLS:
\start.cmd
\WimTools\startup.cmd
\WimTools\WIMTOOLS.TAG
\WimTools\Restore\
\WimTools\Capture\
\WimTools\drivers\
```

Restore-only USB:

```text
NTFS WIMTOOLS:
\start.cmd
\WimTools\startup.cmd
\WimTools\WIMTOOLS.TAG
\WimTools\Recovery.wim
```

## Generated files policy

Do not commit generated Microsoft or image artifacts:

```text
*.wim
*.esd
*.iso
*.cab
*.msi
C:\WinPE_amd64\
WinPE media folders
WinPE mount folders
ADK installers
PE Add-on installers
```
