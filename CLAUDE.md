# CLAUDE.md — dotfiles project guide

macOS (Apple Silicon) dotfiles. Imperative bootstrap — **not** GNU stow. An
ordered set of idempotent scripts installs CLIs/apps and pushes config into
places that can't read from this repo (VSCodium, Terminal.app, CotEditor).

## Layout
- `install.sh` — entrypoint; runs `scripts/00..08` in order, then optional steps.
- `Brewfile` — declarative package list; `brew bundle` installs it (via `01-brew.sh`).
- `scripts/NN-*.sh` — ordered, idempotent install steps (see below).
- `shell/` — `.zshrc`, `starship.toml`, `install-shell.sh` (opt-in shell setup).
- `ghostty/config` — Ghostty terminal config (read in place from repo).
- `vscodium/` — custom empty-editor logo assets for `07-vscodium-logo.sh`.

## Install flow (`install.sh`)
Core steps always run in order:
| Step | Purpose |
|---|---|
| `00-prereqs.sh` | Xcode CLT + Homebrew |
| `01-brew.sh` | `brew bundle` the Brewfile; auto-pins `temurin` LTS |
| `02-extras.sh` | Rust via rustup, Claude Code CLI via npm |
| `03-ghostty-shaders.sh` | Clone ghostty-shaders → `~/.config/ghostty/shaders` |
| `04-vscodium-extensions.sh` | Open VSX extensions + default settings |
| `05-oc-3.11.sh` | OCP 3.11 `oc` client (Linux build, for remote use) |
| `06-app-fonts.sh` | Fonts for VSCodium + Terminal.app |
| `08-coteditor-theme.sh` | Download + set Dracula theme for CotEditor |

Opt-in steps (any order): `./install.sh shell logo`
- `shell` → `shell/install-shell.sh`
- `logo` → `07-vscodium-logo.sh` (needs sudo; reverts on VSCodium update)

> `07` is opt-in only, so it is not in the numeric core sequence.

## Conventions
- **Every script is idempotent** — safe to re-run. Guard with `command -v`,
  `setdefault`-style checks, or "already set" short-circuits before writing.
- **Skip gracefully** when a target app/tool isn't installed (`exit 0`, not error).
- **App settings not in this repo** (VSCodium `settings.json`, CotEditor,
  Terminal.app) are edited in place by scripts, not symlinked/tracked. VSCodium
  settings use `setdefault` so UI changes survive re-runs; delete a key to reset it.
- New install step → add `scripts/NN-name.sh`, `chmod +x`, wire into `install.sh`.
- New package → prefer adding a line to `Brewfile` over a bespoke script.

## Git commits & PRs (overrides global `~/.claude/CLAUDE.md`)
- Add a model-agnostic trailer to commits: `Co-Authored-By: Claude <noreply@anthropic.com>`
  (generic on purpose — the active model varies, so don't pin a version).
- Add the "Generated with Claude Code" footer to PR bodies.
- Work on a feature branch (`feat/...`), push, open a PR — the user merges.
