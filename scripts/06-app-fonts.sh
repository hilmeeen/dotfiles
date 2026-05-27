#!/usr/bin/env bash
# Apply JetBrains Mono Nerd Font to apps that don't read from this repo:
#   - VSCodium (editor + integrated terminal)
#   - macOS Terminal.app (Basic profile)
#
# Ghostty already picks the font up via ghostty/config in this repo, so it's
# not touched here. Prereq: cask "font-jetbrains-mono-nerd-font" (Brewfile).
# Idempotent — safe to re-run.
set -euo pipefail

FONT_FAMILY="JetBrainsMono Nerd Font Mono"
FONT_POSTSCRIPT="JetBrainsMonoNFM-Regular"  # PostScript name (Terminal.app needs this form)
FONT_SIZE=12

# Bail early if the font isn't actually installed — avoids pointing apps at
# a font that won't render. Check user and system font dirs independently;
# `ls a b` would fail on the first missing arg even if the other exists.
font_file="JetBrainsMonoNerdFontMono-Regular.ttf"
if [[ ! -f "$HOME/Library/Fonts/$font_file" && ! -f "/Library/Fonts/$font_file" ]]; then
  echo "JetBrains Mono Nerd Font not found in ~/Library/Fonts or /Library/Fonts." >&2
  echo "Run brew bundle first (cask font-jetbrains-mono-nerd-font), then re-run." >&2
  exit 0
fi

# --- VSCodium ---------------------------------------------------------------
VSCODIUM_SETTINGS="$HOME/Library/Application Support/VSCodium/User/settings.json"
VSCODIUM_DIR="$(dirname "$VSCODIUM_SETTINGS")"

if [[ -d "$VSCODIUM_DIR" ]] || command -v codium >/dev/null 2>&1; then
  mkdir -p "$VSCODIUM_DIR"
  [[ -f "$VSCODIUM_SETTINGS" ]] || echo '{}' > "$VSCODIUM_SETTINGS"

  /usr/bin/python3 - "$VSCODIUM_SETTINGS" "$FONT_FAMILY" <<'PY'
import json, sys, pathlib
path, font = pathlib.Path(sys.argv[1]), sys.argv[2]
try:
    data = json.loads(path.read_text())
except json.JSONDecodeError:
    print(f"warn: {path} is not valid JSON; leaving untouched", file=sys.stderr)
    sys.exit(0)
data["editor.fontFamily"] = f"{font}, Menlo, Monaco, 'Courier New', monospace"
data.setdefault("editor.fontLigatures", True)   # respect user override if already set
data["terminal.integrated.fontFamily"] = font
path.write_text(json.dumps(data, indent=4) + "\n")
print(f"VSCodium settings updated: {path}")
PY
else
  echo "VSCodium not installed and no settings dir — skipping."
fi

# --- macOS Terminal.app (Basic profile) -------------------------------------
# Terminal.app stores font as an NSArchive blob in its plist; setting it via
# AppleScript is the only sane path. This will briefly launch Terminal.app.
if osascript -e 'tell application "System Events" to exists application process "Finder"' >/dev/null 2>&1; then
  current="$(osascript -e 'tell application "Terminal" to get font name of settings set "Basic"' 2>/dev/null || true)"
  if [[ "$current" != "$FONT_POSTSCRIPT" ]]; then
    echo "Setting Terminal.app Basic profile font to $FONT_FAMILY..."
    osascript <<APPLESCRIPT
tell application "Terminal"
    set font name of settings set "Basic" to "$FONT_POSTSCRIPT"
    set font size of settings set "Basic" to $FONT_SIZE
end tell
APPLESCRIPT
  else
    echo "Terminal.app Basic profile already on $FONT_POSTSCRIPT."
  fi
fi
