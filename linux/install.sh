#!/bin/sh
# Adds "Open with Claude" to the Dolphin (KDE) and Nautilus (GNOME) right-click menus.
# Per user, no root. Run: sh linux/install.sh
# Set CLAUDE_BIN=/path/to/claude if claude is not on PATH or in ~/.local/bin.

set -eu

HERE=$(cd "$(dirname "$0")" && pwd)

CLAUDE_BIN=${CLAUDE_BIN:-$(command -v claude 2>/dev/null || true)}
if [ -z "$CLAUDE_BIN" ] && [ -x "$HOME/.local/bin/claude" ]; then
    CLAUDE_BIN="$HOME/.local/bin/claude"
fi
if [ -z "$CLAUDE_BIN" ] || [ ! -x "$CLAUDE_BIN" ]; then
    echo "claude not found. Install Claude Code or set CLAUDE_BIN=/path/to/claude." >&2
    exit 1
fi

# Escape a value for use as a sed replacement.
esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

data_dir="$HOME/.local/share/claude-open-with-context-menu"
helper="$data_dir/open-with-claude"
dolphin_dir="$HOME/.local/share/kio/servicemenus"
nautilus_dir="$HOME/.local/share/nautilus/scripts"

mkdir -p "$data_dir" "$dolphin_dir" "$nautilus_dir"

sed "s|@CLAUDE@|$(esc "$CLAUDE_BIN")|g" "$HERE/open-with-claude.sh" > "$helper"
chmod 755 "$helper"

sed "s|@HELPER@|$(esc "$helper")|g" "$HERE/open-with-claude.desktop.in" > "$dolphin_dir/open-with-claude.desktop"
chmod 644 "$dolphin_dir/open-with-claude.desktop"

sed "s|@HELPER@|$(esc "$helper")|g" "$HERE/nautilus-open-with-claude.sh" > "$nautilus_dir/Open with Claude"
chmod 755 "$nautilus_dir/Open with Claude"

if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$dolphin_dir/open-with-claude.desktop" || true
fi

echo "Installed helper, Dolphin service menu and Nautilus script for: $CLAUDE_BIN"
echo "Log out and back in (or restart Dolphin and run 'nautilus -q') to see the entries."
