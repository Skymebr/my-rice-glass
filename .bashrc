#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias cursor='~/Applications/cursor.AppImage --no-sandbox'
PS1='[\u@\h \W]\$ '

# --- CARREGAMENTO OTIMIZADO DO ANACONDA ---
# Isso faz o terminal abrir instantaneamente. 
# O Conda só será carregado de fato quando você digitar "conda" pela primeira vez.
conda() {
    unset -f conda
    if [ -f "/opt/anaconda/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda/bin:$PATH"
    fi
    conda "$@"
}

eval "$(starship init bash)"
