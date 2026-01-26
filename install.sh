#!/bin/bash

# ====================================================================
# my-rice-glass: Script de Instalação Simplificado
# Este script automatiza a criação de links simbólicos para os dotfiles
# na pasta ~/.config/ e corrige o caminho hardcoded no hyprland.conf.
# ====================================================================

DOTFILES_DIR="$(pwd)"
CONFIG_DIR="$HOME/.config"
HYPR_CONFIG="$DOTFILES_DIR/hypr/hyprland.conf"

# --------------------------------------------------------------------
# 1. FUNÇÃO DE LOG
# --------------------------------------------------------------------
log() {
    echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

# --------------------------------------------------------------------
# 2. FUNÇÃO DE DEPENDÊNCIAS
# --------------------------------------------------------------------
list_dependencies() {
    log "DEPENDÊNCIAS NECESSÁRIAS"
    echo "--------------------------------------------------------------------"
    echo "Este script NÃO instala pacotes. Você deve instalar manualmente:"
    echo "Hyprland, Waybar, Kitty, Wofi, SwayNC, Swww, Matugen, Hyprlock,"
    echo "Thunar, Hyprshot, playerctl, brightnessctl, wpctl, ffmpeg (para vídeos)."
    echo "--------------------------------------------------------------------"
    read -p "Pressione [Enter] para continuar..."
}

# --------------------------------------------------------------------
# 3. FUNÇÃO DE CRIAÇÃO DE LINKS SIMBÓLICOS
# --------------------------------------------------------------------
create_symlinks() {
    log "CRIANDO LINKS SIMBÓLICOS"
    
    # Lista de diretórios a serem linkados
    declare -a DIRS=("hypr" "kitty" "matugen" "swaync" "waybar" "wofi")
    
    for dir in "${DIRS[@]}"; do
        SOURCE="$DOTFILES_DIR/$dir"
        TARGET="$CONFIG_DIR/$dir"
        
        if [ -d "$TARGET" ]; then
            echo "  - $TARGET já existe. Fazendo backup para $TARGET.bak"
            mv "$TARGET" "$TARGET.bak"
        fi
        
        echo "  - Criando link: $SOURCE -> $TARGET"
        ln -s "$SOURCE" "$TARGET"
    done
    
    # Link especial para o starship.toml
    if [ -f "$DOTFILES_DIR/starship.toml" ]; then
        if [ -f "$HOME/.config/starship.toml" ]; then
            echo "  - $HOME/.config/starship.toml já existe. Fazendo backup para $HOME/.config/starship.toml.bak"
            mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
        fi
        echo "  - Criando link: $DOTFILES_DIR/starship.toml -> $HOME/.config/starship.toml"
        ln -s "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
    fi
}

# --------------------------------------------------------------------
# 4. FUNÇÃO DE CORREÇÃO DE CAMINHO
# --------------------------------------------------------------------
fix_hyprland_path() {
    log "CORRIGINDO CAMINHO DO SCRIPT DE WALLPAPER"
    
    # O caminho hardcoded no hyprland.conf é:
    # exec-once = /home/skyme/meus-dotfiles/hypr/scripts/wallpaper.sh init
    
    # O novo caminho deve ser:
    NEW_PATH="$DOTFILES_DIR/hypr/scripts/wallpaper.sh init"
    
    # Escapando barras para o sed
    ESCAPED_NEW_PATH=$(echo "$NEW_PATH" | sed 's/\//\\\//g')
    
    # Usando sed para substituir a linha 81 no arquivo de configuração
    # A linha 81 é: exec-once = /home/skyme/meus-dotfiles/hypr/scripts/wallpaper.sh init
    
    # Primeiro, vamos garantir que o arquivo existe e é editável
    if [ ! -f "$HYPR_CONFIG" ]; then
        echo "ERRO: Arquivo $HYPR_CONFIG não encontrado. Abortando correção de caminho."
        return 1
    fi
    
    # Substitui a linha 81 (ou a linha que contém o padrão)
    sed -i "s|^exec-once = /home/skyme/meus-dotfiles/hypr/scripts/wallpaper.sh init|exec-once = $ESCAPED_NEW_PATH|" "$HYPR_CONFIG"
    
    if [ $? -eq 0 ]; then
        echo "  - Caminho corrigido em $HYPR_CONFIG para:"
        echo "    exec-once = $NEW_PATH"
    else
        echo "  - Aviso: Não foi possível corrigir o caminho automaticamente. Verifique a linha 81 de $HYPR_CONFIG manualmente."
    fi
}

# --------------------------------------------------------------------
# 5. EXECUÇÃO PRINCIPAL
# --------------------------------------------------------------------
main() {
    echo "===================================================================="
    echo "  INICIANDO INSTALAÇÃO DE DOTFILES my-rice-glass"
    echo "===================================================================="
    
    # Garante que estamos no diretório correto
    if [ ! -d "$DOTFILES_DIR/hypr" ]; then
        echo "ERRO: Execute este script dentro do diretório my-rice-glass."
        exit 1
    fi
    
    # Cria a pasta .config se não existir
    mkdir -p "$CONFIG_DIR"
    
    list_dependencies
    create_symlinks
    fix_hyprland_path
    
    log "INSTALAÇÃO CONCLUÍDA!"
    echo "--------------------------------------------------------------------"
    echo "1. Certifique-se de que todas as dependências foram instaladas."
    echo "2. O caminho do script de wallpaper foi corrigido em hyprland.conf."
    echo "3. Se você fez backup de arquivos existentes, verifique-os em *.bak."
    echo "4. Reinicie o Hyprland ou o computador para aplicar as mudanças."
    echo "--------------------------------------------------------------------"
}

main
