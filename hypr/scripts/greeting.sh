#!/bin/bash
HOUR=$(date +%H)
USER_NAME="Skyme"

# Definindo cores (mesmas do hyprlock.conf para consistência)
MAUVE="cba6f7"

if [ $HOUR -ge 05 ] && [ $HOUR -lt 12 ]; then
    GREET="Bom dia"
    ICON="☕"
elif [ $HOUR -ge 12 ] && [ $HOUR -lt 18 ]; then
    GREET="Boa tarde"
    ICON="☀"
elif [ $HOUR -ge 18 ] && [ $HOUR -lt 23 ]; then
    GREET="Boa noite"
    ICON="🌙"
else
    GREET="Vá dormir"
    ICON="💤"
fi

echo "$GREET, <span foreground='#$MAUVE'>$USER_NAME</span> $ICON"
