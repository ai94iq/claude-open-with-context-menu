@echo off
rem Removes "Open with Claude" from the Windows Explorer context menu (HKCU only).

reg delete "HKCU\Software\Classes\Directory\shell\Claude" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Directory\Background\shell\Claude" /f >nul 2>&1

call "%~dp0modern\uninstall-modern.bat"
echo Removed "Open with Claude" (if it was installed).
exit /b 0
