@echo off
rem Removes the Windows 11 top-level menu entry and its certificate for the current user.

set "SUBJECT=CN=OpenWithClaude Local"
rem See install-modern.bat: a PowerShell 7 module path breaks the Cert drive.
set "PSModulePath="

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -Name 'OpenWithClaude.ContextMenu' | Remove-AppxPackage; Get-ChildItem Cert:\CurrentUser\TrustedPeople, Cert:\CurrentUser\My | Where-Object { $_.Subject -eq '%SUBJECT%' } | Remove-Item"

echo Removed the Windows 11 menu entry (if it was installed).
exit /b 0
