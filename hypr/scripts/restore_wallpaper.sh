#!/bin/bash
CACHE_FILE="$HOME/.cache/current_wallpaper"
LOCK_FILE="$HOME/.cache/lock_wallpaper.png"

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
        
        # [CORREÇÃO] Extrai o primeiro frame do vídeo para usar no Lockscreen
        ffmpeg -y -i "$WALLPAPER" -ss 00:00:00 -vframes 1 "$LOCK_FILE" > /dev/null 2>&1 &
    else
        killall mpvpaper
        swww img "$WALLPAPER" --transition-step 255
        
        # [CORREÇÃO] Converte a imagem atual para um PNG real para o Lockscreen
        ffmpeg -y -i "$WALLPAPER" "$LOCK_FILE" > /dev/null 2>&1
    fi
else
    # Se não tiver cache, roda o sorteio normal
    ~/.config/hypr/scripts/wallpaper.sh
fi
