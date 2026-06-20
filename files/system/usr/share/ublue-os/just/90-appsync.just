# appsync — full system update in one command.
# Leaves the stock `ujust update` (OS image + flatpak + brew) untouched and adds
# the layers uupd does not cover: mise tools, AppMan AppImages, and install scripts.
# Logic lives in ~/.config/appsync/update.sh (deployed by chezmoi).

# Update everything: stock OS update, then appsync's extra layers.
[group('System')]
update-all: && update-extras
    @ujust update

# Update only the appsync-managed layers (mise, AppImages, scripts).
[group('System')]
update-extras:
    @"$HOME/.config/appsync/update.sh"
