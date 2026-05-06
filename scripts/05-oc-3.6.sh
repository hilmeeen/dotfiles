#!/usr/bin/env bash
# Download the OCP 3.6 `oc` client (linux/amd64 only — no arm64 build exists)
# into $HOME/bin-linux-amd64/oc-3.6. The binary is a Linux ELF, so it only
# runs *inside* a linux/amd64 container (podman + Rosetta provides this).
# We deliberately keep this folder OFF $PATH on macOS so we never try to
# exec a Linux binary on the host by accident.
#
# Source: https://mirror.openshift.com/pub/openshift-v3/clients/3.6.173.0.96/linux/oc.tar.gz
set -euo pipefail

OC_VERSION="3.6.173.0.96"
OC_URL="https://mirror.openshift.com/pub/openshift-v3/clients/${OC_VERSION}/linux/oc.tar.gz"
LINUX_BIN_DIR="$HOME/bin-linux-amd64"
DEST="$LINUX_BIN_DIR/oc-3.6"

mkdir -p "$LINUX_BIN_DIR"

if [[ -x "$DEST" ]]; then
  echo "$DEST already present — skipping download."
  exit 0
fi

echo "Downloading oc ${OC_VERSION} (linux/amd64) ..."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fL -o "$tmpdir/oc.tar.gz" "$OC_URL"
tar -xzf "$tmpdir/oc.tar.gz" -C "$tmpdir"

# The tarball lays the binary out as either ./oc or ./<dir>/oc; handle both.
oc_bin="$(find "$tmpdir" -maxdepth 3 -type f -name oc -perm -u+x | head -n1 || true)"
if [[ -z "$oc_bin" ]]; then
  echo "Could not locate 'oc' inside the extracted archive." >&2
  exit 1
fi

mv "$oc_bin" "$DEST"
chmod +x "$DEST"
echo "Installed $DEST"

# Sanity check: file should be an ELF x86_64 binary.
if command -v file >/dev/null 2>&1; then
  file "$DEST"
fi

cat <<EOF

Note: $DEST is a linux/amd64 ELF binary. It will NOT run directly on macOS.
Run it inside a linux/amd64 container, e.g.:

  podman run --platform=linux/amd64 --rm -it \\
    -v "\$HOME/bin-linux-amd64:/host-bin:ro" \\
    registry.access.redhat.com/ubi9 \\
    /host-bin/oc-3.6 version
EOF
