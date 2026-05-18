# Managed by dotfiles. Symlinked from $DOTFILES_DIR/shell/.zshrc.

# Homebrew (Apple Silicon).
eval "$(/opt/homebrew/bin/brew shellenv)"

# History.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# Completion.
autoload -Uz compinit && compinit -i

# Plugins.
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null

# fzf keybindings + completion.
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Toolchain PATHs.
export PATH="$HOME/.cargo/bin:$PATH"               # rust
export PATH="$(brew --prefix)/opt/python@3.13/libexec/bin:$PATH"  # `python` -> python3, `pip` -> pip3
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Java (Temurin 25 LTS).
if [[ -d "/Library/Java/JavaVirtualMachines/temurin-25.jdk" ]]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# Aliases.
alias ll='ls -lah'
alias k='kubectl'
alias g='git'

# Custom functions and aliases.
for f in "$HOME/.zshrc.d/"*.zsh(N); do source "$f"; done

# Starship prompt (last so it overrides any earlier PROMPT settings).
eval "$(starship init zsh)"
