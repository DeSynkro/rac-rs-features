#!/bin/sh
# install-desktop-launcher.sh - adds "Ratchet & Clank (rac-rs)" to your
# application menu.
#
# It writes one small file into your home folder and touches nothing else.
# Run it once the game has been built, however you built it.

set -e

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
icon="$root/rac-rs/assets/icon/rac-rs-256.png"
template="$root/rac-rs.desktop"
dest="$HOME/.local/share/applications"
target="$dest/rac-rs.desktop"

if [ ! -f "$root/build/release/rac-rs" ]; then
	echo "The game is not built yet. Run ./setup.sh, or 'sudo docker compose up', first." >&2
	exit 1
fi

if [ ! -f "$template" ]; then
	echo "The launcher template is missing: $template" >&2
	exit 1
fi

# The folder name can hold an "&", and sed reads that as "the text that
# matched". Escape it, or the path comes out wrong.
esc() { printf '%s' "$1" | sed 's/[&|]/\\&/g'; }

mkdir -p "$dest"
sed -e "s|__RACRS_DIR__|$(esc "$root")|g" \
    -e "s|__RACRS_ICON__|$(esc "$icon")|g" \
    "$template" >"$target"

echo "Added a menu entry: $target"
echo "To remove it again: rm '$target'"
