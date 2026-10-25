#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE="$ROOT/_build/stage"
DIST="$ROOT/_build/dist"
mkdir -p "$DIST"
cp "$STAGE/bin/mp3splt.exe" "$DIST/"
find "$STAGE" -type f -iname '*.dll' -exec cp -f {} "$DIST/" \;
find "$DIST" -type f -iname '*splt*mp3*.dll' | grep -q . || { echo 'MP3 plugin missing'; exit 1; }
declare -A done=()
for pass in {1..30}; do
 changed=0
 while IFS= read -r -d '' binary; do
  key="${binary,,}"
  [[ -n "${done[$key]:-}" ]] && continue
  done[$key]=1
  while IFS= read -r dep; do
   [[ -n "$dep" ]] || continue
   case "${dep,,}" in
     msys-2.0.dll) echo "MSYS runtime leak"; exit 1;;
     api-ms-win-*|ext-ms-*|kernel32.dll|kernelbase.dll|ntdll.dll|msvcrt.dll|ucrtbase.dll|advapi32.dll|user32.dll|gdi32.dll|ole32.dll|oleaut32.dll|shell32.dll|ws2_32.dll|winmm.dll|comdlg32.dll|secur32.dll|bcrypt.dll|crypt32.dll|rpcrt4.dll|version.dll|shlwapi.dll|imm32.dll|setupapi.dll|psapi.dll|comctl32.dll|normaliz.dll|dbghelp.dll) continue;;
   esac
   if find "$DIST" -maxdepth 1 -iname "$dep" | grep -q .; then continue; fi
   source="$(find /ucrt64/bin -maxdepth 1 -iname "$dep" -print -quit)"
   [[ -n "$source" ]] || { echo "Missing DLL $dep"; exit 1; }
   cp "$source" "$DIST/"
   changed=1
  done < <(objdump -p "$binary" | sed -n 's/^[[:space:]]*DLL Name:[[:space:]]*//p')
 done < <(find "$DIST" -maxdepth 1 -type f \( -iname '*.exe' -o -iname '*.dll' \) -print0)
 [[ "$changed" -eq 0 ]] && break
done
cp "$STAGE/build-manifest.txt" "$DIST/"
printf 'Portable mp3splt, source: Debian 2.6.2+20170630. GPL-licensed.\n' > "$DIST/README.txt"
for part in mp3splt libmp3splt; do
 license="$(find "$ROOT/_build/src" -type f -path "*/$part/COPYING" -print -quit)"
 [[ -z "$license" ]] || cp "$license" "$DIST/LICENSE_$part.txt"
done
