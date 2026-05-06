#!/usr/bin/env bash
# Optional: install zsh config (.zshrc) and starship prompt config.
# Run separately from the main bootstrap so the shell setup stays opt-in.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SHELL_DIR="$DOTFILES_DIR/shell"

eval "$(/opt/homebrew/bin/brew shellenv)"

# Make sure prerequisites are present (the Brewfile covers these, but allow
# running this script standalone).
for pkg in starship zsh-autosuggestions zsh-syntax-highlighting fzf; do
  if ! brew list --formula "$pkg" >/dev/null 2>&1; then
    brew install "$pkg"
  fi
done

link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "Backing up $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "Linked $dst -> $src"
}

link "$SHELL_DIR/.zshrc"        "$HOME/.zshrc"
link "$SHELL_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "Shell setup complete. Open a new terminal."
