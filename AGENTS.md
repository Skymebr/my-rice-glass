# AGENTS.md

## Project Overview

**my-rice-glass** é uma customização (rice) de desktop Linux focada em estética de vidro/glassmorphism para Hyprland no Wayland.

## Tech Stack

- **Window Manager**: Hyprland (Wayland compositor)
- **Bar**: Waybar
- **Terminal**: Kitty
- **Launcher**: Wofi
- **Notifications**: SwayNC
- **Wallpaper**: swww (wayland wallpaper daemon)
- **Lock Screen**: Hyprlock
- **Shell**: Bash
- **Cursor**: Bibata-Modern-Ice
- **Icon Theme**: Papirus-Dark
- **GTK Theme**: Adwaita-dark

## Project Structure

```
my-rice-glass/
├── AGENTS.md                 # Este arquivo - guia para IA
├── hypr/
│   ├── hyprland.conf         # Configuração principal do Hyprland
│   ├── hyprlock.conf         # Tela de bloqueio "Semantic Glass"
│   ├── colors.conf           # Cores dinâmicas das bordas
│   └── scripts/              # Scripts auxiliares
│       ├── wallpaper.sh          # Gerenciamento de wallpapers
│       ├── status_daemon.sh      # Daemon de status do sistema
│       ├── music.sh              # Info de música para lock screen
│       ├── greeting.sh           # Saudação dinâmica
│       ├── monitor_event.sh      # Eventos de hotplug de monitores
│       ├── backup_rice.sh        # Backup da configuração
│       ├── restore_wallpaper.sh  # Restauração de wallpaper
│       ├── sync-lock.sh          # Sincroniza lock screen
│       ├── togglegamma.sh        # Toggle gammastep
│       └── cancel_menu.sh        # Cancela menu de energia
```

## Key Features

### Hyprland Config (`hypr/hyprland.conf`)
- **Dual Monitor Setup**: Projetor (HDMI-A-1, 720p) + Notebook (eDP-1, 1080p)
- **Glassmorphism**: Transparência 94% ativo / 86% inativo, blur 6px, rounding 12px
- **Animações**: EaseOutQuint, popin, slide workspaces
- **Keybinds**:
  - `SUPER + Q` → Terminal (kitty)
  - `SUPER + B` → Firefox
  - `SUPER + E` → Thunar
  - `SUPER + Space` → Wofi launcher
  - `SUPER + W` → Trocar wallpaper
  - `SUPER + X` → Menu de energia (power menu)
  - `Print` → Screenshot com hyprshot

### Hyprlock Config (`hypr/hyprlock.conf`)
- Tema "Semantic Glass" com Catppuccin colors
- Avatar circular com borda sapphire
- Relógio grande, data, saudação dinâmica
- Info de música (playerctl)
- Status do sistema

### Scripts Importantes

| Script | Função |
|--------|--------|
| `wallpaper.sh` | Gerencia wallpapers com swww, gera cores com matugen |
| `status_daemon.sh` | Atualiza status em `/tmp/lock_status` |
| `music.sh` | Retorna info da música atual para lock screen |
| `greeting.sh` | Saudação baseada na hora do dia |
| `monitor_event.sh` | Detecta conexão/desconexão de monitores |

## Instalação/Setup

```bash
# 1. Clone o repositório
git clone https://github.com/Skymebr/my-rice-glass.git
cd my-rice-glass

# 2. Crie symlinks (exemplo para hypr)
ln -sf $(pwd)/hypr ~/.config/hypr

# 3. Instale dependências (Arch Linux)
# hyprland, hyprlock, waybar, wofi, swaync, swww, kitty, hyprshot
```

## Design Philosophy

- **Glassmorphism**: Transparência + blur + bordas suaves
- **Cores dinâmicas**: Matugen gera paleta baseada no wallpaper
- **Minimalismo funcional**: Interface limpa, atalhos eficientes
- **Dual monitor**: Config otimizada para projetor + notebook

## Notes for AI Assistants

- Os scripts assumem que o usuário é `skyme` e home é `/home/skyme`
- Wallpapers são cacheados em `~/.cache/swww/` e `~/.cache/lock_wallpaper.png`
- O script `wallpaper.sh` referencia caminho absoluto: `/home/skyme/meus-dotfiles/hypr/scripts/wallpaper.sh init`
- Para novos usuários, ajustar paths absolutos nos scripts
- Waybar é iniciada pelo `wallpaper.sh init`, não diretamente no hyprland.conf

## GitHub

Repositório: https://github.com/Skymebr/my-rice-glass.git
