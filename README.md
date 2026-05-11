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
- Shottr (Greenshot/Lightshot replacement — local-only screenshot tool with blur/highlight/arrow/line/text annotations, scrolling capture, OCR; no cloud, no account)

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

## Running linux/amd64 on Apple Silicon

The bootstrap installs Rosetta 2 and initializes a podman machine. Modern
Podman on Apple Silicon automatically uses Rosetta for linux/amd64 emulation
whenever Rosetta is installed on the host — no `--rosetta` flag required (it's
removed in Podman 5.x). Cross-arch work runs at near-native speed, no QEMU.

**Build an amd64 image:**

```bash
podman build --platform=linux/amd64 -t myimage:amd64 .
```

**Run an amd64-only binary** (e.g. the OCP 3.11 `oc` CLI — no native macOS
arm64 build exists) inside an amd64 Linux container. The bootstrap script
[`05-oc-3.11.sh`](scripts/05-oc-3.11.sh) auto-downloads the binary to
`$HOME/bin-linux-amd64/oc-3.11` (a dedicated folder kept *off* macOS `$PATH`
so you never accidentally exec a Linux ELF on the host) and creates a
relative symlink `oc -> oc-3.11` next to it, so commands can just say `oc`.
Bumping versions later is a one-line re-point of the symlink — no call sites
change:

```bash
podman run --platform=linux/amd64 --rm -it \
  -v "$HOME/bin-linux-amd64:/host-bin:ro" \
  registry.access.redhat.com/ubi9-minimal \
  /host-bin/oc version --client
```

The symlink target is a bare filename (`oc-3.11`), not an absolute path, so
it resolves correctly both on the host (`$HOME/bin-linux-amd64/oc`) and
inside the container (`/host-bin/oc`) even though the parent dir differs.

Drop any other Linux-only binaries into `$HOME/bin-linux-amd64/` and they'll
be available at `/host-bin/<name>` inside the container.

**One-off amd64 shell:**

```bash
podman run --platform=linux/amd64 --rm -it registry.access.redhat.com/ubi9-minimal bash
```

**Long-lived amd64 shell** (keep an idle container around so `podman exec` is
instant — useful when you have several Linux-only binaries in `~/bin-linux-amd64`
and want to bounce in and out without re-pulling images):

```bash
# Start once. --replace makes this re-runnable; --restart=unless-stopped
# survives podman machine reboots. `sleep infinity` keeps the container idle.
# --user 1000:1000 drops root inside the container; HOME=/tmp gives bash a
# writable home since UID 1000 has no /etc/passwd entry in ubi9-minimal.
podman run -d --replace --name linux-amd64-box \
  --platform=linux/amd64 \
  --restart=unless-stopped \
  --user 1000:1000 \
  -v "$HOME/bin-linux-amd64:/host-bin:ro" \
  -e HOME=/tmp \
  -e PATH=/host-bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  registry.access.redhat.com/ubi9-minimal \
  sleep infinity

# Enter an interactive shell.
podman exec -it linux-amd64-box bash

# Or run a single command without entering.
podman exec -it linux-amd64-box oc version --client

# Pause / resume / delete.
podman stop linux-amd64-box
podman start linux-amd64-box
podman rm -f linux-amd64-box
```

Bind mounts like `/host-bin` persist on macOS, but anything you install inside
the container root fs (`dnf install …`, `pip install …`) is lost on `podman rm`.
For persistent root-fs state, either `podman commit linux-amd64-box my-linux-amd64-box:latest`
after setup, or write a Containerfile.

Since the container runs as UID 1000, system installs (`dnf`, `microdnf`) and
anything else needing root must shell in as root explicitly:

```bash
podman exec -u 0 -it linux-amd64-box microdnf install -y jq
```

If you ever need a persistent Linux dev environment (long-lived services,
editing code from inside Linux), reach for `lima` instead — but for build
and CLI work, podman+Rosetta is enough.

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
