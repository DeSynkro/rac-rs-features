#!/usr/bin/env fish
# play.fish - starts Ratchet & Clank (rac-rs) from your disc image.
#
# The game reads generated/play.cfg itself (the disc path, the save folder, the
# language), so there are no arguments to pass. Run setup.fish first.

set -l root (realpath (status dirname))
cd $root
exec $root/build/release/rac-rs $argv