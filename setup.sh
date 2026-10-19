#!/usr/bin/env fish
# setup.fish - builds rac-rs (a PC port of Ratchet & Clank, PS2) on Linux from your own disc image.
#
# A Linux stand-in for setup.ps1 (which is Windows PowerShell 5.1). It runs the project's own
# generators and cargo, and nothing else. The Windows tools it replaces are not used here:
# no rustup, no embeddable Python, no MSYS2 GNU assembler. Your system Rust and Python are used
# as they are, so the pinned-toolchain download (~1.2 GB) does not happen.
#
# Steps, in order:
#   (b)  check that the .iso is Ratchet & Clank PAL/EU v1.00 (SCES-50916) or USA v1.00 (SCUS-97199)
#   (c)  generate the game code from the disc with tools/recgen_iso.py (boot + 19 levels)
#   (c2) generate the VU microcode translations with tools/vugen_iso.py
#   (d)  build the game with cargo (release) into ./build
#   (e)  write generated/play.cfg, so ./build/release/rac-rs can start on its own
#
# Everything it writes stays inside this folder: oracle/rec, oracle/game, the generated .rs
# files named by .gitignore, generated/, build/, and player/ once you play.
#
# Usage:
#   ./setup.fish --iso "<path to your .iso>"
#   ./setup.fish                       # reuses the .iso from generated/play.cfg
#   ./setup.fish --check-only --iso ...  # just verify the disc
#
# Options:
#   --iso PATH     the disc image (or pass it as the first plain argument)
#   -j, --jobs N   level generators in parallel (default 4)
#   --check-only   do (b) only
#   --skip-hash    size check only, skip the SHA-1
#   --regenerate   redo (c) and (c2) even if the stamps say they are current
#   --no-build     stop after (c2)
#   -h, --help     this text

set -l root (realpath (status dirname))
cd $root

function Fail
    printf 'ERROR: %s\n' $argv[1] >&2
    exit 1
end

function Step
    printf '\n== %s\n' $argv[1]
end

# ---------------------------------------------------------------- arguments
set -l iso ''
set -l jobs 4
set -l skip_hash 0
set -l check_only 0
set -l regenerate 0
set -l no_build 0

set -l args $argv
while test (count $args) -gt 0
    switch $args[1]
        case --iso
            test (count $args) -ge 2; or Fail '--iso needs a path'
            set iso $args[2]
            set -e args[1..2]
        case -j --jobs
            test (count $args) -ge 2; or Fail '--jobs needs a number'
            set jobs $args[2]
            set -e args[1..2]
        case --skip-hash
            set skip_hash 1
            set -e args[1]
        case --check-only
            set check_only 1
            set -e args[1]
        case --regenerate
            set regenerate 1
            set -e args[1]
        case --no-build
            set no_build 1
            set -e args[1]
        case -h --help
            set -l self (status filename)
            set -l last (grep -n '^#   -h, --help' $self | cut -d: -f1)
            head -n $last $self | tail -n +2
            exit 0
        case '*'
            test -z "$iso"; or Fail 'the disc image was given twice'
            set iso $args[1]
            set -e args[1]
    end
end

# From here on the ISO is a plain path. It may contain spaces and '&' (for example
# ".../Ratchet & Clank/Roms/Ratchet & Clank.iso"), so it is only ever passed as one
# element of a command list, never interpolated into a command string.
test (count $iso) -gt 0; or Fail 'no disc image given (use --iso "<path to your .iso>")'
test -f "$iso"; or Fail "disc image not found: $iso"

# The version this tree is, from the VERSION file (0.2.2). Written into
# generated/built_version.txt after a build; the game puts it in the window title.
# Not named `version`: that is a read-only fish special variable.
set -l build_version (string trim (cat VERSION))

# Rust crates are 97% of the compile work; they build at opt-level 3 in one codegen
# unit. Passed to cargo as a config file so rac-rs/Cargo.toml stays unchanged. (Step d
# in setup.ps1 does the same.)
# Only this toolchain is used and no build settings from your shell config can change
# the build or its speed.
for v in RUSTC RUSTC_WRAPPER RUSTC_WORKSPACE_WRAPPER RUSTFLAGS CARGO_ENCODED_RUSTFLAGS \
         CARGO_BUILD_TARGET CARGO_BUILD_RUSTFLAGS CARGO_BUILD_RUSTC_WRAPPER CARGO_TARGET_DIR \
         CARGO_PROFILE_RELEASE_OPT_LEVEL CARGO_PROFILE_RELEASE_LTO RUSTUP_DIST_SERVER
    set -e $v
end
command -v cargo >/dev/null; or Fail 'cargo not found (install the rust toolchain: https://rustup.rs)'
command -v python3 >/dev/null; or Fail 'python3 not found (the generators need it)'

# The generator flags, as in setup.ps1. --shared-slow writes the memory-access slow paths
# as shared helpers instead of inlining them.
set -l gen_flags --no-comments --compact --shared-slow --outline-mem

# ---------------------------------------------------------------- (b) disc image
Step '(b) disc image'

# The two supported discs, v1.00 of each. They differ in size; the SHA-1 then proves the copy.
set -l disc_size 0
set -l disc_sha1 ''
set -l disc_name ''
set -l len (stat -c %s -- $iso)
switch $len
    case 4213997568
        set disc_size 4213997568
        set disc_sha1 B0DFBD8EAC0D84F173B6FC25D8A02A5FF22C652F
        set disc_name 'PAL / Europe v1.00 (SCES-50916)'
    case 4214095872
        set disc_size 4214095872
        set disc_sha1 AEE9275384F739C9B24CD5DE6F7E200292DB7B01
        set disc_name 'USA v1.00 (SCUS-97199)'
    case '*'
        Fail "wrong size: $len bytes. Expected 4213997568 (Ratchet & Clank PAL/EU v1.00, SCES-50916) or 4214095872 (USA v1.00, SCUS-97199), both En/Fr/De/Es/It. Other regions and versions are not supported."
end
printf '  %s (%d bytes)\n' $iso $len
printf '  disc: Ratchet & Clank %s (by size)\n' $disc_name
set -l sha1 $disc_sha1
if test $skip_hash -eq 0
    printf '  computing SHA-1 (about half a minute) ...\n'
    set sha1 (sha1sum -- $iso | cut -d' ' -f1 | string upper)
    if test "$sha1" != "$disc_sha1"
        Fail "SHA-1 mismatch: $sha1 (expected $disc_sha1). This is not the $disc_name disc image (re-dump, or another version)."
    end
    printf '  SHA-1 ok: Ratchet & Clank %s\n' $disc_name
else
    printf '  SHA-1 skipped (--skip-hash); size matches\n'
end
if test $check_only -eq 1
    printf 'Checks passed.\n'
    exit 0
end

set -l gen generated
mkdir -p $gen

# The stamp is the disc, the generator flags and a hash of the generator files: if any of
# those change, the generated code is redone. (setup.ps1 keeps a list of older generator
# hashes that produce identical output, so that an update which only changed how the files
# are written does not regenerate. Nothing to keep compatible here.)
function Stamp
    cat -- $argv | sha256sum | cut -d' ' -f1
end

# Blocks until a level's .exit file shows up, or about 30 minutes, whichever is first.
# The wait is bounded so a generator killed outright cannot hang setup forever.
function WaitExit
    set -l spins 3600
    while not test -f $argv[1]
        sleep 0.5
        set spins (math $spins - 1)
        if test $spins -le 0
            return 1
        end
    end
    return 0
end

# ---------------------------------------------------------------- (c) generate
Step '(c) generating game code from the disc image'
set -l orc oracle
set -l stamp $gen/done.txt
set -l gen_files tools/recgen_iso.py tools/fn_bounds.tsv oracle/stubs.txt
if test "$sha1" = AEE9275384F739C9B24CD5DE6F7E200292DB7B01
    set -a gen_files tools/fn_bounds_usa.tsv
end
set -l gen_hash (Stamp $gen_files)
set -l want "$sha1 $disc_size flags="(string join ' ' -- $gen_flags)" gen=$gen_hash"
# A stamp that is empty means something upstream failed to compute. Two empty stamps would
# compare equal and silently skip the generation, so refuse to continue instead.
test (string length -- "$want") -gt 40; or Fail "internal error: could not build the generator stamp"
set -l have ''
test -f $stamp; and set have (string trim (cat $stamp))
test -f $orc/game/src/lib.rs; or set have ''
test -f $orc/rec/l18_00/Cargo.toml; or set have ''

if test $regenerate -eq 1; or test "$have" != "$want"
    # The generators write in place and only touch files whose content differs, so
    # cargo rebuilds by file mtime and an unchanged regenerate costs nothing extra.
    rm -f $stamp
    rm -rf $gen/logs
    mkdir -p $gen/logs
    # Levels 0..18, --jobs of them at a time. Two fish details shape this:
    #   - `wait` never reports a background job's exit status (it is always 0), and fish
    #     has already reaped a finished job by the time you wait for it.
    #   - So each level writes its own exit status to generated/logs/level_N.exit, and
    #     that file appearing is what marks the level finished. The block writes it
    #     whether the generator succeeded or not, so it always appears.
    set -l running
    set -l failed
    for lv in (seq 0 18)
        while test (count $running) -ge $jobs
            set -l l $running[1]
            set -e running[1]
            WaitExit $gen/logs/level_$l.exit
            set -l rc (string trim (cat $gen/logs/level_$l.exit))
            if test "$rc" = 0
                printf '  level %s done: %s\n' $l (tail -n 1 $gen/logs/level_$l.log)
            else
                set -a failed $l
                printf '  level %s FAILED (see generated/logs/level_%s.log.err)\n' $l $l >&2
            end
        end
        set -l a python3 -I tools/recgen_iso.py --iso $iso --level $lv --out $orc --oracle $orc
        test $lv -gt 0; and set -a a --keep-boot
        set -a a $gen_flags
        begin
            $a >$gen/logs/level_$lv.log 2>$gen/logs/level_$lv.log.err
            echo $status >$gen/logs/level_$lv.exit
        end &
        set -a running $lv
    end
    while test (count $running) -gt 0
        set -l l $running[1]
        set -e running[1]
        WaitExit $gen/logs/level_$l.exit
        set -l rc (string trim (cat $gen/logs/level_$l.exit))
        if test "$rc" = 0
            printf '  level %s done: %s\n' $l (tail -n 1 $gen/logs/level_$l.log)
        else
            set -a failed $l
            printf '  level %s FAILED (see generated/logs/level_%s.log.err)\n' $l $l >&2
        end
    end
    test (count $failed) -eq 0; or Fail "generation failed for level(s) "(string join ', ' $failed)"; logs are in generated/logs"
    # The parallel generators race on game/src/lib.rs: rewrite it once from what is on disk.
    python3 tools/recgen_iso.py --facade-only --out $orc --oracle $orc
    test $status -eq 0; or Fail 'facade rewrite failed'
    # Every crate must be in the facade (the concurrent generators rewrite it).
    set -l n_crates (find $orc/rec -mindepth 1 -maxdepth 1 -type d 2>/dev/null | count)
    set -l n_reg (grep -c '::FNS)' $orc/game/src/lib.rs)
    test "$n_crates" -eq "$n_reg"; or Fail "facade lists $n_reg of $n_crates crates; rerun with --regenerate --jobs 1"
    printf '%s\n' $want >$stamp
    printf '  generated %d crates\n' $n_crates
else
    printf '  already generated for this disc image (use --regenerate to redo)\n'
end

# ---------------------------------------------------------------- (c2) VU microcode translations
# The VU0/VU1 microprograms (graphics/maths code of the game) are cut out of YOUR disc image
# and translated to Rust. None of that is shipped. (Same as setup.ps1 step c2.)
Step '(c2) generating the VU microcode translations from the disc image'
set -l vu_stamp $gen/vu_done.txt
set -l vu_files tools/vugen_iso.py tools/vu/vu0gen.py tools/vu/vu1gen.py tools/vu/vu_disasm.py tools/vu/profile.txt
set -l vu_want "$sha1 vu1 gen="(Stamp $vu_files)
set -l vu_have ''
test -f $vu_stamp; and set vu_have (string trim (cat $vu_stamp))
test -f $orc/src/vu0_prog0.rs; or set vu_have ''
test -f rac-rs/src/gsfull/vu1aot_gen.rs; or set vu_have ''
test -f rac-rs/src/particles/orb_tables.rs; or set vu_have ''

if test $regenerate -eq 1; or test "$vu_have" != "$vu_want"
    # Not -I: vugen_iso.py puts tools/vu on sys.path itself.
    python3 tools/vugen_iso.py --iso $iso --tree $root
    test $status -eq 0; or Fail 'VU microcode generation failed (tools/vugen_iso.py)'
    printf '%s\n' $vu_want >$vu_stamp
    printf '  done\n'
else
    printf '  already generated (use --regenerate to redo)\n'
end

if test $no_build -eq 1
    printf 'Generation done (--no-build).\n'
    exit 0
end

# The generated crates are what the build needs; if step (c) was skipped or half-done,
# cargo would fail with a confusing "no matching package named ee-game".
test -f $orc/game/src/lib.rs; or Fail 'the generated game code is missing; rerun with --regenerate'
test -d $orc/rec; or Fail 'the generated game code is missing; rerun with --regenerate'

# ---------------------------------------------------------------- (d) build
Step '(d) building the game (release)'
set -l prof $gen/build_profile.toml
printf '%s\n' '# written by setup.fish (step d): build profile of the generated crates' \
    '[profile.release.package.ee-game]' 'opt-level = 3' 'codegen-units = 1' >$prof
# One opt-level 3 / codegen-units 1 table per generated crate. The crate directory names
# (l0_00, boot_00, ...) become package names with underscores turned into dashes.
# `path basename`, not `ls`: fish's ls is a function that defaults to the long listing,
# which would write a whole ls -l line into the TOML.
for p in (find $orc/rec -mindepth 1 -maxdepth 1 -type d)
    printf '\n[profile.release.package.rec-%s]\nopt-level = 3\ncodegen-units = 1\n' \
        (string replace -a _ - (path basename $p)) >>$prof
end
cargo build --release --manifest-path rac-rs/Cargo.toml --target-dir build \
    --bin rac-rs --config $prof
test $status -eq 0; or Fail 'cargo build failed'
set -l exe build/release/rac-rs
test -f $exe; or Fail "build finished but $exe is missing"
printf '  built %s\n' $exe
printf '%s\n' $build_version >$gen/built_version.txt

# ---------------------------------------------------------------- (e) play
# generated/play.cfg: key=value, UTF-8, LF. The game, started with no arguments, reads it to
# find the disc image; it then sets the environment itself, so play.fish needs no arguments.
printf 'iso=%s\n' $iso >$gen/play.cfg
printf '  wrote generated/play.cfg\n'

Step 'done'
printf 'To play:  ./play.fish\n'