# Brewfile — declarative package list for `brew bundle`.
# Edit freely; the install scripts run `brew bundle --file=Brewfile`.

# --- Languages & runtimes ---------------------------------------------------
brew "go"
brew "node"          # ships npm
brew "python"        # latest stable; provides python3/pip3
brew "rustup-init"   # `rustup-init -y` is run by 02-extras.sh
cask "temurin@25"    # latest LTS (auto-pinned by 01-brew.sh)

# --- DevOps / cloud-native --------------------------------------------------
tap "slp/krun"                   # provides libkrun + krunkit (Podman machine dependencies on macOS)
brew "libepoxy"                  # required by libkrun
brew "libkrun"                   # Apple Hypervisor Framework backend for Podman machine
brew "krunkit"                   # Podman machine driver on macOS (reinstall these three if machine fails to start)
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
brew "sshpass"
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"
cask "font-google-sans-code"        # editor font for VSCodium (terminal keeps JetBrainsMono Nerd Font)

# --- GUI applications -------------------------------------------------------
cask "vscodium"
cask "intellij-idea-ce"   # community edition; swap to "intellij-idea" for ultimate
cask "keystore-explorer"
cask "podman-desktop"
cask "zen-browser"
cask "coteditor"           # Notepad++-equivalent: plain-text editor with auto-save & versions
cask "shottr"              # Greenshot-equivalent: local screenshot tool with annotations (blur/highlight/arrows)
cask "gitup"               # FOSS Git GUI with a live commit/branch graph (GitLab-style network view)
cask "dbeaver-community"   # universal database tool / SQL client (community edition)
