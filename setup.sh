#!/bin/sh
# rac-rs's setup script is written in fish (it uses fish's syntax throughout); this wrapper runs it.
# See the README for the requirements: fish, Rust, Python, a C compiler, pkg-config, the ALSA and libudev headers.
d=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
if ! command -v fish >/dev/null 2>&1; then
	echo "fish is not installed. On Arch: sudo pacman -S fish   (see the README for the other packages)" >&2
	exit 1
fi
exec fish "$d/setup.fish" "$@"
