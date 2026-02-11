# AGENTS.md

## Project Overview

**my-rice-glass** é uma customização (rice) de desktop Linux focada em estética de vidro/glassmorphism para Hyprland.

## Tech Stack

- **Window Manager**: Hyprland (Wayland compositor)
- **Bar**: Waybar
- **Terminal**: (a definir - provavelmente kitty ou alacritty)
- **Shell**: Bash/Zsh
- **Theme Generator**: Matugen (Material You generator)
- **Fonte de ícones**: Font Awesome, Nerd Fonts

## Project Structure

```
my-rice-glass/
├── hypr/           # Configurações do Hyprland
├── waybar/         # Configurações e estilos do Waybar
├── kitty/          # Configuração do terminal Kitty
├── rofi/           # Launcher e menus
├── mako/           # Notificações
├── scripts/        # Scripts auxiliares
└── wallpapers/     # Papeis de parede
```

## Key Scripts

- `rice-backup.sh` - Backup da configuração atual
- `audit-wallpaper-setup.sh` - Configuração de wallpapers

## Design Philosophy

- Glassmorphism (transparência + blur)
- Cores dinâmicas baseadas no wallpaper (via Matugen)
- Minimalismo funcional

## Notes for AI Assistants

- Sempre verifique se os caminhos de configuração seguem o padrão XDG (`~/.config/`)
- Teste scripts em ambiente seguro antes de aplicar
- Mantenha consistência visual com o tema glassmorphism
- Prefira symlink para arquivos de configuração ao invés de copiar
