# claude-open-with-context-menu

Adds an "Open with Claude" entry to the Windows Explorer right-click menu.
Right-click a folder, or empty space inside a folder, and Claude Code opens
in that folder in a new `cmd.exe` window.

Two entries are installed:

- **Classic menu** (registry, `HKCU`): under "Show more options" on Windows 11,
  and directly in the menu on Windows 10.
- **Windows 11 top-level menu** (sparse MSIX package with a small COM DLL):
  the entry appears in the main right-click menu.

Windows only. Linux and macOS are not covered yet.

## Requirements

- Windows 10 or 11
- Claude Code installed at `%USERPROFILE%\.local\bin\claude.exe`
  (the default location of the native installer)
- For the top-level menu entry only: Visual Studio Build Tools with the
  C++ workload. `modern\build-modern.bat` finds the compiler with `vswhere`.

No admin rights are needed. Everything is installed for the current user.

## Install

Double-click `install.bat`, or run it from a terminal:

    install.bat

This adds the classic entry first, then builds and registers the top-level
entry. If the build tools are missing, the classic entry stays and the
script says so.

If `claude.exe` is not at the default path, edit the `EXE` line in
`install.bat` and the matching path in `modern\build-modern.bat`.

## Uninstall

    uninstall.bat

This removes both entries, the signing certificate, and the registry keys.
Running it when nothing is installed is harmless.

## What the scripts change

Classic menu (`HKCU\Software\Classes`):

| Key | Trigger |
|---|---|
| `Directory\shell\Claude` | Right-click a folder |
| `Directory\Background\shell\Claude` | Right-click empty space in a folder |

Each key sets the label "Open with Claude", the icon (from `claude.exe`),
and this command:

    cmd.exe /d /k cd /d "<folder>" && "<claude.exe>"

Top-level menu:

- A self-signed code-signing certificate, `CN=OpenWithClaude Local`, in the
  current user's `My` and `TrustedPeople` stores.
- A sparse package, `OpenWithClaude.ContextMenu`, registered for the current
  user from `modern\build\pkg`. It holds `ClaudeContextMenu.dll`, a COM
  `IExplorerCommand` that runs the same command as the classic entry.

`modern\install-modern.bat` clears `PSModulePath` before it calls PowerShell.
A PowerShell 7 module path on that variable breaks the `Cert:` drive in
Windows PowerShell.

## Checks

- Classic entry: the registry values were read back with `reg query` after
  install, and both keys were gone after uninstall.
- `cd` step: run with `cmd.exe` on a sample path.
- Top-level entry: the package registers and reports `Status: Ok`. The DLL
  exports `DllGetClassObject` and `DllCanUnloadNow`, and the class factory
  returns S_OK when loaded directly.
- Not checked: the menu entry itself has not been clicked in Explorer by the
  author.

## Limits

- Paths with a trailing backslash on the background entry (for example the
  root of a drive, `C:\`) may not parse correctly, because `\"` escapes the
  closing quote. Untested.
- Folder names that contain `&` or `%` may need extra quoting. Untested.
- The top-level entry is unsigned by any public CA. Only this machine trusts
  its certificate.

## License

No license file yet.
