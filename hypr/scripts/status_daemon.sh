#!/bin/bash

# --- CONFIGURAÇÃO ---
OUTPUT="/tmp/lock_status"
WEATHER_CACHE="/tmp/weather.cache"
BAT_PATH="/sys/class/power_supply/BAT1" # BAT0 ou BAT1
CITY_LAT="-3.107"
CITY_LON="-60.026"

# --- FUNÇÃO CLIMA (Open-Meteo) ---
update_weather() {
    # Baixa JSON
    RAW_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${CITY_LAT}&longitude=${CITY_LON}&current_weather=true&timezone=America%2FManaus")
    
    # Extrai temperatura
    TEMP_FLOAT=$(echo "$RAW_JSON" | grep -oE '"temperature":[0-9.]+' | sed 's/[^0-9.]//g')
    
    # Arredonda (27.8 -> 28)
    if [ -n "$TEMP_FLOAT" ]; then
        TEMP_INT=$(printf "%.0f" "$TEMP_FLOAT")
        echo "${TEMP_INT}°C" > "$WEATHER_CACHE"
    fi
}

# --- INICIALIZAÇÃO ---
if [ ! -f "$WEATHER_CACHE" ]; then
    echo "..." > "$WEATHER_CACHE"
    update_weather & 
fi

COUNTER=180

while true; do
    
    # 1. CLIMA (30 min)
    if [ $COUNTER -ge 180 ]; then
        update_weather &
        COUNTER=0
    fi
    let COUNTER++
    
    # Lê Cache
    if [ -f "$WEATHER_CACHE" ]; then
        TEMP_VAL=$(cat "$WEATHER_CACHE")
    else
        TEMP_VAL="?"
    fi
    
    # Se erro, esconde
    if [[ "$TEMP_VAL" == *"?"* ]] || [[ "$TEMP_VAL" == *"..."* ]]; then
        WEATHER_TEXT=""
    else
        WEATHER_TEXT="  $TEMP_VAL"
    fi

    # 2. BATERIA
    if [ -d "$BAT_PATH" ]; then
        BAT_CAP=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo 0)
        BAT_STAT=$(cat "$BAT_PATH/status" 2>/dev/null)

        if [ "$BAT_STAT" = "Charging" ]; then
            BAT_ICON=""
        else
            if   [ "$BAT_CAP" -ge 90 ]; then BAT_ICON=""
            elif [ "$BAT_CAP" -ge 60 ]; then BAT_ICON=""
            elif [ "$BAT_CAP" -ge 40 ]; then BAT_ICON=""
            elif [ "$BAT_CAP" -ge 10 ]; then BAT_ICON=""
            else BAT_ICON=""; fi
        fi
        BAT_TEXT="$BAT_ICON $BAT_CAP%"
    else
        BAT_TEXT=""
    fi

    # 3. WI-FI
    SSID=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    if [ -n "$SSID" ]; then
        WIFI_TEXT="  $SSID"
    else
        WIFI_TEXT="󰤮 Offline"
    fi

    # 4. MONTAGEM (SEM BARRAS)
    FINAL_STR=""
    
    # Adiciona Clima
    [ -n "$WEATHER_TEXT" ] && FINAL_STR="$WEATHER_TEXT"
    
    # Adiciona Wi-Fi (com 4 espaços de separação)
    if [ -n "$WIFI_TEXT" ]; then
        [ -n "$FINAL_STR" ] && FINAL_STR="$FINAL_STR    "
        FINAL_STR="$FINAL_STR$WIFI_TEXT"
    fi
    
    # Adiciona Bateria (com 4 espaços de separação)
    if [ -n "$BAT_TEXT" ]; then
        [ -n "$FINAL_STR" ] && FINAL_STR="$FINAL_STR    "
        FINAL_STR="$FINAL_STR$BAT_TEXT"
    fi

    echo "$FINAL_STR" > "$OUTPUT"
    
    sleep 10
done
