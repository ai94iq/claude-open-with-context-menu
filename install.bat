@echo off
rem Adds "Open with Claude" to the Windows Explorer context menu for the current user (HKCU, no admin).

setlocal
set "EXE=%USERPROFILE%\.local\bin\claude.exe"

if not exist "%EXE%" (
    echo claude.exe not found at "%EXE%"
    echo Install Claude Code first, or edit EXE in this file.
    exit /b 1
)

rem Right-click on a folder
reg add "HKCU\Software\Classes\Directory\shell\Claude" /ve /d "Open with Claude" /f >nul || goto :fail
reg add "HKCU\Software\Classes\Directory\shell\Claude" /v Icon /d "%EXE%" /f >nul || goto :fail
reg add "HKCU\Software\Classes\Directory\shell\Claude\command" /ve /d "cmd.exe /d /k cd /d \"%%1\" && \"%EXE%\"" /f >nul || goto :fail

rem Right-click on empty space inside a folder
reg add "HKCU\Software\Classes\Directory\Background\shell\Claude" /ve /d "Open with Claude" /f >nul || goto :fail
reg add "HKCU\Software\Classes\Directory\Background\shell\Claude" /v Icon /d "%EXE%" /f >nul || goto :fail
reg add "HKCU\Software\Classes\Directory\Background\shell\Claude\command" /ve /d "cmd.exe /d /k cd /d \"%%V\" && \"%EXE%\"" /f >nul || goto :fail

echo Installed "Open with Claude" in the classic menu (folder and folder background).

call "%~dp0modern\install-modern.bat"
if errorlevel 1 (
    echo Top-level menu entry failed. The classic entry is installed.
    exit /b 1
)
exit /b 0

:fail
echo Failed to write the registry keys. Nothing else was changed.
exit /b 1
