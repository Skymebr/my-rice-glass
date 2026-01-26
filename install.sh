#!/bin/bash

# ====================================================================
# my-rice-glass: Simplified Installation Script
# This script automates the creation of symbolic links for dotfiles
# in the ~/.config/ folder and fixes the hardcoded path in hyprland.conf.
# ====================================================================

DOTFILES_DIR="$(pwd)"
CONFIG_DIR="$HOME/.config"
HYPR_CONFIG="$DOTFILES_DIR/hypr/hyprland.conf"

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
    declare -a DIRS=("hypr" "kitty" "matugen" "swaync" "waybar" "wofi")
    
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
# 4. PATH CORRECTION FUNCTION
# --------------------------------------------------------------------
fix_hyprland_path() {
    log "FIXING WALLPAPER SCRIPT PATH"
    
    # The hardcoded path in hyprland.conf is:
    # exec-once = /home/skyme/meus-dotfiles/hypr/scripts/wallpaper.sh init
    
    # The new path should be:
    NEW_PATH="$DOTFILES_DIR/hypr/scripts/wallpaper.sh init"
    
    # Escaping slashes for sed
    ESCAPED_NEW_PATH=$(echo "$NEW_PATH" | sed 's/\//\\\//g')
    
    # Using sed to replace line 81 in the configuration file
    if [ ! -f "$HYPR_CONFIG" ]; then
        echo "ERROR: File $HYPR_CONFIG not found. Aborting path correction."
        return 1
    fi
    
    # Replace the line that matches the pattern
    sed -i "s|^exec-once = /home/skyme/meus-dotfiles/hypr/scripts/wallpaper.sh init|exec-once = $ESCAPED_NEW_PATH|" "$HYPR_CONFIG"
    
    if [ $? -eq 0 ]; then
        echo "  - Path corrected in $HYPR_CONFIG to:"
        echo "    exec-once = $NEW_PATH"
    else
        echo "  - Warning: Could not automatically fix the path. Please check line 81 of $HYPR_CONFIG manually."
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
    fix_hyprland_path
    
    log "INSTALLATION COMPLETE!"
    echo "--------------------------------------------------------------------"
    echo "1. Ensure all dependencies have been installed."
    echo "2. The wallpaper script path has been corrected in hyprland.conf."
    echo "3. If you backed up existing files, check them in *.bak."
    echo "4. Restart Hyprland or your computer to apply the changes."
    echo "--------------------------------------------------------------------"
}

main
