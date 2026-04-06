#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SRC_PATH="$SCRIPT_DIR/skywall.c"
BIN_PATH="$SCRIPT_DIR/skywall-bin"

if [[ ! -x "$BIN_PATH" || "$SRC_PATH" -nt "$BIN_PATH" ]]; then
    TMP_BIN="$SCRIPT_DIR/skywall-bin.tmp.$$"
    cc -O2 -Wall -Wextra -std=gnu11 \
        "$SRC_PATH" \
        -o "$TMP_BIN" \
        $(pkg-config --cflags gtk4-layer-shell-0 gtk4 gdk-pixbuf-2.0 cairo) \
        $(pkg-config --libs gtk4-layer-shell-0 gtk4 gdk-pixbuf-2.0 cairo) \
        -lm
    mv "$TMP_BIN" "$BIN_PATH"
fi

printf '%s\n' "$BIN_PATH"
