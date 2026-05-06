#!/usr/bin/env bash
# Install everything declared in the Brewfile.
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

brew bundle --file="$DOTFILES_DIR/Brewfile"
