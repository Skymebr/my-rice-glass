#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/my-rice-glass/quickshell/glass-bar"
CONFIG_PATH="$CONFIG_DIR/shell.qml"

usage() {
    cat <<'EOF'
Usage:
  glass-bar.sh start|stop|restart|toggle|status
EOF
}

start_bar() {
    qs -n -p "$CONFIG_PATH" -d
}

stop_bar() {
    qs kill -p "$CONFIG_PATH" --any-display >/dev/null 2>&1 || true
}

case "${1:-toggle}" in
    start)
        start_bar
        ;;
    stop)
        stop_bar
        ;;
    restart)
        stop_bar
        sleep 0.2
        start_bar
        ;;
    toggle)
        if qs kill -p "$CONFIG_PATH" --any-display >/dev/null 2>&1; then
            exit 0
        fi
        start_bar
        ;;
    status)
        qs list --all
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
