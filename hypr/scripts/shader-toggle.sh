#!/usr/bin/env bash
set -euo pipefail

SHADER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/shaders"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_FILE="$STATE_DIR/hypr-shader-mode"

usage() {
    cat <<'EOF'
Usage:
  shader-toggle.sh reading|night|cinema|invert|off
  shader-toggle.sh status

Calling the active mode again turns the shader off.
EOF
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a hypr-shader "$1" "$2" >/dev/null 2>&1 || true
    fi
}

set_shader() {
    local label="$1"
    local file="$2"
    local path="$SHADER_DIR/$file"

    if [[ -f "$STATE_FILE" && "$(<"$STATE_FILE")" == "$label" ]]; then
        clear_shader
        return
    fi

    if [[ ! -f "$path" ]]; then
        printf 'shader-toggle.sh: shader not found: %s\n' "$path" >&2
        exit 1
    fi

    mkdir -p "$STATE_DIR"
    hyprctl keyword decoration:screen_shader "$path" >/dev/null
    printf '%s\n' "$label" > "$STATE_FILE"
    notify "Shader ativo" "$label"
}

clear_shader() {
    mkdir -p "$STATE_DIR"
    hyprctl keyword decoration:screen_shader "" >/dev/null
    rm -f "$STATE_FILE"
    notify "Shader desligado" "screen_shader limpo"
}

mode="${1:-}"
case "${mode,,}" in
    reading|leitura|"modo leitura"|"reading mode")
        set_shader "reading" "reading_mode.glsl"
        ;;
    night|noite|"night light"|"luz noturna")
        set_shader "night" "night.glsl"
        ;;
    cinema|movie|filme)
        set_shader "cinema" "cinema.glsl"
        ;;
    invert|inverter|"smart invert")
        set_shader "invert" "smart_invert.glsl"
        ;;
    off|none|desligar|limpar)
        clear_shader
        ;;
    status)
        if [[ -f "$STATE_FILE" ]]; then
            cat "$STATE_FILE"
        else
            printf 'off\n'
        fi
        ;;
    help|-h|--help|"")
        usage
        ;;
    *)
        printf 'shader-toggle.sh: unknown mode: %s\n' "$mode" >&2
        usage >&2
        exit 2
        ;;
esac
