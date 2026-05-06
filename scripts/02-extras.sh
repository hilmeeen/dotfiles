#!/usr/bin/env bash
# Install things that don't fit cleanly in the Brewfile:
#   - Rust toolchain via rustup
#   - Claude Code CLI via npm
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
