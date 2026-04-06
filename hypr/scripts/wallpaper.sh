#!/usr/bin/env bash

# --- CONFIGURACAO ---
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/meus-dotfiles/wallpapers}"
CACHE_DIR="$HOME/.cache"
LOCK_FILE="$CACHE_DIR/lock_wallpaper.png"
CURRENT_FILE="$CACHE_DIR/current_wallpaper"
QUEUE_FILE="$CACHE_DIR/wallpaper_queue"
THUMB_DIR="$CACHE_DIR/video_thumbs"

usage() {
    cat <<'EOF'
Usage:
  wallpaper.sh              # random wallpaper
  wallpaper.sh init         # restore cached wallpaper on startup
  wallpaper.sh restore      # reuse cached wallpaper if available
  wallpaper.sh pick FILE [X Y]
  wallpaper.sh print-dir
EOF
}

is_video_extension() {
    case "${1,,}" in
        mp4|mkv|webm) return 0 ;;
        *) return 1 ;;
    esac
}

set_transition_args() {
    local mode="$1"
    local x="$2"
    local y="$3"

    if [[ "$mode" == "init" ]]; then
        TRANSITION_ARGS=(--transition-step 255 --transition-fps 120)
        SKIP_ANIMATION=true
        return
    fi

    if [[ "$mode" == "pick" ]]; then
        TRANSITION_ARGS=(
            --transition-type grow
            --transition-pos "${x},${y}"
            --transition-step 40
            --transition-duration 0.7
            --transition-fps 120
            --transition-bezier 0.65,0,0.35,1
        )
        SKIP_ANIMATION=false
        return
    fi

    TRANSITION_ARGS=(
        --transition-type outer
        --transition-pos 0.9,0.9
        --transition-duration 0.7
        --transition-fps 120
        --transition-bezier 0.65,0,0.35,1
    )
    SKIP_ANIMATION=false
}

wait_for_swww() {
    local attempt
    local query_output

    for ((attempt = 0; attempt < 50; attempt++)); do
        query_output=$(swww query 2>/dev/null || true)
        if [[ -n "$query_output" ]]; then
            return 0
        fi
        sleep 0.1
    done

    return 1
}

remove_from_queue() {
    local selected="$1"
    local temp_file="$QUEUE_FILE.tmp"

    [[ -f "$QUEUE_FILE" ]] || return 0
    grep -Fxv -- "$selected" "$QUEUE_FILE" > "$temp_file" || true
    mv "$temp_file" "$QUEUE_FILE"
}

generate_video_thumb() {
    local source="$1"
    local thumb="$2"

    ffmpeg -y -i "$source" -ss 00:00:01 -vframes 1 -vf "scale=1920:-1" -v error "$thumb" \
        || ffmpeg -y -i "$source" -vframes 1 -vf "scale=1920:-1" -v error "$thumb"
}

update_system_theme() {
    local img_source="$1"
    local media_type="$2"
    local hypr_colors="$HOME/.config/hypr/colors.conf"

    if [[ "$media_type" == "video" ]]; then
        cp "$img_source" "$LOCK_FILE"
    else
        nice -n 19 ffmpeg -y -i "$img_source" -vf "scale=1920:-1" -pix_fmt rgba "$LOCK_FILE" -v error
    fi

    if command -v matugen &>/dev/null; then
        matugen image "$LOCK_FILE" --quiet
    fi

    {
        pkill -SIGUSR2 waybar || (killall waybar; waybar & disown)
        command -v pywalfox &>/dev/null && pywalfox update
        killall -SIGUSR1 kitty
        pkill -SIGUSR1 cava
        swaync-client -rs
        pkill wofi

        if pgrep -x "spotify" >/dev/null; then
            spicetify apply -n -q
            pkill -x spotify
            sleep 0.5
            spotify & disown
        fi
    } 2>/dev/null &

    if [[ -f "$hypr_colors" ]]; then
        eval "$(awk '
            /primary.default.hex/ { print \"NEW_BORDER=0xff\" substr($3, 2) }
            /surface.default.hex/ { print \"NEW_INACTIVE=0xff\" substr($3, 2) }
        ' "$hypr_colors")"

        if [[ -n "${NEW_BORDER:-}" ]]; then
            hyprctl keyword general:col.active_border "$NEW_BORDER" >/dev/null
            hyprctl keyword general:col.inactive_border "$NEW_INACTIVE" >/dev/null
        fi
    fi
}

MODE="${1:-random}"

case "$MODE" in
    print-dir)
        printf '%s\n' "$WALLPAPER_DIR"
        exit 0
        ;;
    help|-h|--help)
        usage
        exit 0
        ;;
esac

mkdir -p "$CACHE_DIR" "$THUMB_DIR"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    exit 1
fi

set_transition_args "$MODE" "${3:-0.500}" "${4:-0.500}"

if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon --format xrgb &
fi

if ! wait_for_swww; then
    printf 'wallpaper.sh: swww-daemon not ready\n' >&2
    exit 1
fi

RANDOM_FILE=""

if [[ "$MODE" == "pick" ]]; then
    RANDOM_FILE="${2:-}"
    if [[ -z "$RANDOM_FILE" || ! -f "$RANDOM_FILE" ]]; then
        printf 'wallpaper.sh: invalid pick target\n' >&2
        exit 1
    fi
    remove_from_queue "$RANDOM_FILE"
elif [[ ( "$MODE" == "restore" || "$MODE" == "init" ) && -f "$CURRENT_FILE" ]]; then
    RANDOM_FILE=$(<"$CURRENT_FILE")
fi

if [[ -z "$RANDOM_FILE" || ! -f "$RANDOM_FILE" ]]; then
    if [[ ! -s "$QUEUE_FILE" ]]; then
        find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" -o -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" \) | shuf > "$QUEUE_FILE"
    fi
    IFS= read -r RANDOM_FILE < "$QUEUE_FILE"
    sed -i '1d' "$QUEUE_FILE"
fi

if [[ -z "$RANDOM_FILE" ]]; then
    exit 1
fi

printf '%s\n' "$RANDOM_FILE" > "$CURRENT_FILE"

EXT="${RANDOM_FILE##*.}"
EXT="${EXT,,}"

if is_video_extension "$EXT"; then
    HASH_NAME=$(echo -n "$RANDOM_FILE" | md5sum | cut -d" " -f1)
    THUMB_FILE="$THUMB_DIR/$HASH_NAME.png"

    if [[ ! -f "$THUMB_FILE" ]]; then
        generate_video_thumb "$RANDOM_FILE" "$THUMB_FILE"
    fi

    update_system_theme "$THUMB_FILE" "video" &

    swww img "$THUMB_FILE" "${TRANSITION_ARGS[@]}" --resize crop

    killall mpvpaper 2>/dev/null
    if [[ "$SKIP_ANIMATION" == "false" ]]; then
        sleep 0.6
    fi

    mpvpaper -p -o "no-audio --loop-playlist --hwdec=auto-safe --vo=gpu" '*' "$RANDOM_FILE" &
else
    killall mpvpaper 2>/dev/null
    update_system_theme "$RANDOM_FILE" "image" &
    swww img "$RANDOM_FILE" "${TRANSITION_ARGS[@]}" --resize crop
fi
