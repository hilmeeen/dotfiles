#!/usr/bin/env bash
# macOS M-series dotfiles bootstrap.
# Usage:
#   ./install.sh              # core install (CLIs, apps, ghostty, vscodium ext)
#   ./install.sh shell        # + optional zsh + starship setup
#   ./install.sh logo         # + optional custom VSCodium blank-page logo (sudo)
#   ./install.sh shell logo   # combine optional steps in any order
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
run_step 05-oc-3.11.sh
run_step 06-app-fonts.sh
run_step 08-coteditor-theme.sh

# Optional opt-in steps, runnable in any order: ./install.sh shell logo
for opt in "$@"; do
  case "$opt" in
    shell)
      echo
      echo "==> optional shell setup"
      bash "$DOTFILES_DIR/shell/install-shell.sh"
      ;;
    logo)
      echo
      echo "==> optional VSCodium logo (needs sudo; reverts on VSCodium update)"
      # Non-fatal: a declined sudo shouldn't abort an otherwise-done bootstrap.
      bash "$DOTFILES_DIR/scripts/07-vscodium-logo.sh" ||
        echo "VSCodium logo step skipped (sudo declined or failed) — continuing." >&2
      ;;
    *)
      echo "Unknown option '$opt' (known: shell, logo)" >&2
      ;;
  esac
done

echo
echo "Done. Open a new terminal session to pick up PATH changes."
echo "If you skipped shell setup, run: $DOTFILES_DIR/shell/install-shell.sh"
echo "Custom VSCodium logo (opt-in): bash $DOTFILES_DIR/scripts/07-vscodium-logo.sh"
