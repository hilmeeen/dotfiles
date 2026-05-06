#!/usr/bin/env bash
# Clone hackr-sh/ghostty-shaders into ~/.config/ghostty/shaders and link config.
set -euo pipefail

GHOSTTY_DIR="$HOME/.config/ghostty"
SHADERS_DIR="$GHOSTTY_DIR/shaders"
SHADERS_REPO="https://github.com/hackr-sh/ghostty-shaders.git"

mkdir -p "$GHOSTTY_DIR"

# Clone shaders repo (or pull if already there).
if [[ -d "$SHADERS_DIR/.git" ]]; then
  echo "Updating existing ghostty-shaders clone..."
  git -C "$SHADERS_DIR" pull --ff-only
else
  echo "Cloning ghostty-shaders into $SHADERS_DIR..."
  rm -rf "$SHADERS_DIR"
  git clone --depth=1 "$SHADERS_REPO" "$SHADERS_DIR"
fi

# Sanity-check that the shaders we reference in the config actually exist.
for f in retro-terminal.glsl tft.glsl; do
  if [[ ! -f "$SHADERS_DIR/$f" ]]; then
    echo "warning: $SHADERS_DIR/$f not found — did the upstream repo rename it?" >&2
  fi
done

# Link our managed config file.
CONFIG_SRC="$DOTFILES_DIR/ghostty/config"
CONFIG_DST="$GHOSTTY_DIR/config"
if [[ -e "$CONFIG_DST" && ! -L "$CONFIG_DST" ]]; then
  echo "Backing up existing $CONFIG_DST -> $CONFIG_DST.bak"
  mv "$CONFIG_DST" "$CONFIG_DST.bak"
fi
ln -sfn "$CONFIG_SRC" "$CONFIG_DST"
echo "Linked $CONFIG_DST -> $CONFIG_SRC"
