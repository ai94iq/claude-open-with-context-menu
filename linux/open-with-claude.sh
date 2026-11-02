#!/bin/sh
# Opens Claude Code in a folder, in a new terminal window.
# Usage: open-with-claude.sh [folder]   (default: current folder)
# Installed by linux/install.sh, which replaces @CLAUDE@ with the claude path.

CLAUDE_BIN="@CLAUDE@"

target=${1:-$PWD}
if [ -f "$target" ]; then
    target=$(dirname "$target")
fi

if [ -n "${CLAUDE_OPEN_DRY_RUN:-}" ]; then
    printf '%s\n' "$target"
    exit 0
fi

exec x-terminal-emulator -e sh -c 'cd "$1" && exec "$2"' sh "$target" "$CLAUDE_BIN"
