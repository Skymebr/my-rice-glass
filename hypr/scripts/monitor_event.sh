#!/bin/bash

# Define a função que recarrega o Waybar
handle_monitor_change() {
    echo "Monitor detectado! Reiniciando Waybar..."
    # Mata o waybar e inicia de novo (desvinculado do terminal)
    killall waybar
    sleep 1
    waybar & disown
}

# Conecta no soquete do Hyprland e escuta eventos
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    # Se o evento for "monitoradded" (plugou) ou "monitorremoved" (tirou)
    if [[ "$line" == "monitoradded>>"* ]] || [[ "$line" == "monitorremoved>>"* ]]; then
        handle_monitor_change
    fi
done
