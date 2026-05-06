#!/usr/bin/env bash
# Install Xcode Command Line Tools and Homebrew.
set -euo pipefail

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools (a GUI prompt will appear)..."
  xcode-select --install || true
  echo "Re-run this script once the CLT installer finishes."
  # Wait for CLT to be present.
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in this shell session (Apple Silicon path).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew update
