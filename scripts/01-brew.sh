#!/usr/bin/env bash
# Install everything declared in the Brewfile.
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

# Pin Temurin to the newest Java LTS. Adoptium ships a feature release every 6
# months but only LTS lines get long-term support, and Homebrew has no rolling
# "latest LTS" cask. So ask the Adoptium API for the most recent LTS and rewrite
# the Brewfile's temurin line to match (idempotent: a no-op when already
# current). On any failure we keep the existing pin and carry on.
lts="$(curl -fsS --max-time 10 https://api.adoptium.net/v3/info/available_releases 2>/dev/null \
  | grep -oE '"most_recent_lts": *[0-9]+' | grep -oE '[0-9]+' || true)"

if [[ -n "$lts" ]] && brew info --cask "temurin@${lts}" >/dev/null 2>&1; then
  if ! grep -q "^cask \"temurin@${lts}\"" "$DOTFILES_DIR/Brewfile"; then
    echo "Updating Brewfile: Temurin -> @${lts} (latest LTS)"
    sed -i '' -E "s|^cask \"temurin@[0-9]+\".*|cask \"temurin@${lts}\"    # latest LTS (auto-pinned by 01-brew.sh)|" "$DOTFILES_DIR/Brewfile"
  fi
else
  echo "Could not resolve latest Temurin LTS (or its cask is unavailable); keeping existing Brewfile pin." >&2
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"
