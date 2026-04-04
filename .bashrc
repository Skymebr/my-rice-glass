[[ $- != *i* ]] && return

add_paths() {
    local d
    for d in "$@"; do
        [[ -d "$d" && ":$PATH:" != *":$d:"* ]] && PATH="$PATH:$d"
    done
}

add_paths "$HOME/.local/bin" "$HOME/.opencode/bin" "$HOME/.npm-global/bin"
export PATH

export OLLAMA_NUM_THREADS=16
export OLLAMA_KEEP_ALIVE=30m

conda() {
    unset -f conda
    if [[ -f "/opt/anaconda/etc/profile.d/conda.sh" ]]; then
        . "/opt/anaconda/etc/profile.d/conda.sh"
    elif [[ -d "/opt/anaconda/bin" ]]; then
        add_paths "/opt/anaconda/bin"
        export PATH
    fi
    conda "$@"
}

alias cursor='$HOME/Applications/cursor.AppImage --no-sandbox'
alias updot='$HOME/.config/hypr/scripts/backup_rice.sh'
alias manim-proj='cd "$HOME/ManimProjects"'
alias manim-env='source "$HOME/venvs/manim-env/bin/activate"'
alias steam='steam -tcp'

[[ -r "$HOME/.local/share/bash-completion/completions/ai" ]] && source "$HOME/.local/share/bash-completion/completions/ai"

if command -v fish >/dev/null 2>&1 && [[ "${SKIP_FISH:-0}" != 1 ]] && [[ ${SHLVL:-0} -le 2 ]] && grep -qv fish "/proc/$PPID/comm" 2>/dev/null; then
    exec fish
fi

PS1='[\u@\h \W]\$ '
