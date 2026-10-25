# Music Combine — portable mp3splt 2.6.2 (Windows x64)

This repository builds a portable Windows x64 `mp3splt.exe` from the SHA-256-pinned Debian mp3splt 2.6.2 source archive, including the MP3 plugin and runtime DLLs.

The CI must pass a real MP3 split test with an isolated Windows PATH before packaging. A successful CI run produces an artifact, **not an automatically trusted or published release**.

Source: `mp3splt_2.6.2+20170630.orig.tar.gz` (Debian)

Source SHA-256: `20D940415759735549DBC5B9A974AAABA8FDDB41572A0B7E3535DE6E4B375E44`

Status: first Windows CI build not yet verified.

## Build

Actions → **Build portable mp3splt 2.6.2** → Run workflow, or push a commit to `main`. Failed builds must not be published.

## Licenses

mp3splt/libmp3splt are GPL licensed. Redistribution of the portable bundle also requires compliance with the licenses of bundled DLL dependencies and appropriate source/notice availability.
