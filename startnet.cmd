@echo off

wpeinit

powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1

echo.
echo Searching for external startup script...
echo.

set "USBROOT="

for %%D in (C: D: E: F: G: H: I: J: K: L: M: N: O: P: Q: R: S: T: U: V: W: Y: Z:) do (
    if /I not "%%D"=="X:" (
        if exist "%%D\start.cmd" (
            set "USBROOT=%%D"
            goto :FOUND
        )
    )
)

echo External startup script not found.
echo Expected:
echo \start.cmd
echo.
cmd /k
exit /b 1

:FOUND
echo Found startup script at %USBROOT%\start.cmd
echo.

call "%USBROOT%\start.cmd"

echo.
echo start.cmd finished or exited.
cmd /k
