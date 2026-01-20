#!/bin/bash
# Pega o wallpaper atual do swww e converte para hyprlock
swww query | grep -oP 'image: \K.*' | while read -r img; do
    magick "$img" -resize 1920x1080^ -gravity center -extent 1920x1080 ~/.cache/lock_wallpaper.png
done
