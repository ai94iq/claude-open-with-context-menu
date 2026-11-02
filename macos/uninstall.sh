#!/bin/sh
# Removes the Finder Quick Action. Run: sh macos/uninstall.sh
# NOT TESTED on macOS.

rm -rf "$HOME/Library/Services/Open with Claude.workflow"

echo "Removed the Open with Claude Quick Action (if it was installed)."
