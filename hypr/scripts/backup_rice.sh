#!/bin/bash

# Define caminhos
SOURCE_DIR="$HOME/.config"
BACKUP_DIR="$HOME/meus-dotfiles"

echo "📦 Iniciando Backup do Rice..."

# 1. Atualiza os arquivos (Copia do sistema para a pasta de backup)
# Adicione aqui tudo que você quer salvar
cp -r "$SOURCE_DIR/hypr" "$BACKUP_DIR/"
cp -r "$SOURCE_DIR/kitty" "$BACKUP_DIR/" 2>/dev/null
cp -r "$SOURCE_DIR/matugen" "$BACKUP_DIR/" 2>/dev/null
cp -r "$SOURCE_DIR/fastfetch" "$BACKUP_DIR/" 2>/dev/null
cp -r "$SOURCE_DIR/waybar" "$BACKUP_DIR/" 2>/dev/null
cp -r "$SOURCE_DIR/wofi" "$BACKUP_DIR/" 2>/dev/null
cp -r "$SOURCE_DIR/swaync" "$BACKUP_DIR/" 2>/dev/null
cp "$HOME/.bashrc" "$BACKUP_DIR/.bashrc"
cp "$SOURCE_DIR/starship.toml" "$BACKUP_DIR/starship.toml" 2>/dev/null

# Kernel/System (Como texto)
cp /etc/mkinitcpio.conf "$BACKUP_DIR/etc/mkinitcpio.conf" 2>/dev/null

# 2. Entra na pasta e manda pro Git
cd "$BACKUP_DIR" || exit

echo "gittin..."
git add .

# Cria um commit com a data e hora atual
git commit -m "backup: update automático em $(date '+%Y-%m-%d %H:%M')"

# O SEGREDO: --force garante que o GitHub aceite sem reclamar
git push origin main --force

echo "✅ Backup concluído com sucesso!"
