#!/usr/bin/env bash
# Download the OCP 3.11 `oc` client (linux/amd64) into
# $HOME/bin-linux-amd64/oc-3.11. There is no native macOS arm64 build, and
# the linux-aarch64 build is still a Linux ELF — so we standardize on
# linux/amd64 and run it inside a podman+Rosetta container.
#
# 3.11.346 (Aug 2021) is the last v3-line release on the mirror. Its Go
# runtime is recent enough to avoid the lfstackpush panic that kills the
# old oc 3.6 binary under emulation, and it talks to OpenShift 3.x servers
# fine for everyday CLI work.
#
# We deliberately keep $HOME/bin-linux-amd64 OFF $PATH on macOS so we never
# accidentally exec a Linux ELF on the host.
#
# Source: https://mirror.openshift.com/pub/openshift-v3/clients/3.11.346/linux/oc.tar.gz
set -euo pipefail

OC_VERSION="3.11.346"
OC_URL="https://mirror.openshift.com/pub/openshift-v3/clients/${OC_VERSION}/linux/oc.tar.gz"
LINUX_BIN_DIR="$HOME/bin-linux-amd64"
DEST="$LINUX_BIN_DIR/oc-3.11"

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
    /host-bin/oc-3.11 version --client
EOF
