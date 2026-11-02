@echo off
rem Registers the Windows 11 top-level menu entry for the current user.
rem Creates a self-signed certificate on first run, trusts it for the current user,
rem then registers the sparse package. No admin needed.

setlocal
set "HERE=%~dp0"
set "PKG=%HERE%build\pkg"
set "SUBJECT=CN=OpenWithClaude Local"
set "CER=%TEMP%\OpenWithClaudeLocal.cer"

call "%HERE%build-modern.bat" || exit /b 1

rem A PSModulePath that points at PowerShell 7 modules breaks the Cert drive in Windows PowerShell.
set "PSModulePath="

rem Create the signing certificate if it is missing, and trust its public part for this user.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = '%SUBJECT%'; $c = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $s } | Select-Object -First 1; if (-not $c) { $c = New-SelfSignedCertificate -Type Custom -Subject $s -KeyUsage DigitalSignature -KeyAlgorithm RSA -KeyLength 2048 -CertStoreLocation Cert:\CurrentUser\My -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}') }; if (-not (Get-ChildItem Cert:\CurrentUser\TrustedPeople | Where-Object { $_.Subject -eq $s })) { Export-Certificate -Cert $c -FilePath '%CER%' | Out-Null; Import-Certificate -FilePath '%CER%' -CertStoreLocation Cert:\CurrentUser\TrustedPeople | Out-Null; Remove-Item '%CER%' }"
if errorlevel 1 (
    echo Certificate setup failed.
    exit /b 1
)

rem Replace any earlier registration, then register the package from the staged folder.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -Name 'OpenWithClaude.ContextMenu' | Remove-AppxPackage; Add-AppxPackage -Register '%PKG%\AppxManifest.xml' -ExternalLocation '%PKG%'"
if errorlevel 1 (
    echo Package registration failed.
    exit /b 1
)

echo Registered "Open with Claude" in the Windows 11 context menu.
exit /b 0
