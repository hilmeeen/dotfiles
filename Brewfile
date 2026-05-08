# Brewfile — declarative package list for `brew bundle`.
# Edit freely; the install scripts run `brew bundle --file=Brewfile`.

# --- Languages & runtimes ---------------------------------------------------
brew "go"
brew "node"          # ships npm
brew "python@3.13"   # latest stable; provides python3/pip3
brew "rustup-init"   # `rustup-init -y` is run by 02-extras.sh
cask "temurin@25"    # Java 25 LTS (released Sep 2025)

# --- DevOps / cloud-native --------------------------------------------------
brew "podman"
brew "kubectl"
brew "helm"
brew "openshift-cli" # provides `oc`
brew "k6"
brew "gh"
brew "jmeter"

# --- Terminal / shell -------------------------------------------------------
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf"
brew "git"
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"

# --- GUI applications -------------------------------------------------------
cask "vscodium"
cask "intellij-idea-ce"   # community edition; swap to "intellij-idea" for ultimate
cask "keystore-explorer"
cask "podman-desktop"
cask "zen-browser"
cask "coteditor"           # Notepad++-equivalent: plain-text editor with auto-save & versions
cask "shottr"              # Greenshot-equivalent: local screenshot tool with annotations (blur/highlight/arrows)
