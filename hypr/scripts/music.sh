#!/bin/bash

# 1. Obtém a lista de todos os players
PLAYERS=$(playerctl -l 2>/dev/null)

if [ -z "$PLAYERS" ]; then
    echo ""
    exit 0
fi

SELECTED_PLAYER=""
PLAYING_PLAYER=""
PAUSED_PLAYER=""

for p in $PLAYERS; do
    STATUS=$(playerctl -p "$p" status 2>/dev/null)
    if [ "$STATUS" == "Playing" ]; then
        PLAYING_PLAYER="$p"
        break
    elif [ "$STATUS" == "Paused" ]; then
        if [ -z "$PAUSED_PLAYER" ]; then
            PAUSED_PLAYER="$p"
        fi
    fi
done

if [ -n "$PLAYING_PLAYER" ]; then
    SELECTED_PLAYER="$PLAYING_PLAYER"
else
    SELECTED_PLAYER="$PAUSED_PLAYER"
fi

if [ -z "$SELECTED_PLAYER" ]; then
    echo ""
    exit 0
fi

PLAYER_NAME=$(playerctl -p "$SELECTED_PLAYER" metadata --format "{{ playerName }}" 2>/dev/null)
ARTIST=$(playerctl -p "$SELECTED_PLAYER" metadata artist 2>/dev/null)
TITLE=$(playerctl -p "$SELECTED_PLAYER" metadata title 2>/dev/null)

if [ -z "$ARTIST" ]; then ARTIST="Artista Desconhecido"; fi
if [ -z "$TITLE" ]; then TITLE="Música Desconhecida"; fi

case "$PLAYER_NAME" in
    "spotify") ICON=" " ;;
    "firefox"|"librewolf"|"falkon") ICON=" " ;;
    "chromium"|"google-chrome"|"brave") ICON=" " ;;
    "mpv"|"vlc"|"celluloid") ICON=" " ;;
    *) ICON=" " ;;
esac

# Usando Pango Markup para estilo
echo "$ICON <span style='italic' foreground='#a6adc8'>$ARTIST</span> - <b>$TITLE</b>"
