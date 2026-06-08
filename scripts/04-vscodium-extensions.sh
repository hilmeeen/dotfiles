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
  "dracula-theme.theme-dracula"               # Dracula color theme (Solarized ships built-in)
  "ardonplay.vscode-jetbrains-icon-theme"     # JetBrains file/folder icon theme
  "mechatroner.rainbow-csv"                   # colorize CSV/TSV columns
  "saltcoreyan.json-format-sortcore"          # format + sort JSON keys
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

download_vsix() {
  local ext="$1"
  local publisher="${ext%%.*}"
  local name="${ext#*.}"
  local url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${name}/latest/vspackage"
  local out="$tmpdir/${publisher}.${name}.vsix"

  # Progress goes to stderr so the captured stdout is *only* the .vsix path.
  echo "Fetching $ext from VS Code Marketplace..." >&2
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

# --- Default editor settings ------------------------------------------------
# Solarized Dark / Solarized Light ship built-in with VSCodium, so no extension
# is needed for the color theme — Dracula and the JetBrains icon theme come from
# the Open VSX extensions installed above. Each key is applied with setdefault,
# so anything you later change in the UI (theme, icon theme, layout) survives a
# re-run; delete a key from settings.json to let this script reset it.
VSCODIUM_SETTINGS="$HOME/Library/Application Support/VSCodium/User/settings.json"
mkdir -p "$(dirname "$VSCODIUM_SETTINGS")"
[[ -f "$VSCODIUM_SETTINGS" ]] || echo '{}' > "$VSCODIUM_SETTINGS"

/usr/bin/python3 - "$VSCODIUM_SETTINGS" <<'PY'
import json, sys, pathlib
path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except json.JSONDecodeError:
    print(f"warn: {path} is not valid JSON; leaving settings untouched", file=sys.stderr)
    sys.exit(0)

defaults = {
    "workbench.colorTheme": "Solarized Dark",
    "workbench.iconTheme": "vscode-jetbrains-icon-theme-2023-auto",
    "workbench.sideBar.location": "right",
    "claudeCode.preferredLocation": "panel",
}
changed = False
for key, value in defaults.items():
    if key not in data:
        data[key] = value
        changed = True
        print(f"  set {key} = {value!r}")
    else:
        print(f"  {key} already {data[key]!r}; left as-is.")
if changed:
    path.write_text(json.dumps(data, indent=4) + "\n")
    print(f"VSCodium defaults written: {path}")
else:
    print("VSCodium defaults already present; nothing to change.")
PY
