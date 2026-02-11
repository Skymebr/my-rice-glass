#!/bin/bash

# 1. Obtém a lista de todos os players (spotify, firefox, etc)
PLAYERS=$(playerctl -l 2>/dev/null)

if [ -z "$PLAYERS" ]; then
    echo ""
    exit 0
fi

# 2. Lógica de Prioridade: "Playing" > "Paused"
# O playerctl padrão pode pegar um pausado (Spotify) em vez do tocando (Firefox).
# Vamos forçar a busca pelo que está tocando agora.

SELECTED_PLAYER=""
PLAYING_PLAYER=""
PAUSED_PLAYER=""

for p in $PLAYERS; do
    STATUS=$(playerctl -p "$p" status 2>/dev/null)
    if [ "$STATUS" == "Playing" ]; then
        PLAYING_PLAYER="$p"
        break # Achamos um tocando! Para a busca.
    elif [ "$STATUS" == "Paused" ]; then
        # Guarda o primeiro pausado que achar como backup
        if [ -z "$PAUSED_PLAYER" ]; then
            PAUSED_PLAYER="$p"
        fi
    fi
done

# Se achou alguém tocando, usa ele. Se não, usa o backup pausado.
if [ -n "$PLAYING_PLAYER" ]; then
    SELECTED_PLAYER="$PLAYING_PLAYER"
else
    SELECTED_PLAYER="$PAUSED_PLAYER"
fi

# Se não selecionou nenhum (ex: todos 'Stopped'), sai.
if [ -z "$SELECTED_PLAYER" ]; then
    echo ""
    exit 0
fi

# 3. Extrai Metadados DO PLAYER SELECIONADO (-p)
PLAYER_NAME=$(playerctl -p "$SELECTED_PLAYER" metadata --format "{{ playerName }}" 2>/dev/null)
ARTIST=$(playerctl -p "$SELECTED_PLAYER" metadata artist 2>/dev/null)
TITLE=$(playerctl -p "$SELECTED_PLAYER" metadata title 2>/dev/null)

# Fallback se metadados estiverem vazios
if [ -z "$ARTIST" ]; then ARTIST=""; fi
if [ -z "$TITLE" ]; then TITLE="Desconhecido"; fi

# 4. Ícones Inteligentes
case "$PLAYER_NAME" in
    "spotify")
        ICON=" " ;;
    "firefox"|"librewolf"|"falkon")
        ICON=" " ;;
    "chromium"|"google-chrome"|"brave")
        ICON=" " ;;
    "mpv"|"vlc"|"celluloid")
        ICON=" " ;;
    "telegram"*)
        ICON=" " ;;
    *)
        ICON=" " ;; # Genérico
esac

TEXT="$ICON $ARTIST - $TITLE"

# Limita tamanho
if [ ${#TEXT} -gt 50 ]; then
    echo "${TEXT:0:50}..."
else
    echo "$TEXT"
fi
