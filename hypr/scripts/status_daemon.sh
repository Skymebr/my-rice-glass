#!/bin/bash

OUTPUT="/tmp/lock_status"
BAT_PATH="/sys/class/power_supply/BAT1"

get_weather() {
    # Sem flag -4, sem validação complexa. Apenas pega o texto.
    # O 'sed' remove caracteres de escape (cores) caso venham
    curl -s "wttr.in/Manaus?format=%t" | sed 's/\x1b\[[0-9;]*m//g'
}

while true; do
    # 1. BATERIA
    BAT_CAP=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo 0)
    BAT_STAT=$(cat "$BAT_PATH/status" 2>/dev/null)

    if [ "$BAT_STAT" = "Charging" ]; then
        BAT_ICON=""
    elif [ "$BAT_CAP" -le 20 ]; then
        BAT_ICON=""     
    elif [ "$BAT_CAP" -le 100 ]; then
        BAT_ICON=""
    fi
    BAT_TEXT="$BAT_ICON $BAT_CAP%"

    # 2. WI-FI
    SSID=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    [ -n "$SSID" ] && WIFI_TEXT="  $SSID" || WIFI_TEXT="󰤮 Offline"

    # 3. CLIMA (Direto e Reto)
    TEMP=$(get_weather | xargs)
    
    # Se estiver vazio, aí sim mostra ?
    if [ -z "$TEMP" ]; then
         WEATHER_TEXT="  ?"
    else
         WEATHER_TEXT="  $TEMP"
    fi

    # SALVA
    echo "$WEATHER_TEXT   $WIFI_TEXT   $BAT_TEXT" > "$OUTPUT"
    
    # Atualiza a cada 10s
    sleep 10
done
