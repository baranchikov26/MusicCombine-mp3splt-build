#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/_build/mp3guessenc"
SOURCE="mp3guessenc_0.27.6~beta+dfsg.orig.tar.xz"
URL="https://deb.debian.org/debian/pool/main/m/mp3guessenc/mp3guessenc_0.27.6~beta%2Bdfsg.orig.tar.xz"
SHA256="4b38e35abb3f1d63ba9ec322ed89a01370deb4b6705a29fc0b1e8435e32efa6c"
mkdir -p "$BUILD/src" "$BUILD/dist"
curl -fL --retry 3 --connect-timeout 30 -o "$BUILD/$SOURCE" "$URL"
echo "$SHA256  $BUILD/$SOURCE" | sha256sum -c -
tar -xJf "$BUILD/$SOURCE" -C "$BUILD/src" --strip-components=1
cd "$BUILD/src"
test -f Makefile
test -f COPYING
# Override obsolete 32-bit -march=i686 injected when SYSTEMROOT is set.
# No dependencies beyond standard C/Windows UCRT.
make -j2 CC=gcc BIN_EXT=.exe CFLAGS='-O2 -Wall -Wextra -D_FILE_OFFSET_BITS=64' LDFLAGS='-static-libgcc'
test -s mp3guessenc.exe
cp mp3guessenc.exe "$BUILD/dist/"
cp COPYING "$BUILD/dist/LICENSE.txt"
cp ChangeLog "$BUILD/dist/ChangeLog.txt"
printf 'Source: Debian mp3guessenc 0.27.6~beta+dfsg\nSource archive SHA256: %s\nToolchain: MSYS2 UCRT64 GCC\n' "$SHA256" > "$BUILD/dist/build-info.txt"
# Check that the output is a native executable, not the MSYS POSIX runtime.
if objdump -p mp3guessenc.exe | grep -Eiq 'DLL Name:[[:space:]]*msys-2[.]0[.]dll'; then
  echo 'ERROR: an MSYS runtime dependency was introduced' >&2
  exit 1
fi
objdump -p mp3guessenc.exe | grep 'DLL Name:' > "$BUILD/dist/imported-dlls.txt" || true
