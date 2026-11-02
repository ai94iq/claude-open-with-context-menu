# claude-open-with-context-menu

Adds an "Open with Claude" entry to the Windows Explorer right-click menu.
Right-click a folder, or empty space inside a folder, and Claude Code opens
in that folder in a new `cmd.exe` window.

Two entries are installed:

- **Classic menu** (registry, `HKCU`): under "Show more options" on Windows 11,
  and directly in the menu on Windows 10.
- **Windows 11 top-level menu** (sparse MSIX package with a small COM DLL):
  the entry appears in the main right-click menu.

## Platforms

| Platform | Install | Menu | Tested |
|---|---|---|---|
| Windows 10/11 | `install.bat` | Classic menu, and top-level menu on Windows 11 | Yes, on Windows 11 |
| Linux, KDE Dolphin | `sh linux/install.sh` | Dolphin service menu | Scripts and `.desktop` file only, in WSL Ubuntu; Dolphin not run |
| Linux, GNOME Files | `sh linux/install.sh` | Nautilus script ("Scripts" submenu) | Script logic only, in WSL Ubuntu; Nautilus not run |
| macOS | `sh macos/install.sh` | Finder Quick Action | Not tested: no Mac. XML and the generated shell command checked only |

Uninstall on each platform: `uninstall.bat`, `sh linux/uninstall.sh`, or
`sh macos/uninstall.sh`.

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

Linux (per user, under `~/.local`):

- `~/.local/share/claude-open-with-context-menu/open-with-claude`: helper
  that opens a terminal in the folder and starts claude there.
- `~/.local/share/kio/servicemenus/open-with-claude.desktop`: Dolphin entry.
- `~/.local/share/nautilus/scripts/Open with Claude`: Nautilus script.

Nautilus decodes `%20` in the folder URI with `python3` when it is present.

macOS: `~/Library/Services/Open with Claude.workflow`, a Finder Quick Action
with one shell step. It opens Terminal in the folder. macOS may ask for
permission to control Terminal the first time.

## Checks

- Linux, in WSL Ubuntu 26.04 with a throwaway HOME: install, uninstall, the
  helper's folder/file/no-argument paths, the Nautilus folder, file and
  `%20` URI paths, and the `cd`-then-start quoting were run. A fake terminal
  check ran the helper with `/bin/pwd` in place of claude.
- Linux, Dolphin: `desktop-file-validate` reports that `MimeType` and
  `Actions` are for Application entries only. KDE service menus use these
  keys with `Type=Service`, so the entry is left as is. Not seen in Dolphin.
- macOS: not run. The Quick Action XML was parsed with Python `plistlib` in WSL.
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
- Linux: a folder path containing `"`, `$` or a backslash is not escaped in
  the Dolphin `Exec` line. Untested.
- The top-level entry is unsigned by any public CA. Only this machine trusts
  its certificate.

## License

No license file yet.
