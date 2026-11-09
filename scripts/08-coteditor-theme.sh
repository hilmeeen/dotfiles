#!/usr/bin/env bash
# Install the Dracula theme for CotEditor and set it as the default.
# Source: https://github.com/dracula/coteditor
# Idempotent — safe to re-run. Skips gracefully if CotEditor is not installed.
set -euo pipefail

THEME_NAME="Dracula"
THEME_URL="https://raw.githubusercontent.com/dracula/coteditor/master/Dracula.cottheme"
THEME_DIR="$HOME/Library/Application Support/CotEditor/Themes"

if ! command -v coteditor >/dev/null 2>&1 && [[ ! -d "$HOME/Applications/CotEditor.app" ]] && [[ ! -d "/Applications/CotEditor.app" ]]; then
  echo "CotEditor not found — skipping theme install." >&2
  exit 0
fi

mkdir -p "$THEME_DIR"

THEME_FILE="$THEME_DIR/$THEME_NAME.cottheme"
if [[ -f "$THEME_FILE" ]]; then
  echo "Dracula.cottheme already present; skipping download."
else
  echo "Downloading Dracula theme for CotEditor..."
  curl -fsSL "$THEME_URL" -o "$THEME_FILE"
  echo "  saved to $THEME_FILE"
fi

current="$(defaults read com.coteditor.CotEditor theme 2>/dev/null || true)"
if [[ "$current" == "$THEME_NAME" ]]; then
  echo "CotEditor theme already set to $THEME_NAME."
else
  defaults write com.coteditor.CotEditor theme "$THEME_NAME"
  echo "CotEditor default theme set to $THEME_NAME."
fi
