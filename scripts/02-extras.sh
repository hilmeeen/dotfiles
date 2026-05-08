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
# (e.g. legacy OpenShift `oc` clients) at near-native speed via Rosetta.
if [[ "$(uname -m)" == "arm64" ]]; then
  if [[ ! -f /Library/Apple/usr/share/rosetta/rosetta ]]; then
    echo "Installing Rosetta 2 (will prompt for sudo password)..."
    sudo softwareupdate --install-rosetta --agree-to-license
  fi

  if ! podman machine inspect podman-machine-default >/dev/null 2>&1; then
    # Modern Podman auto-uses Rosetta for amd64 emulation when Rosetta is
    # installed on the host — the old `--rosetta` flag is no longer needed
    # (and is removed in Podman 5.x).
    echo "Initializing podman machine..."
    podman machine init
  fi

  state="$(podman machine inspect podman-machine-default --format '{{.State}}' 2>/dev/null || echo '')"
  if [[ "$state" != "running" ]]; then
    echo "Starting podman machine..."
    podman machine start
  fi
fi
