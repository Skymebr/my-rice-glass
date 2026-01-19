#!/bin/bash

# --- CONFIGURAÇÃO ---
WALLPAPER_DIR="$HOME/meus-dotfiles/wallpapers"
LOCK_FILE="$HOME/.cache/lock_wallpaper.png"
CACHE_FILE="$HOME/.cache/current_wallpaper"
QUEUE_FILE="$HOME/.cache/wallpaper_queue"

# --- LÓGICA DE TRANSIÇÃO ---
# Se for "init", a transição é cortada (instantânea)
if [[ "$1" == "init" ]]; then
    TRANSITION_ARGS="--transition-step 255"
else
    # Uso manual: Animação suave
    DURATION="0.7"
    TRANSITION_ARGS="--transition-type outer --transition-pos 0.9,0.9 --transition-duration $DURATION --transition-fps 144 --transition-bezier 0.65,0,0.35,1"
fi

mkdir -p "$HOME/.cache"
if [ ! -d "$WALLPAPER_DIR" ]; then exit 1; fi

# Garante que o daemon está rodando
swww query || swww-daemon --format xrgb &

# --- SELEÇÃO DO ARQUIVO ---
RANDOM_FILE=""
if [ "$1" == "restore" ] || [ "$1" == "init" ]; then
    if [ -f "$CACHE_FILE" ]; then RANDOM_FILE=$(cat "$CACHE_FILE"); fi
fi

if [ -z "$RANDOM_FILE" ] || [ ! -f "$RANDOM_FILE" ]; then
    if [ ! -s "$QUEUE_FILE" ]; then
        find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" \) | shuf > "$QUEUE_FILE"
    fi
    RANDOM_FILE=$(head -n 1 "$QUEUE_FILE")
    sed -i '1d' "$QUEUE_FILE"
fi

if [ -z "$RANDOM_FILE" ]; then exit 1; fi
echo "$RANDOM_FILE" > "$CACHE_FILE"

EXT="${RANDOM_FILE##*.}"
EXT="${EXT,,}"

# --- FUNÇÃO TURBO ---
reload_system_turbo() {
    if command -v matugen &> /dev/null; then
        matugen image "$LOCK_FILE" --quiet
    fi
    pkill -SIGUSR2 waybar 2>/dev/null || (killall waybar; waybar & disown)
    if command -v pywalfox &> /dev/null; then pywalfox update & fi
    killall -SIGUSR1 kitty 2>/dev/null
    pkill -SIGUSR1 cava 2>/dev/null
    swaync-client -rs &
    pkill wofi 2>/dev/null
    
    if [ -f "$HOME/.config/hypr/colors.conf" ]; then
        NEW_BORDER=$(grep 'primary.default.hex' "$HOME/.config/hypr/colors.conf" | cut -d ' ' -f 3 | tr -d 'a-fA-F' | sed 's/#/0xff/')
        NEW_INACTIVE=$(grep 'surface.default.hex' "$HOME/.config/hypr/colors.conf" | cut -d ' ' -f 3 | tr -d 'a-fA-F' | sed 's/#/0xff/')
        if [ -n "$NEW_BORDER" ]; then
            hyprctl keyword general:col.active_border "$NEW_BORDER"
            hyprctl keyword general:col.inactive_border "$NEW_INACTIVE"
        fi
    fi
}

# --- APLICAÇÃO VISUAL ---
if [[ "$EXT" == "mp4" || "$EXT" == "mkv" || "$EXT" == "webm" ]]; then
    rm -f "$LOCK_FILE"
    # Extrai frame 1080p RGBA
    ffmpeg -y -i "$RANDOM_FILE" -ss 00:00:01 -vframes 1 -vf "scale=1920:-1" -pix_fmt rgba "$LOCK_FILE" -v error
    if [[ ! -f "$LOCK_FILE" ]]; then
        FALLBACK=$(find "$WALLPAPER_DIR" -type f -name "*.jpg" -o -name "*.png" | head -n 1)
        ffmpeg -y -i "$FALLBACK" -vf "scale=1920:-1" -pix_fmt rgba "$LOCK_FILE" -v error
    fi
    
    reload_system_turbo &
    
    swww img "$LOCK_FILE" $TRANSITION_ARGS
    killall mpvpaper 2>/dev/null
    
    # Se for init, não precisa de delay
    if [[ "$1" != "init" ]]; then sleep 0.7; fi
    
    mpvpaper -o "no-audio --loop-playlist" '*' "$RANDOM_FILE" &
    swww clear --transition-step 255
else
    killall mpvpaper 2>/dev/null
    rm -f "$LOCK_FILE"
    # Converte imagem para 1080p RGBA
    ffmpeg -y -i "$RANDOM_FILE" -vf "scale=1920:-1" -pix_fmt rgba "$LOCK_FILE" > /dev/null 2>&1
    
    reload_system_turbo &
    swww img "$RANDOM_FILE" $TRANSITION_ARGS
fi
