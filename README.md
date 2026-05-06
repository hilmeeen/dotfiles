# dotfiles — macOS (Apple Silicon)

Bootstrap a fresh macOS M-series machine with the CLIs, GUI apps, terminal,
and (optionally) shell prompt I use for work.

## Quick start

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
chmod +x install.sh scripts/*.sh shell/install-shell.sh
./install.sh           # core install
./install.sh shell     # core install + zsh/starship setup
```

The shell setup is intentionally a separate step so you can opt out.

## What gets installed

### Languages & runtimes
- Java 25 LTS (Eclipse Temurin)
- Go
- Python 3.13 (`python`/`pip` aliased to `python3`/`pip3` via PATH)
- Node + npm
- Rust (via rustup, stable toolchain)

### CLIs
- claude (Claude Code, via npm)
- gh, git
- kubectl, helm, oc (OpenShift CLI), podman
- k6, jmeter
- fzf

### GUI apps
- Ghostty (terminal, with shaders)
- VSCodium (with Claude Code extension sideloaded from VS Code Marketplace)
- IntelliJ IDEA Community
- KeyStore Explorer
- Podman Desktop
- Zen Browser
- CotEditor (Notepad++ replacement — plain-text editor with macOS auto-save & version history, so unsaved windows persist across crashes/restarts)

### Terminal look
- Ghostty + JetBrains Mono Nerd Font
- Stacked shaders: `retro-terminal.glsl` + `tft.glsl` from
  [hackr-sh/ghostty-shaders](https://github.com/hackr-sh/ghostty-shaders),
  cloned into `~/.config/ghostty/shaders`.
- Edit shader stack in [`ghostty/config`](ghostty/config) — multiple
  `custom-shader =` lines compose, each running on the previous one's output.

### Optional shell (run with `./install.sh shell`)
- zsh + starship prompt
- zsh-autosuggestions, zsh-syntax-highlighting, fzf keybindings
- Symlinks `~/.zshrc` and `~/.config/starship.toml` to files in [`shell/`](shell/)

## Structure

```
.
├── install.sh                 # entrypoint
├── Brewfile                   # all brew formulae & casks
├── scripts/
│   ├── 00-prereqs.sh          # Xcode CLT + Homebrew
│   ├── 01-brew.sh             # brew bundle
│   ├── 02-extras.sh           # rustup-init, claude code via npm
│   ├── 03-ghostty-shaders.sh  # clone shaders, link config
│   └── 04-vscodium-extensions.sh  # sideload Claude Code .vsix
├── ghostty/
│   └── config                 # symlinked into ~/.config/ghostty/
└── shell/                     # opt-in
    ├── install-shell.sh
    ├── .zshrc
    └── starship.toml
```

## Notes & caveats

- **VSCodium + Claude Code extension.** VSCodium pulls extensions from Open
  VSX, where the official Claude Code extension isn't published. The
  [`04-vscodium-extensions.sh`](scripts/04-vscodium-extensions.sh) script
  sideloads it from the VS Code Marketplace API as a `.vsix`. Re-run that
  script periodically to pick up updates, since VSCodium's auto-update
  doesn't see Marketplace-only extensions.
- **IntelliJ edition.** [`Brewfile`](Brewfile) installs Community Edition
  (`intellij-idea-ce`). Swap to `intellij-idea` for Ultimate.
- **Java version.** Pinned to `temurin@25` (Java 25 LTS, released Sep 2025).
  Bump in the Brewfile when the next LTS lands.
- **Editing the shader stack.** To try other looks (e.g. `bettercrt`, `bloom`,
  `crt`, `cineShader-Lava`), add `custom-shader =` lines in
  [`ghostty/config`](ghostty/config). All shaders from the upstream repo are
  already cloned into `~/.config/ghostty/shaders/`.
- **Re-running.** All scripts are idempotent — safe to run again to pick up
  Brewfile changes or new dotfile updates.
