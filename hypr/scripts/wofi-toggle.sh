#!/bin/bash

set -euo pipefail

if pgrep -x wofi >/dev/null 2>&1; then
    pkill -x wofi
    exit 0
fi

exec wofi --show drun --allow-images --width 500 --height 900
