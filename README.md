[![CI](https://github.com/equalitie/ouisync-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/equalitie/ouisync-plugin/actions/workflows/ci.yml)

# Ouisync Plugin

A flutter plugin providing high-level dart API for the ouisync native library.

## Building the native library

You will need the following installed:
- rustup
- cargo (which gets installed with rustup)
- llvm
- flutter

On macos, we recommend installing Apple's Xcode command line tools, which include a working llvm installation.

The native library is built automatically as part of this plugins build
process, but it needs the following prerequisities to be satisfied first:

1. Install [rust](https://www.rust-lang.org/tools/install)
2. For each of the supported platforms, add its corresponding target:

        $ rustup target add $TARGET

Where `$TARGET` is the target triple of the platform (run `rustup target list`
to list all available triples):

    - android arm64:  `aarch64-linux-android`
    - android arm32:  `armv7-linux-androideabi`
    - android x86_64: `x86_64-linux-android`
    - ios arm64:      `aarch64-apple-ios`
    - etc...

## Before using/building this plugin

Before this plugin can be used, one has to first generate the `ouisync/target/bindings.h`
header file and then the `lib/bindings.dart` file.

The former is done with the command:

    $ cd ouisync
    $ cargo build --lib

The latter is then done from the root folder of this repository:

    $ flutter pub get
    $ flutter pub run ffigen

Note that the above needs to be done every time the public interface of the
`ouisync` module changes.

## Building the AAR

You normally don't build the `.aar` file manually. Rather, it gets
built as a depdendecy of whatever app uses this plugin. See the
[`ouisync-app`](https://github.com/equalitie/ouisync-app/blob/040eb7216c0c48cc4de75c8d36a0d68267320854/pubspec.yaml)
for an example.

If, however, you want to build a standalone `.aar` file, run

    $ flutter build aar

This will create release, debug and profile builds for `arm32`, `arm64` and
`x86_64` architectures (32bit `x86` is omited by default).

To build only for certain architectures or add missing ones, add the
`--target-platform={android-arm,android-arm64,android-x86,android-x64}` flag to
the above command.

To avoid building the release, debug or profile versions use any combination of
`--no-release`, `--no-debug`, `--no-profile`.
