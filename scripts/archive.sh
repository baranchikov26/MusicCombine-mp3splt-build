#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/output"
NAME=mp3splt-2.6.2-windows-x64.zip
(cd "$ROOT/_build/dist" && zip -q -X "$ROOT/output/$NAME" ./*)
(cd "$ROOT/output" && sha256sum "$NAME" > "$NAME.sha256")
