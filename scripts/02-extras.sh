#!/usr/bin/env bash
# Install things that don't fit cleanly in the Brewfile:
#   - Rust toolchain via rustup
#   - Claude Code CLI via npm
#   - Rosetta 2 + podman machine (linux/amd64 cross-arch via Rosetta)
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

# --- Rust toolchain ---------------------------------------------------------
if ! command -v rustc >/dev/null 2>&1; then
  echo "Initializing rustup with stable toolchain..."
  rustup-init -y --default-toolchain stable --no-modify-path
fi

# --- Claude Code CLI --------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

# --- Rosetta 2 + podman machine (for linux/amd64 cross-arch) ---------------
# Lets us build linux/amd64 images and run amd64-only Linux binaries
# (e.g. older oc CLI for OCP 3.6) at near-native speed via Rosetta.
if [[ "$(uname -m)" == "arm64" ]]; then
  if [[ ! -f /Library/Apple/usr/share/rosetta/rosetta ]]; then
    echo "Installing Rosetta 2 (will prompt for sudo password)..."
    sudo softwareupdate --install-rosetta --agree-to-license
  fi

  if ! podman machine inspect podman-machine-default >/dev/null 2>&1; then
    echo "Initializing podman machine with Rosetta backend..."
    podman machine init --rosetta
  fi

  state="$(podman machine inspect podman-machine-default --format '{{.State}}' 2>/dev/null || echo '')"
  if [[ "$state" != "running" ]]; then
    echo "Starting podman machine..."
    podman machine start
  fi
fi
