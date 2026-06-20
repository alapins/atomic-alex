#!/usr/bin/env bash
# Bake appsync's required CLI tools into the image:
#   - yq      (mikefarah/yq, Go) — required by ~/.config/appsync/install.sh at runtime.
#             Do NOT use Fedora's dnf `yq`; that is a different python tool.
#   - topgrade — universal updater (used ad-hoc on Linux, primary updater on macOS).
# Both are single static binaries pulled from upstream GitHub releases.
set -euo pipefail

arch="$(uname -m)"  # x86_64 on this image
dest="/usr/bin"

echo "::group:: install yq (mikefarah)"
curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
  -o "$dest/yq"
chmod +x "$dest/yq"
"$dest/yq" --version
echo "::endgroup::"

echo "::group:: install topgrade"
ver="$(curl -fsSL https://api.github.com/repos/topgrade-rs/topgrade/releases/latest \
  | grep -oP '"tag_name":\s*"\K[^"]+')"
curl -fsSL "https://github.com/topgrade-rs/topgrade/releases/download/${ver}/topgrade-${ver}-${arch}-unknown-linux-gnu.tar.gz" \
  | tar -xz -C "$dest" topgrade
chmod +x "$dest/topgrade"
"$dest/topgrade" --version
echo "::endgroup::"
