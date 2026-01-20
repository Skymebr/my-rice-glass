#!/bin/bash
HOUR=$(date +%H)
USER_NAME="Skyme"

if [ $HOUR -ge 05 ] && [ $HOUR -lt 12 ]; then
    echo "Bom dia, $USER_NAME ☕"
elif [ $HOUR -ge 12 ] && [ $HOUR -lt 18 ]; then
    echo "Boa tarde, $USER_NAME ☀"
elif [ $HOUR -ge 18 ] && [ $HOUR -lt 23 ]; then
    echo "Boa noite, $USER_NAME 🌙"
else
    echo "Vá dormir, $USER_NAME !"
fi
