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
reg add "HKCU\Software\Classes\Directory\shell\Claude\command" /ve /d "\"%EXE%\" \"%%1\"" /f >nul || goto :fail

rem Right-click on empty space inside a folder
reg add "HKCU\Software\Classes\Directory\Background\shell\Claude" /ve /d "Open with Claude" /f >nul || goto :fail
reg add "HKCU\Software\Classes\Directory\Background\shell\Claude" /v Icon /d "%EXE%" /f >nul || goto :fail
reg add "HKCU\Software\Classes\Directory\Background\shell\Claude\command" /ve /d "\"%EXE%\" \"%%V\"" /f >nul || goto :fail

echo Installed "Open with Claude" (folder and folder background).
echo On Windows 11 it appears under "Show more options".
exit /b 0

:fail
echo Failed to write the registry keys. Nothing else was changed.
exit /b 1
