#!/usr/bin/env bash
# Apply fonts to apps that don't read from this repo:
#   - VSCodium editor  → Google Sans Code (clean monospaced coding font)
#   - VSCodium terminal → JetBrainsMono Nerd Font Mono (needed for Nerd Font glyphs)
#   - macOS Terminal.app (Basic profile) → JetBrainsMono Nerd Font Mono
#
# Ghostty already picks the font up via ghostty/config in this repo, so it's
# not touched here.
# Prereqs: cask "font-google-sans-code" and cask "font-jetbrains-mono-nerd-font" (Brewfile).
# Idempotent — safe to re-run.
set -euo pipefail

EDITOR_FONT="Google Sans Code"          # VSCodium code editor
TERMINAL_FONT="JetBrainsMono Nerd Font Mono"  # VSCodium + Terminal.app (Nerd Font glyphs)
TERMINAL_FONT_POSTSCRIPT="JetBrainsMonoNFM-Regular"  # PostScript name (Terminal.app needs this)
FONT_SIZE=12

# Bail early if JetBrainsMono Nerd Font is missing — terminal would break.
jetbrains_file="JetBrainsMonoNerdFontMono-Regular.ttf"
if [[ ! -f "$HOME/Library/Fonts/$jetbrains_file" && ! -f "/Library/Fonts/$jetbrains_file" ]]; then
  echo "JetBrains Mono Nerd Font not found in ~/Library/Fonts or /Library/Fonts." >&2
  echo "Run brew bundle first (cask font-jetbrains-mono-nerd-font), then re-run." >&2
  exit 0
fi

# Warn (but don't bail) if Google Sans Code is missing — editor falls back gracefully.
google_sans_file="GoogleSansCode[wght].ttf"
if [[ ! -f "$HOME/Library/Fonts/$google_sans_file" && ! -f "/Library/Fonts/$google_sans_file" ]]; then
  echo "warn: Google Sans Code not found — editor will fall back to JetBrainsMono." >&2
  echo "      Run brew bundle first (cask font-google-sans-code) to install it." >&2
fi

# --- VSCodium ---------------------------------------------------------------
VSCODIUM_SETTINGS="$HOME/Library/Application Support/VSCodium/User/settings.json"
VSCODIUM_DIR="$(dirname "$VSCODIUM_SETTINGS")"

if [[ -d "$VSCODIUM_DIR" ]] || command -v codium >/dev/null 2>&1; then
  mkdir -p "$VSCODIUM_DIR"
  [[ -f "$VSCODIUM_SETTINGS" ]] || echo '{}' > "$VSCODIUM_SETTINGS"

  /usr/bin/python3 - "$VSCODIUM_SETTINGS" "$EDITOR_FONT" "$TERMINAL_FONT" <<'PY'
import json, sys, pathlib
path, editor_font, terminal_font = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
try:
    data = json.loads(path.read_text())
except json.JSONDecodeError:
    print(f"warn: {path} is not valid JSON; leaving untouched", file=sys.stderr)
    sys.exit(0)
# Editor: Google Sans Code first, JetBrainsMono as fallback, then system fallbacks
data["editor.fontFamily"] = f"'{editor_font}', {terminal_font}, Menlo, Monaco, 'Courier New', monospace"
data.setdefault("editor.fontLigatures", True)   # respect user override if already set
# Terminal keeps JetBrainsMono Nerd Font for glyph/icon support (Starship, etc.)
data["terminal.integrated.fontFamily"] = terminal_font
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
