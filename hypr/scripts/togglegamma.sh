#!/bin/bash

# Verifica se o gammastep está ativo (temperatura de cor diferente de 6500K)
if [[ $(gammastep -p | grep "Color temperature" | cut -d' ' -f3) == "6500K" ]]; then
    # Se está em 6500K (desativado), a próxima ação será ATIVAR
    notify-send "Gammastep" "Modo noturno ativado" -t 2000
else
    # Se a temperatura é diferente, a próxima ação será DESATIVAR
    notify-send "Gammastep" "Modo noturno desativado" -t 2000
fi

# Envia o sinal para o gammastep alternar o estado
killall -USR1 gammastep
