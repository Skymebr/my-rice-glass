#!/bin/bash

# --- CONFIGURAÇÃO ---
WALLPAPER_DIR="/home/skyme/wallpapers"
LOCK_FILE="$HOME/.cache/lock_wallpaper.png"
CACHE_FILE="$HOME/.cache/current_wallpaper"
QUEUE_FILE="$HOME/.cache/wallpaper_queue"
DURATION="0.5"
TRANSITION_ARGS="--transition-type outer --transition-pos 0.9,0.9 --transition-duration $DURATION --transition-fps 144"

mkdir -p "$HOME/.cache"
if [ ! -d "$WALLPAPER_DIR" ]; then exit 1; fi

swww query || swww-daemon &

# 1. PONTE ESTÁTICA
if pgrep -x "mpvpaper" > /dev/null; then
    swww img "$LOCK_FILE" --transition-step 255
    killall mpvpaper
fi

# 2. SISTEMA DE FILA
if [ ! -s "$QUEUE_FILE" ]; then
    find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" \) | shuf > "$QUEUE_FILE"
fi

RANDOM_FILE=$(head -n 1 "$QUEUE_FILE")
sed -i '1d' "$QUEUE_FILE"

if [ -z "$RANDOM_FILE" ]; then exit 1; fi
echo "$RANDOM_FILE" > "$CACHE_FILE"

EXT="${RANDOM_FILE##*.}"
EXT="${EXT,,}"

# 3. APLICAÇÃO

if [[ "$EXT" == "mp4" || "$EXT" == "mkv" || "$EXT" == "webm" ]]; then
    # VÍDEO
    (ffmpeg -y -i "$RANDOM_FILE" -ss 00:00:00 -vframes 1 "$LOCK_FILE" > /dev/null 2>&1) & disown
    
    swww img "$LOCK_FILE" $TRANSITION_ARGS
    mpvpaper -o "no-audio --loop-playlist" '*' "$RANDOM_FILE" & 
    
    CALCULATED_SLEEP=$(awk "BEGIN {print $DURATION + 0.2}")
    sleep "$CALCULATED_SLEEP"
    swww clear --transition-step 255

else
    # IMAGEM
    cp "$RANDOM_FILE" "$LOCK_FILE"
    swww img "$RANDOM_FILE" $TRANSITION_ARGS
fi
