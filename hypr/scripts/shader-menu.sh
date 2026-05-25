#!/usr/bin/env bash
set -euo pipefail

TOGGLE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/shader-toggle.sh"

if ! command -v wofi >/dev/null 2>&1; then
    printf 'shader-menu.sh: wofi is required\n' >&2
    exit 1
fi

choice=$(printf '%s\n' \
    'Modo leitura' \
    'Luz noturna' \
    'Cinema' \
    'Inverter' \
    'Desligar shader' \
    | wofi --dmenu --prompt 'Shader' --cache-file /dev/null)

case "$choice" in
    'Modo leitura') exec "$TOGGLE" reading ;;
    'Luz noturna') exec "$TOGGLE" night ;;
    'Cinema') exec "$TOGGLE" cinema ;;
    'Inverter') exec "$TOGGLE" invert ;;
    'Desligar shader') exec "$TOGGLE" off ;;
    *) exit 0 ;;
esac
