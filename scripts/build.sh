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
# This historical source hardcodes '/lib/libz.a' in its Windows
# Automake rules. On modern UCRT64, use the toolchain's -lz instead.
# Patch both Automake source and distributed Makefile.in before configure
# so generated makefiles cannot reintroduce the obsolete absolute path.
for mk in "$LIB_DIR/src/Makefile.am" "$LIB_DIR/src/Makefile.in"; do
  if [[ -f "$mk" ]]; then
    sed -i 's@/lib/libz[.]a@-lz@g' "$mk"
  fi
done
cd "$LIB_DIR"
./configure --prefix="$BUILD/stage" --enable-win --enable-mp3 --enable-id3tag --disable-ogg --disable-flac --disable-pcre --disable-cutter --disable-doxygen_doc
# Old Automake put the original static archive in both LIBADD (linker)
# and DEPENDENCIES (make prerequisites). -lz is a linker flag, not a file.
# Remove it ONLY from the prerequisite list in the generated Makefile.
sed -i -E '/^libmp3splt_la_DEPENDENCIES[[:space:]]*=/s/[[:space:]]-lz//g' "$LIB_DIR/src/Makefile"
if grep -Fq '/lib/libz.a' "$LIB_DIR/src/Makefile"; then
  echo 'ERROR: unresolved legacy zlib linkage in generated Makefile' >&2
  exit 1
fi
if grep -E '^libmp3splt_la_DEPENDENCIES[[:space:]]*=' "$LIB_DIR/src/Makefile" | grep -q -- '-lz'; then
  echo 'ERROR: -lz incorrectly present among make prerequisites' >&2
  exit 1
fi
make -j2
make install
find "$BUILD/stage" -type f -iname '*splt*mp3*.dll' | grep -q .
cd "$CLI_DIR"
./configure --prefix="$BUILD/stage" --disable-oggsplt_symlink --disable-flacsplt_symlink
make -j2
make install
test -f "$BUILD/stage/bin/mp3splt.exe"
{ echo "Source SHA256: $EXPECTED"; gcc --version | head -1; pacman -Q; } > "$BUILD/stage/build-manifest.txt"
