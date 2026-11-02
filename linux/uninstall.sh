#!/bin/sh
# Removes the helper, the Dolphin service menu and the Nautilus script. Run: sh linux/uninstall.sh

rm -f "$HOME/.local/share/kio/servicemenus/open-with-claude.desktop"
rm -f "$HOME/.local/share/nautilus/scripts/Open with Claude"
rm -rf "$HOME/.local/share/claude-open-with-context-menu"

echo "Removed Open with Claude from Dolphin and Nautilus (if it was installed)."
