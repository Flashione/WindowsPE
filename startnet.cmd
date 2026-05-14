@echo off

wpeinit

powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1

echo.
echo Searching for WimTools USB root...
echo.

set "USBROOT="

for %%D in (C: D: E: F: G: H: I: J: K: L: M: N: O: P: Q: R: S: T: U: V: W: Y: Z:) do (
    if exist "%%D\WimTools\WIMTOOLS.TAG" (
        set "USBROOT=%%D"
        goto :FOUND
    )
)

echo WimTools USB root not found.
echo Expected marker:
echo \WimTools\WIMTOOLS.TAG
echo.
cmd /k
exit /b 1

:FOUND
echo Found WimTools at %USBROOT%\WimTools
echo.

if not exist "%USBROOT%\WimTools\startup.cmd" (
    echo startup.cmd not found:
    echo %USBROOT%\WimTools\startup.cmd
    echo.
    cmd /k
    exit /b 1
)

call "%USBROOT%\WimTools\startup.cmd"

echo.
echo startup.cmd finished or exited.
cmd /k
