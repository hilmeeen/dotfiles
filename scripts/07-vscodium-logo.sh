#!/usr/bin/env bash
# Swap VSCodium's empty-editor "letterpress" logo (the faded mark shown on a
# blank page) for a custom image. The 4 stock SVGs live inside the app bundle
# and are root-owned, so writing them needs sudo; VSCodium *updates restore the
# originals*, so re-run this after each update.
#
# This only swaps an image asset — it patches no executable code and does NOT
# trigger the "installation appears corrupt" warning. The CSS expects a *.svg,
# so we wrap the PNG in a valid SVG (base64 <image> at OPACITY); same image is
# used for all four theme variants (dark/light/hcDark/hcLight).
#
# Nothing here is committed: the logo is fetched from LOGO_URL on first run and
# the stock SVGs are backed up locally, both under vscodium/ which is gitignored.
#
# Usage:
#   bash scripts/07-vscodium-logo.sh            # install custom logo
#   bash scripts/07-vscodium-logo.sh restore    # restore the stock logo
#   LETTERPRESS_OPACITY=0.5 bash scripts/07-vscodium-logo.sh   # tweak the fade
#   LOGO_URL=https://.../my.png  bash scripts/07-vscodium-logo.sh   # other logo
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LOGO_URL="${LOGO_URL:-https://raw.githubusercontent.com/Aikoyori/ProgrammingVTuberLogos/main/VSCode/VSCode-Thick.png}"
LOGO_SRC="$DOTFILES_DIR/vscodium/letterpress.png"
BACKUP_DIR="$DOTFILES_DIR/vscodium/letterpress-originals"
OPACITY="${LETTERPRESS_OPACITY:-0.3}"

MEDIA_DIR="/Applications/VSCodium.app/Contents/Resources/app/out/media"
VARIANTS=(letterpress-dark.svg letterpress-light.svg letterpress-hcDark.svg letterpress-hcLight.svg)

if [[ ! -d "$MEDIA_DIR" ]]; then
  echo "VSCodium media dir not found ($MEDIA_DIR) — skipping." >&2
  exit 0
fi

# Back up the stock SVGs once. They're world-readable, so copying OUT needs no
# sudo; this gives us a clean source for the restore path.
if [[ ! -d "$BACKUP_DIR" ]]; then
  mkdir -p "$BACKUP_DIR"
  for v in "${VARIANTS[@]}"; do cp "$MEDIA_DIR/$v" "$BACKUP_DIR/$v"; done
  echo "Backed up stock letterpress SVGs to $BACKUP_DIR"
fi

if [[ "${1:-}" == "restore" ]]; then
  if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "No backup at $BACKUP_DIR — nothing to restore." >&2
    exit 1
  fi
  echo "Restoring stock VSCodium logo (needs sudo)..."
  for v in "${VARIANTS[@]}"; do sudo cp "$BACKUP_DIR/$v" "$MEDIA_DIR/$v"; done
  echo "Done. Restart VSCodium (Cmd+Q) to see the original logo."
  exit 0
fi

# Fetch the logo on first run (it isn't committed; vscodium/ is gitignored).
# Delete vscodium/letterpress.png to force a re-download next time.
if [[ ! -f "$LOGO_SRC" ]]; then
  echo "Fetching logo from $LOGO_URL ..."
  mkdir -p "$(dirname "$LOGO_SRC")"
  if ! curl -fL -o "$LOGO_SRC" "$LOGO_URL"; then
    echo "Failed to download logo from $LOGO_URL" >&2
    rm -f "$LOGO_SRC"
    exit 1
  fi
fi

# Read dimensions so the SVG viewBox matches the PNG; the CSS draws it with
# background-size:contain inside a 1:1 box, so aspect ratio is preserved.
W="$(sips -g pixelWidth  "$LOGO_SRC" | awk '/pixelWidth/{print $2}')"
H="$(sips -g pixelHeight "$LOGO_SRC" | awk '/pixelHeight/{print $2}')"

# Build the wrapper SVG (PNG embedded as a base64 data URI at the given opacity).
tmp_svg="$(mktemp)"
trap 'rm -f "$tmp_svg"' EXIT
{
  printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%s" height="%s" viewBox="0 0 %s %s">' "$W" "$H" "$W" "$H"
  printf '<image opacity="%s" width="%s" height="%s" xlink:href="data:image/png;base64,' "$OPACITY" "$W" "$H"
  base64 < "$LOGO_SRC" | tr -d '\n'
  printf '"/></svg>'
} > "$tmp_svg"

echo "Installing custom letterpress logo (opacity $OPACITY, needs sudo)..."
for v in "${VARIANTS[@]}"; do sudo cp "$tmp_svg" "$MEDIA_DIR/$v"; done
echo "Done. Restart VSCodium (Cmd+Q) to see it on a blank editor."
