#!/usr/bin/env bash
# Bake appsync's required CLI tools into the image:
#   - yq      (mikefarah/yq, Go) — required by ~/.config/appsync/install.sh at runtime.
#             Do NOT use Fedora's dnf `yq`; that is a different python tool.
#   - topgrade — universal updater (used ad-hoc on Linux, primary updater on macOS).
# Both are single static binaries pulled from upstream GitHub releases.
#
# Resilience: every download goes through fetch() which retries transient failures
# (5xx, dropped connections, and rate-limit 403s via --retry-all-errors). We also
# resolve the "latest" version WITHOUT api.github.com: the unauthenticated API is
# aggressively rate-limited from GitHub Actions' shared runner IPs and returns 403,
# which previously failed the whole image build. Instead we read the tag from the
# github.com /releases/latest 302 redirect (same host yq downloads from), which is
# not API-rate-limited. Both tools are required; a real outage still fails the build.
set -euo pipefail

arch="$(uname -m)"  # x86_64 on this image
dest="/usr/bin"

# Retry wrapper for all network fetches.
fetch() { curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors "$@"; }

# Latest release tag for a GitHub repo, via the /releases/latest redirect (no API).
# e.g. gh_latest_tag topgrade-rs/topgrade -> v17.6.2
gh_latest_tag() {
  fetch -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" \
    | sed -E 's#.*/tag/##'
}

echo "::group:: install yq (mikefarah)"
fetch -o "$dest/yq" \
  "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
chmod +x "$dest/yq"
"$dest/yq" --version
echo "::endgroup::"

echo "::group:: install topgrade"
ver="$(gh_latest_tag topgrade-rs/topgrade)"
fetch "https://github.com/topgrade-rs/topgrade/releases/download/${ver}/topgrade-${ver}-${arch}-unknown-linux-gnu.tar.gz" \
  | tar -xz -C "$dest" topgrade
chmod +x "$dest/topgrade"
"$dest/topgrade" --version
echo "::endgroup::"
