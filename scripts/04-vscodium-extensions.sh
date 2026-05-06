#!/usr/bin/env bash
# VSCodium uses Open VSX, which doesn't carry the Claude Code extension.
# This script sideloads it (and any others listed below) from the VS Code
# Marketplace API as .vsix files.
set -euo pipefail

if ! command -v codium >/dev/null 2>&1; then
  echo "codium not on PATH — skipping extension install." >&2
  exit 0
fi

# Extensions to sideload from VS Code Marketplace, format: publisher.name
MARKETPLACE_EXTS=(
  "Anthropic.claude-code"
)

# Extensions available on Open VSX (installed normally by codium).
OPENVSX_EXTS=(
  # add any here, e.g. "golang.go"
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

download_vsix() {
  local ext="$1"
  local publisher="${ext%%.*}"
  local name="${ext#*.}"
  local url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${name}/latest/vspackage"
  local out="$tmpdir/${publisher}.${name}.vsix"

  echo "Fetching $ext from VS Code Marketplace..."
  # Marketplace serves gzipped .vsix; -L follows redirects, --compressed handles gzip.
  if ! curl -fL --compressed -o "$out" "$url"; then
    echo "  failed to download $ext — install it manually." >&2
    return 1
  fi
  echo "$out"
}

for ext in "${MARKETPLACE_EXTS[@]}"; do
  if vsix_path="$(download_vsix "$ext")"; then
    codium --install-extension "$vsix_path" || \
      echo "  codium refused $ext — you may need to install manually." >&2
  fi
done

for ext in "${OPENVSX_EXTS[@]}"; do
  codium --install-extension "$ext" || true
done
