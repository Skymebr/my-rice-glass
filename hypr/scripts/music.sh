#!/bin/bash

# Verifica se tem player rodando
STATUS=$(playerctl status 2>/dev/null)

# Se estiver tocando ou pausado
if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
    # Pega os dados
    ARTIST=$(playerctl metadata artist 2>/dev/null)
    TITLE=$(playerctl metadata title 2>/dev/null)
    
    # Formata: Ícone + Texto
    TEXT="  $ARTIST - $TITLE"
    
    # Limita o tamanho para não quebrar o layout
    if [ ${#TEXT} -gt 50 ]; then
        echo "${TEXT:0:50}..."
    else
        echo "$TEXT"
    fi
fi
