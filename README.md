<p align="center"><img src="rac-rs.png" alt="Ratchet &amp; Clank" width="600"></p>

# rac-rs for Linux

**Fellow Linux users! This one is for you!**

Ratchet & Clank (PlayStation 2, 2002) on Linux, from power-on to the end
credits, built from **your own disc**. The game runs its own original code,
recompiled for your CPU.

This is a fork of **[rac-rs](https://github.com/AsobiCodes/rac-rs)** by
[AsobiCodes](https://github.com/AsobiCodes), a remarkable piece of work that
made the whole game playable on a PC in the first place. It was built for
Windows. This fork carries it over to Linux, adds what Linux players were
missing, and smooths the edges for anyone who would rather just play the
game than fight their way through a build.

> **No game data is included.** This repository contains no game code,
> graphics, sound, text or other game files. The setup reads your own copy of
> the disc and creates everything it needs on your PC. You need to own the
> game.

## What this fork adds

- **A native Linux build.** One script, no PowerShell, no Windows toolchain,
  and no 1.2 GB private copy of Rust.
- **Gamepad support.** Xbox-style and PlayStation controllers, over USB or
  Bluetooth, read as evdev devices. Full analog sticks and triggers, and a
  controller plugged in while the game is running is picked up straight away.
- **Xbox button glyphs.** The prompts can name the buttons the way an Xbox
  pad does: `A` `B` `X` `Y` `LB` `RB` `LT` `RT` `R3` `L3`. Switch back to
  the original PlayStation shapes whenever you like.
- **Prompts that follow your hands.** Mouse and keyboard shows the key names,
  a controller shows the button names, and the game switches between them by
  itself as you use each.
- **A third camera style, "Enhanced".** L2 aims, like the modern camera's
  R2, and R2 fires the weapon like the Circle button. The camera row now
  offers Classic, Modern and Enhanced.
- **"Reversed" applies to the right stick only.** The camera's reversal
  options no longer turn the mouse upside down as well.
- **The controller skips cutscenes.** Start skips, like Spacebar does. The
  Insomniac intro at the start of the game can be skipped too, at last.
- **A kinder build.** Drop your disc image in the `rom` folder and run one
  script. It finds the disc, checks it, and builds the game. The build log
  lands in `generated/build.log`, the build is `nice`d so your desktop stays
  usable, and `CARGO_BUILD_JOBS` caps how many cores it takes.

## Status

- The whole game is playable from power-on to the end credits, including
  New Game+.
- Gameplay follows the original PS2 game one to one. On top of that, the PC
  version has widescreen, keyboard and mouse controls, gamepad support, and
  an optional modern camera (mouse look and strafing).
- Optional modern graphics on the Graphics page (Pause > Options > Graphics):
  enhanced lighting, ambient occlusion, dynamic shadows, clear reflective
  water, enhanced smoke, fire and explosions, and sun rays. The Classic
  settings keep the original PS2 look.
- Plays from the PAL / Europe disc and, since v0.2, from the USA disc.
- Known issues are listed under [Known issues](#known-issues) below.

## How it works

The game runs on its own original code. When you run the setup, it translates
the PS2 code from your disc into native Rust ("static recompilation"), and
that code runs on a PS2 CPU core written in Rust. Because the game logic is
the original code, gameplay behaves exactly like the PS2 version.

Everything around the game code is native PC code written for this port:
graphics, sound, movies, input, saving, and the PC features. Where a fix or
a PC feature needs it, an original function is rewritten in readable Rust.
Changes are tested against the original: test runs play the same frames on
both versions and compare the game's memory.

## Goal

A faithful, fully playable PC version of Ratchet & Clank that you build from
your own disc, with PC improvements on top. The game logic stays the
original code. Rewriting the whole game from scratch is not a goal of this
project.

## What you need

- **The game disc:** Ratchet & Clank, **PAL / Europe v1.00** (serial
  SCES-50916) or **USA v1.00** (serial SCUS-97199). Make an `.iso` image of
  **your own** disc. Other versions (Japan, Platinum and Greatest Hits
  re-releases) are not supported yet. The setup checks the image.
- **About the USA version:** it plays the same as the PAL version (at 60
  fields a second, like the original US game), but it has had less testing so
  far. The PAL version runs at 50, as the original European release did.
- **A 64-bit Linux** with about **5 GB of free disk space** (the finished
  install takes about 3.5 GB).

To build it you need these:

| | Arch | Debian / Ubuntu | Fedora |
|---|---|---|---|
| Rust 1.85 or newer | `rust` | `rustup` | `rust` |
| Python 3.8 or newer | `python` | `python3` | `python3` |
| A C compiler, for linking | `gcc` | `build-essential` | `gcc` |
| pkg-config | `pkgconf` | `pkg-config` | `pkgconf-pkg-config` |
| ALSA headers | `alsa-lib` | `libasound2-dev` | `alsa-lib-devel` |
| libudev headers | `systemd-libs` | `libudev-dev` | `systemd-devel` |
| fish, the shell the scripts use | `fish` | `fish` | `fish` |

```sh
# Arch
sudo pacman -S --needed rust python gcc pkgconf alsa-lib systemd-libs fish

# Debian / Ubuntu
sudo apt install rustup python3 build-essential pkg-config libasound2-dev libudev-dev fish

# Fedora
sudo dnf install rust python3 gcc pkgconf-pkg-config alsa-lib-devel systemd-devel fish
```

To play it you also want a Vulkan driver (`vulkan-radeon`, `vulkan-intel` or
the proprietary one) and working sound. A gamepad is optional.

> **Tested on CachyOS with KDE Plasma.** Other distributions and desktop
> environments may need extra packages or a small tweak. If something does
> not work for you, please open an issue and say what you are on.

## Setup

1. Download or clone this repository and unpack it anywhere.
2. Put your disc image in the **`rom`** folder. Any name ending in `.iso`
   works. If you have more than one, the setup asks you which to use.
3. Run **`./setup.sh`**. It checks the disc, generates the game code from it,
   and builds the game. This takes about 8 minutes on a 24-thread CPU, or
   roughly half an hour on a 4-core CPU. You can keep using your computer
   while it runs.

The window stays open when it is done, so you can read the log. Set
`CARGO_BUILD_JOBS=4` to use fewer cores, or pass `--no-pause` to skip the
wait. A full log is written to `generated/build.log`.

Next time, run **`./play.sh`**.

Setup does the rest by itself:

- **Disc check:** it checks your disc image.
- **Build:** it generates the game code from your disc and builds the game.
- **Launcher (optional):** `./setup.sh --install-launcher` adds a
  "Ratchet & Clank (rac-rs)" entry to your application menu.

Your saves are kept in the `player` folder.

**Do not share or upload the generated files or the built game.** They contain
code generated from the game disc. Everything setup creates stays inside this
folder.

## Playing

Run `./play.sh`. The game starts from your disc, the same way the original
did, logos and all.

## Updating

This fork does not have an automatic updater. Pull the changes instead:

```sh
git pull
./setup.sh
```

Your saves, your disc setting and your downloaded crates are kept, and only
the parts that changed are rebuilt.

## Controls

The game's own button prompts show the keyboard and mouse keys, or the
controller's buttons, whichever you used last. You can change the camera
style, the button glyphs and the language in the game's Options menu.

Controllers work too: Xbox-style controllers and PlayStation controllers
(PS4 DualShock 4 and PS5 DualSense, over USB or Bluetooth), also when you
switch one on or plug it in after the game has started.

| | Classic | Modern | Enhanced |
|---|---|---|---|
| Camera | the original PS2 follow camera | mouse look and strafing | mouse look, L2 aims |
| R2 | does nothing | aims | fires the weapon |
| L2 | does nothing | nothing | aims |

With the modern camera on, hold R2 to strafe. In Enhanced, hold L2 to aim.

## Known issues

- Clank's jetpack can drift out of sync with Ratchet.
- Some glass surfaces can flicker.

## For developers

The unit tests read the game data off your disc. They look for it at a
fixed path in the game folder, so make a link to it:

```sh
ln -s "/path/to/Ratchet & Clank.iso" \
      "Ratchet & Clank (Europe) (En,Fr,De,Es,It) (v1.00).iso"
```

Then `cargo test --release --manifest-path rac-rs/Cargo.toml --bin rac-rs`
runs the suite. One test, `retail::memcard`, wants a savestate from the
upstream project's own test data, which is not part of a public checkout, so
it fails here. Everything else passes.

## Credits
**[rac-rs](https://github.com/AsobiCodes/rac-rs)** by
[AsobiCodes](https://github.com/AsobiCodes) is the original project, and
essentially all of it. The Linux port, the gamepad support, the Xbox button
glyphs, the third camera style and the cutscene skip are the work of
**[DeSynkro](https://github.com/DeSynkro)**, who did it for Linux users and
for anyone who would rather just play the game than fight a Windows
installer.

[OpenCode](https://opencode.ai) was used for a portion of the work.

The original project's `README.md`, `NOTICE.md` and `LICENSE` are kept, and
the credits for the third-party work it builds on are in
[NOTICE.md](NOTICE.md).

## Legal

This is a fan project for preservation and education. It is **not affiliated
with, endorsed by or sponsored by Sony Interactive Entertainment or
Insomniac Games**. "Ratchet & Clank" is a trademark of Sony Interactive
Entertainment LLC. All game content belongs to its owners.

The repository contains only original source code and tools. It contains no
copyrighted game data, and it does not tell you how to get the game other
than from a disc you own.

The Windows installer, the automatic updater and the Windows release of the
game live in the [upstream repository](https://github.com/AsobiCodes/rac-rs),
not here.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE). Credits for third-party work are
in [NOTICE.md](NOTICE.md).
