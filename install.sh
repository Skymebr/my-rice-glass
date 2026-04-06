#!/bin/bash

# ====================================================================
# my-rice-glass: Simplified Installation Script
# This script automates the creation of symbolic links for dotfiles
# in the ~/.config/ folder.
# ====================================================================

DOTFILES_DIR="$(pwd)"
CONFIG_DIR="$HOME/.config"

# --------------------------------------------------------------------
# 1. LOGGING FUNCTION
# --------------------------------------------------------------------
log() {
    echo -e "\n\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

# --------------------------------------------------------------------
# 2. DEPENDENCIES FUNCTION
# --------------------------------------------------------------------
list_dependencies() {
    log "REQUIRED DEPENDENCIES"
    echo "--------------------------------------------------------------------"
    echo "This script DOES NOT install packages. You must install them manually:"
    echo "Hyprland, Waybar, Kitty, Wofi, SwayNC, Swww, Matugen, Hyprlock,"
    echo "Thunar, Hyprshot, playerctl, brightnessctl, wpctl, ffmpeg (for videos)."
    echo "--------------------------------------------------------------------"
    read -p "Press [Enter] to continue..."
}

# --------------------------------------------------------------------
# 3. SYMBOLIC LINK CREATION FUNCTION
# --------------------------------------------------------------------
create_symlinks() {
    log "CREATING SYMBOLIC LINKS"
    
    # List of directories to be linked
    declare -a DIRS=("fastfetch" "hypr" "kitty" "matugen" "skywall" "swaync" "waybar" "wofi" "gtk-3.0" "gtk-4.0")
    
    for dir in "${DIRS[@]}"; do
        SOURCE="$DOTFILES_DIR/$dir"
        TARGET="$CONFIG_DIR/$dir"
        
        if [ -d "$TARGET" ]; then
            echo "  - $TARGET already exists. Backing up to $TARGET.bak"
            mv "$TARGET" "$TARGET.bak"
        fi
        
        echo "  - Creating link: $SOURCE -> $TARGET"
        ln -s "$SOURCE" "$TARGET"
    done
    
    # Special link for starship.toml
    if [ -f "$DOTFILES_DIR/starship.toml" ]; then
        if [ -f "$HOME/.config/starship.toml" ]; then
            echo "  - $HOME/.config/starship.toml already exists. Backing up to $HOME/.config/starship.toml.bak"
            mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
        fi
        echo "  - Creating link: $DOTFILES_DIR/starship.toml -> $HOME/.config/starship.toml"
        ln -s "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
    fi
}

# --------------------------------------------------------------------
# 4. CONFIG VALIDATION FUNCTION
# --------------------------------------------------------------------
validate_hyprland_config() {
    log "VALIDATING HYPRLAND CONFIG"

    if grep -q '^exec-once = ~/.config/hypr/scripts/wallpaper.sh init$' "$DOTFILES_DIR/hypr/hyprland.conf"; then
        echo "  - Wallpaper script path already points to ~/.config/hypr/scripts/wallpaper.sh"
    else
        echo "  - Warning: hypr/hyprland.conf no longer matches the expected wallpaper startup path."
    fi
}

# --------------------------------------------------------------------
# 5. MAIN EXECUTION
# --------------------------------------------------------------------
main() {
    echo "===================================================================="
    echo "  STARTING my-rice-glass DOTFILES INSTALLATION"
    echo "===================================================================="
    
    # Ensure we are in the correct directory
    if [ ! -d "$DOTFILES_DIR/hypr" ]; then
        echo "ERROR: Please run this script inside the my-rice-glass directory."
        exit 1
    fi
    
    # Create .config folder if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    list_dependencies
    create_symlinks
    validate_hyprland_config
    
    log "INSTALLATION COMPLETE!"
    echo "--------------------------------------------------------------------"
    echo "1. Ensure all dependencies have been installed."
    echo "2. Hyprland config was validated against the expected wallpaper startup path."
    echo "3. If you backed up existing files, check them in *.bak."
    echo "4. Restart Hyprland or your computer to apply the changes."
    echo "--------------------------------------------------------------------"
}

main
