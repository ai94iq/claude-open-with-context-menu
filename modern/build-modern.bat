@echo off
rem Builds the Windows 11 top-level menu package into modern\build\pkg.
rem Needs Visual Studio Build Tools (C++) and the Windows 10/11 SDK.

setlocal EnableDelayedExpansion
set "HERE=%~dp0"
set "BUILD=%HERE%build"
set "PKG=%BUILD%\pkg"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

if not exist "%VSWHERE%" (
    echo Visual Studio Installer not found. Install Build Tools with the C++ workload.
    exit /b 1
)

set "VCVARS="
for /f "usebackq delims=" %%i in (`""!VSWHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find "VC\Auxiliary\Build\vcvars64.bat""`) do set "VCVARS=%%i"
if not defined VCVARS (
    echo No C++ build tools found. Install Build Tools with the C++ workload.
    exit /b 1
)

if exist "%BUILD%" rmdir /s /q "%BUILD%"
mkdir "%PKG%\Assets" || exit /b 1

call "%VCVARS%" >nul 2>&1 || exit /b 1
pushd "%BUILD%"

cl /nologo /LD /EHsc /std:c++17 /W4 /WX /O2 "%HERE%ClaudeContextMenu.cpp" /Fe:ClaudeContextMenu.dll /link /DEF:"%HERE%ClaudeContextMenu.def" || goto :fail
cl /nologo "%HERE%stub.c" /Fe:ClaudeContextMenu.exe || goto :fail
popd

copy /y "%BUILD%\ClaudeContextMenu.dll" "%PKG%\" >nul || exit /b 1
copy /y "%BUILD%\ClaudeContextMenu.exe" "%PKG%\" >nul || exit /b 1
copy /y "%HERE%AppxManifest.xml" "%PKG%\" >nul || exit /b 1
copy /y "%HERE%Assets\StoreLogo.png" "%PKG%\Assets\" >nul || exit /b 1
copy /y "%HERE%Assets\claude.ico" "%PKG%\Assets\" >nul || exit /b 1
copy /y "%HERE%Assets\claude.png" "%PKG%\Assets\" >nul || exit /b 1

echo Built package in "%PKG%".
exit /b 0

:fail
popd
echo Build failed.
exit /b 1
