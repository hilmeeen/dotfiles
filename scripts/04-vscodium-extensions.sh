#!/usr/bin/env bash
# Installs VSCodium extensions from the Open VSX registry (the registry VSCodium
# ships with). Open VSX now carries the Claude Code extension, including
# platform-specific builds, and `codium --install-extension <id>` picks the
# build matching the host os/arch automatically — so every extension installs
# the same way by id.
set -euo pipefail

if ! command -v codium >/dev/null 2>&1; then
  echo "codium not on PATH — skipping extension install." >&2
  exit 0
fi

# Extensions to install from Open VSX, format: publisher.name
OPENVSX_EXTS=(
  "Anthropic.claude-code"                     # Claude Code (platform-specific; Open VSX serves the host build)
  "dracula-theme.theme-dracula"               # Dracula color theme (Solarized ships built-in)
  "ardonplay.vscode-jetbrains-icon-theme"     # JetBrains file/folder icon theme
  "mechatroner.rainbow-csv"                   # colorize CSV/TSV columns
  "saltcoreyan.json-format-sortcore"          # format + sort JSON keys
  "mhutchie.git-graph"                        # GitLab-style repository/commit graph in-editor
  "cweijan.dbclient-jdbc"                     # SQL Developer-like DB client (Oracle/MySQL/PG); uses JDBC (needs JRE — temurin@25)
)

for ext in "${OPENVSX_EXTS[@]}"; do
  codium --install-extension "$ext" || \
    echo "  codium refused $ext — you may need to install manually." >&2
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
