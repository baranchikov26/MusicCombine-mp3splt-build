#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/_build"
ARCHIVE="mp3splt_2.6.2+20170630.orig.tar.gz"
URL="https://deb.debian.org/debian/pool/main/m/mp3splt/mp3splt_2.6.2%2B20170630.orig.tar.gz"
EXPECTED="20d940415759735549dbc5b9a974aaaba8fddb41572a0b7e3535de6e4b375e44"
mkdir -p "$BUILD/src" "$BUILD/stage"
curl -fL --retry 3 --connect-timeout 30 -o "$BUILD/$ARCHIVE" "$URL"
echo "$EXPECTED  $BUILD/$ARCHIVE" | sha256sum -c -
tar -xzf "$BUILD/$ARCHIVE" -C "$BUILD/src"
LIB_CONFIG="$(find "$BUILD/src" -type f -path '*/libmp3splt/configure' -print -quit)"
test -n "$LIB_CONFIG"
LIB_DIR="$(dirname "$LIB_CONFIG")"
CLI_DIR="$(dirname "$LIB_DIR")/mp3splt"
test -f "$CLI_DIR/configure"
export PKG_CONFIG_PATH="$BUILD/stage/lib/pkgconfig:/ucrt64/lib/pkgconfig"
export CPPFLAGS="-I$BUILD/stage/include"
export LDFLAGS="-L$BUILD/stage/lib"
export PATH="$BUILD/stage/bin:$PATH"
export CFLAGS="-O2 -std=gnu11 -Wno-error=implicit-function-declaration"
cd "$LIB_DIR"
./configure --prefix="$BUILD/stage" --enable-win --enable-mp3 --enable-id3tag --disable-ogg --disable-flac --disable-pcre --disable-cutter --disable-doxygen_doc
make -j2
make install
find "$BUILD/stage" -type f -iname '*splt*mp3*.dll' | grep -q .
cd "$CLI_DIR"
./configure --prefix="$BUILD/stage" --disable-oggsplt_symlink --disable-flacsplt_symlink
make -j2
make install
test -f "$BUILD/stage/bin/mp3splt.exe"
{ echo "Source SHA256: $EXPECTED"; gcc --version | head -1; pacman -Q; } > "$BUILD/stage/build-manifest.txt"
