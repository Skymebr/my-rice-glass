#!/bin/bash

# --- CONFIGURAÇÃO ---
WALLPAPER_DIR="$HOME/meus-dotfiles/wallpapers"
CACHE_DIR="$HOME/.cache"
LOCK_FILE="$CACHE_DIR/lock_wallpaper.png"
CURRENT_FILE="$CACHE_DIR/current_wallpaper"
QUEUE_FILE="$CACHE_DIR/wallpaper_queue"
THUMB_DIR="$CACHE_DIR/video_thumbs"

# Cria pastas automaticamente
mkdir -p "$CACHE_DIR" "$THUMB_DIR"

# --- LÓGICA DE TRANSIÇÃO ---
if [[ "$1" == "init" ]]; then
    TRANSITION_ARGS="--transition-step 255 --transition-fps 120"
    SKIP_ANIMATION=true
else
    # Transição suave padrão
    TRANSITION_ARGS="--transition-type outer --transition-pos 0.9,0.9 --transition-duration 0.7 --transition-fps 120 --transition-bezier 0.65,0,0.35,1"
    SKIP_ANIMATION=false
fi

if [ ! -d "$WALLPAPER_DIR" ]; then exit 1; fi

# Inicia daemon
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon --format xrgb &
fi

# --- SELEÇÃO DO ARQUIVO ---
RANDOM_FILE=""
if [[ "$1" == "restore" || "$1" == "init" ]] && [ -f "$CURRENT_FILE" ]; then
    RANDOM_FILE=$(cat "$CURRENT_FILE")
fi

if [ -z "$RANDOM_FILE" ] || [ ! -f "$RANDOM_FILE" ]; then
    if [ ! -s "$QUEUE_FILE" ]; then
        find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" \) | shuf > "$QUEUE_FILE"
    fi
    RANDOM_FILE=$(head -n 1 "$QUEUE_FILE")
    sed -i '1d' "$QUEUE_FILE"
fi

if [ -z "$RANDOM_FILE" ]; then exit 1; fi
echo "$RANDOM_FILE" > "$CURRENT_FILE"

EXT="${RANDOM_FILE##*.}"
EXT="${EXT,,}"

# --- FUNÇÃO BACKGROUND (Gera cores e lockscreen) ---
update_system_theme() {
    local img_source="$1"
    local type="$2" 
    
    # 1. Atualiza Lockscreen
    if [ "$type" == "video" ]; then
        cp "$img_source" "$LOCK_FILE"
    else
        # Apenas converte para o formato do lockscreen, mantendo proporção
        nice -n 19 ffmpeg -y -i "$img_source" -vf "scale=1920:-1" -pix_fmt rgba "$LOCK_FILE" -v error
    fi

    # 2. Matugen (Cores)
    if command -v matugen &> /dev/null; then
        matugen image "$LOCK_FILE" --quiet
    fi

    # 3. Atualiza Apps
    {
        pkill -SIGUSR2 waybar || (killall waybar; waybar & disown)
        command -v pywalfox &> /dev/null && pywalfox update
        killall -SIGUSR1 kitty
        pkill -SIGUSR1 cava
        swaync-client -rs
        pkill wofi
        
        if pgrep -x "spotify" > /dev/null; then
             spicetify apply -n -q
             pkill -x spotify
             sleep 0.5 
             spotify & disown
        fi
    } 2>/dev/null &

    # 4. Bordas Hyprland
    local HYPR_COLORS="$HOME/.config/hypr/colors.conf"
    if [ -f "$HYPR_COLORS" ]; then
        eval $(awk '
            /primary.default.hex/ { print "NEW_BORDER=0xff" substr($3, 2) }
            /surface.default.hex/ { print "NEW_INACTIVE=0xff" substr($3, 2) }
        ' "$HYPR_COLORS")
        
        if [ -n "$NEW_BORDER" ]; then
            hyprctl keyword general:col.active_border "$NEW_BORDER" > /dev/null
            hyprctl keyword general:col.inactive_border "$NEW_INACTIVE" > /dev/null
        fi
    fi
}

# --- APLICAÇÃO VISUAL ---

if [[ "$EXT" == "mp4" || "$EXT" == "mkv" || "$EXT" == "webm" ]]; then
    # -- VÍDEO --
    HASH_NAME=$(echo -n "$RANDOM_FILE" | md5sum | cut -d" " -f1)
    THUMB_FILE="$THUMB_DIR/$HASH_NAME.png"

    if [ ! -f "$THUMB_FILE" ]; then
        ffmpeg -i "$RANDOM_FILE" -ss 00:00:01 -vframes 1 -vf "scale=1920:-1" -v error -y "$THUMB_FILE"
    fi

    update_system_theme "$THUMB_FILE" "video" &

    swww img "$THUMB_FILE" $TRANSITION_ARGS --resize crop
    
    killall mpvpaper 2>/dev/null
    if [[ "$SKIP_ANIMATION" == "false" ]]; then sleep 0.6; fi
    
    # Vídeo: Mantém proporção correta (sem esticar)
    mpvpaper -p -o "no-audio --loop-playlist --hwdec=auto-safe --vo=gpu" '*' "$RANDOM_FILE" & 

else
    # -- IMAGEM --
    killall mpvpaper 2>/dev/null
    
    update_system_theme "$RANDOM_FILE" "image" &
    
    # SIMPLES E DIRETO:
    # Usa --resize crop como segurança (para 4K virar 1080p sem bordas pretas)
    # Se você já editou a imagem para 1920x1080, isso não faz nada (fica perfeito).
    swww img "$RANDOM_FILE" $TRANSITION_ARGS --resize crop
fi
