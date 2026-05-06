#!/usr/bin/env bash
# macOS M-series dotfiles bootstrap.
# Usage:
#   ./install.sh         # core install (CLIs, apps, ghostty, vscodium ext)
#   ./install.sh shell   # also run optional zsh + starship setup
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This bootstrap targets macOS. Detected: $(uname -s)" >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "Warning: not running on Apple Silicon (uname -m = $(uname -m))." >&2
  echo "Scripts assume /opt/homebrew. Continuing anyway." >&2
fi

run_step() {
  local script="$1"
  echo
  echo "==> $script"
  bash "$DOTFILES_DIR/scripts/$script"
}

run_step 00-prereqs.sh
run_step 01-brew.sh
run_step 02-extras.sh
run_step 03-ghostty-shaders.sh
run_step 04-vscodium-extensions.sh

if [[ "${1:-}" == "shell" ]]; then
  echo
  echo "==> optional shell setup"
  bash "$DOTFILES_DIR/shell/install-shell.sh"
fi

echo
echo "Done. Open a new terminal session to pick up PATH changes."
echo "If you skipped shell setup, run: $DOTFILES_DIR/shell/install-shell.sh"
