# atomic-alex &nbsp; [![bluebuild build badge](https://github.com/alapins/atomic-alex/actions/workflows/build.yml/badge.svg)](https://github.com/alapins/atomic-alex/actions/workflows/build.yml)

My personal [BlueBuild](https://blue-build.org) images, built on [Universal Blue](https://universal-blue.org)'s Aurora.

## Images

This repo builds two images that share most of their configuration:

| Image | Base | For |
| --- | --- | --- |
| `ghcr.io/alapins/atomic-alex` | `aurora-dx:stable` | Desktop |
| `ghcr.io/alapins/atomic-alex-nvidia` | `aurora-dx:latest` + proprietary NVIDIA | Dell XPS 9570 laptop (GTX 1050 Ti) |

**Why the laptop image tracks `latest` instead of `stable`:** the GTX 1050 Ti is
a Pascal GPU, which NVIDIA's *open* kernel modules don't support, so it needs the
proprietary driver layered via the `akmods` module. uBlue only publishes prebuilt
NVIDIA kmods for the rolling/latest kernel — `aurora-dx:stable` deliberately lags,
so its kernel never matches the kmod and the build fails. `latest` (the newest
daily Fedora build, *not* a beta) keeps the kernel in lockstep with the kmod. The
desktop image has no NVIDIA layering, so it stays on `stable`.

### Configuration layout

Shared modules live in `recipes/common/` and are pulled into each recipe with
`from-file`:

```
recipes/
├── common/
│   ├── system.yml     # files + chezmoi                ┐
│   ├── dnf.yml        # shared dnf repos + packages     ├─ both images
│   ├── flatpaks.yml   # shared system flatpaks          │
│   └── finalize.yml   # appsync script, signing, systemd┘
├── recipe.yml         # desktop  → atomic-alex
└── recipe-nvidia.yml  # XPS 9570 → atomic-alex-nvidia
```

Apps common to both go in `recipes/common/*.yml`. To install something on only
one machine, add a `dnf` or `default-flatpaks` module inline in that recipe.

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation, pick the image for that
machine — `atomic-alex` (desktop) or `atomic-alex-nvidia` (laptop) — and use it
in both commands below. The desktop is shown here; for the laptop swap in
`atomic-alex-nvidia`.

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/alapins/atomic-alex:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/alapins/atomic-alex:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag always points to the latest build.

### NVIDIA laptop notes

On the first boot after rebasing to `atomic-alex-nvidia`, you may get a one-time
**MOK enrollment** prompt (Secure Boot) — enter `universalblue` to enroll uBlue's
signing key so the NVIDIA module loads. If `lsmod | grep nvidia` comes back empty
afterward, run `ujust configure-nvidia` once and reboot.

## ISO

To build a bootable installer ISO from a published image (requires `podman`;
runs a privileged container, so use `sudo`):

```bash
sudo bluebuild generate-iso \
  --iso-name atomic-alex-nvidia.iso \
  -o ./output \
  image ghcr.io/alapins/atomic-alex-nvidia:latest
```

Swap the image ref for `ghcr.io/alapins/atomic-alex:latest` to build the desktop
ISO. The Aurora images are KDE-based, so the default `kinoite` installer variant
is correct. Then write the result to a USB stick with Fedora Media Writer,
[Impression](https://flathub.org/apps/io.gitlab.adhami3310.Impression), Ventoy,
or `dd`:

```bash
sudo dd if=./output/atomic-alex-nvidia.iso of=/dev/sdX bs=4M status=progress oflag=direct conv=fsync
```

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/alapins/atomic-alex
cosign verify --key cosign.pub ghcr.io/alapins/atomic-alex-nvidia
```
