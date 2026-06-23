#!/usr/bin/env bash
# Cap SQL Developer's JVM max heap via the user-level product.conf.
#
# SQL Developer does NOT auto-size heap from your RAM — ide.conf (inside the
# app bundle) hardcodes `Add64VMOption -Xmx2G`. product.conf is read *after*
# ide.conf, is user-owned, and survives app reinstalls/upgrades, so it's the
# right place for an override. The version lives in the path
# (~/.sqldeveloper/<version>/product.conf), so we glob every version dir.
#
# Idempotent: if an active `AddVMOption -Xmx...` already exists it's left as-is
# (respects a manual tweak); otherwise our line is appended.
set -euo pipefail

XMX="1g"   # max heap; lighter than the bundled 2G default

shopt -s nullglob
confs=("$HOME"/.sqldeveloper/*/product.conf)
shopt -u nullglob

if [[ ${#confs[@]} -eq 0 ]]; then
  echo "No ~/.sqldeveloper/*/product.conf found — launch SQL Developer once, then re-run." >&2
  exit 0
fi

for conf in "${confs[@]}"; do
  if grep -qE '^[[:space:]]*AddVMOption[[:space:]]+-Xmx' "$conf"; then
    echo "  $(grep -E '^[[:space:]]*AddVMOption[[:space:]]+-Xmx' "$conf" | head -1 | xargs) already set in $conf — left as-is."
    continue
  fi
  printf '\n# Set by dotfiles (08-sqldeveloper-conf.sh): cap max heap.\nAddVMOption -Xmx%s\n' "$XMX" >> "$conf"
  echo "  added AddVMOption -Xmx$XMX to $conf"
done
