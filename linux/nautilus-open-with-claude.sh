#!/bin/sh
# GNOME Files (Nautilus) script: "Open with Claude".
# Nautilus sets NAUTILUS_SCRIPT_SELECTED_FILE_PATHS for a selection, otherwise
# NAUTILUS_SCRIPT_CURRENT_URI for the folder being viewed.
# Installed by linux/install.sh, which replaces @HELPER@ with the helper path.

HELPER="@HELPER@"

if [ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    target=$(printf '%s\n' "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n 1)
else
    uri=$NAUTILUS_SCRIPT_CURRENT_URI
    case "$uri" in
        file://*) uri=${uri#file://} ;;
    esac
    # Decode %20 and friends. Without python3 the encoded path is used as is.
    if command -v python3 >/dev/null 2>&1; then
        target=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))' "$uri")
    else
        target=$uri
    fi
fi

exec "$HELPER" "$target"
