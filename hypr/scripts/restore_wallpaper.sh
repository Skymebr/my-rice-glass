#!/bin/bash
CACHE_FILE="$HOME/.cache/current_wallpaper"

if [ -f "$CACHE_FILE" ]; then
    # Lê o caminho do arquivo salvo
    WALLPAPER=$(cat "$CACHE_FILE")

    # Verifica se é vídeo ou imagem
    EXT="${WALLPAPER##*.}"
    EXT="${EXT,,}"

    if [[ "$EXT" == "mp4" || "$EXT" == "mkv" || "$EXT" == "webm" ]]; then
        swww clear
        killall mpvpaper
        mpvpaper -o "no-audio --loop-playlist" '*' "$WALLPAPER" &
    else
        killall mpvpaper
        swww img "$WALLPAPER" --transition-step 255 # Sem animação no boot para ser rápido
    fi
else
    # Se não tiver cache, roda o sorteio normal
    ~/.config/hypr/scripts/wallpaper.sh
fi
