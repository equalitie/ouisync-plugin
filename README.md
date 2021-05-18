# Ouisync Plugin

A flutter plugin providing high-level dart API for the ouisync native library.

## Building the native library

The library is built automatically as part of this plugins build process, but it needs the following prerequisities to be satisfied first:

1. Checkout the library into a directory called `ouisync` next to this plugin's directory (or `git pull` the latest revision if already checked out).
2. Install [rust](https://www.rust-lang.org/tools/install)
3. For each of the supported platforms, add its corresponding target:

        rustup target add $TARGET

   Where `$TARGET` is the target triple of the platform (run `rustup target list` to list all available triples):

    - android arm64:  `aarch64-linux-android`
    - android arm32:  `armv7-linux-androideabi`
    - android x86_64: `x86_64-linux-android`
    - ios arm64:      `aarch64-apple-ios`
    - etc...

## Generating the low-level dart bindings module (`lib/bindings.dart`)

(needs to be done every time the public API of the native library changes)

    flutter pub run ffigen

## Running unit tests

Copy/symlink the native library to:
 - linux: `build/test/libouisync.so`
 - osx: `build/test/ouisync.dylb`
 - windows: `build/test/ouisync.dll`
