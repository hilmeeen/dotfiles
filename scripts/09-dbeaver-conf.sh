#!/usr/bin/env bash
# Cap DBeaver's JVM max heap via the bundle's dbeaver.ini.
#
# DBeaver is Eclipse-based: VM args live in Contents/Eclipse/dbeaver.ini, and
# there is NO user-level override file (unlike SQL Developer's product.conf).
# So this edits the in-bundle ini, which means it RESETS on every
# `brew upgrade --cask dbeaver-community` — just re-run this script (or
# ./install.sh) afterwards to re-apply. The default ini ships with ~2048m.
#
# Idempotent: if -Xmx already equals our target it's left alone; an existing
# -Xmx line is rewritten; if absent it's appended after -vmargs.
set -euo pipefail

XMX="1024m"   # max heap; lighter than the bundled ~2048m default

INI=""
for candidate in \
  "/Applications/DBeaver.app/Contents/Eclipse/dbeaver.ini" \
  "$HOME/Applications/DBeaver.app/Contents/Eclipse/dbeaver.ini"; do
  [[ -f "$candidate" ]] && INI="$candidate" && break
done

if [[ -z "$INI" ]]; then
  echo "DBeaver.app not found — install it (brew bundle) then re-run." >&2
  exit 0
fi

/usr/bin/python3 - "$INI" "$XMX" <<'PY'
import sys, pathlib
path, xmx = pathlib.Path(sys.argv[1]), sys.argv[2]
target = f"-Xmx{xmx}"
lines = path.read_text().splitlines()

xmx_idx = next((i for i, l in enumerate(lines) if l.strip().startswith("-Xmx")), None)
if xmx_idx is not None:
    if lines[xmx_idx].strip() == target:
        print(f"  {target} already set in {path} — left as-is.")
        sys.exit(0)
    old = lines[xmx_idx].strip()
    lines[xmx_idx] = target
    print(f"  changed {old} -> {target} in {path}")
else:
    try:
        ins = lines.index("-vmargs") + 1
    except ValueError:
        ins = len(lines)
    lines.insert(ins, target)
    print(f"  added {target} to {path}")

path.write_text("\n".join(lines) + "\n")
PY
