# my-rice-glass: Hyprland Configuration (Wayland) :)

## ⚙️ Core Components

The "rice" (visual configuration) is built around the following core components:

| Component | Function | Configuration Files |
| :--- | :--- | :--- |
| **Hyprland** | Tiling Window Manager | `hypr/hyprland.conf`, `hypr/colors.conf` |
| **Waybar** | Status Bar | `waybar/config`, `waybar/style.css` |
| **Kitty** | Terminal Emulator | `kitty/kitty.conf`, `kitty/colors.conf` |
| **Wofi** | Application Launcher | `wofi/style.css` |
| **SwayNC** | Notification Center | `swaync/config.json`, `swaync/style.css` |
| **Swww** | Wallpaper Manager | Integrated via `hypr/scripts/wallpaper.sh` |
| **Matugen** | Color Scheme Generation | `matugen/config.toml` |
| **Hyprlock** | Screen Locker | `hypr/hyprlock.conf` |

## System Commands and Shortcuts

The core of system interaction is the `hypr/hyprland.conf` file, which defines all keyboard shortcuts. The main modifier key (`$mainMod`) is the **SUPER** key (also known as `Win` or `Meta`).

### 1. Power Menu and System Control

Power and session control are managed through a Hyprland **Submap**, activated with `SUPER + X`.

| Action | Shortcut | Executed Command | Notes |
| :--- | :--- | :--- | :--- |
| **Activate Menu** | `SUPER + X` | `hyprctl dispatch submap power` | Displays a notification with the options. |
| **Poweroff** | `P` (after `SUPER + X`) | `systemctl poweroff` | Shuts down the computer. |
| **Reboot** | `R` (after `SUPER + X`) | `systemctl reboot` | Restarts the computer. |
| **Lock Screen** | `L` (after `SUPER + X`) | `hyprlock` | Locks the screen using Hyprlock. |
| **Suspend** | `S` (after `SUPER + X`) | `systemctl suspend` | Puts the computer into suspend mode. |
| **Log Out** | `E` (after `SUPER + X`) | `hyprctl dispatch exit` | Exits Hyprland (Logout). |
| **Log Out 2** | `SUPER + M`| `hyprctl dispatch exit` | Exits Hyprland (Logout). |
| **Cancel Menu** | `Escape` (after `SUPER + X`) | `hyprctl dispatch submap reset` | Returns to normal shortcut mode. |

### 2. Wallpaper Switching

Wallpaper switching is automated and is a key feature of this configuration, as it triggers the update of the entire system's color scheme.

| Action | Shortcut | Executed Script | Notes |
| :--- | :--- | :--- | :--- |
| **Change Wallpaper** | `SUPER + W` | `~/.config/hypr/scripts/wallpaper.sh` | Selects a new wallpaper (image or video) and updates system colors via Matugen. |

The `wallpaper.sh` script does the following:
1. Selects a random file (image, GIF, MP4, MKV, WEBM) from the `wallpapers` folder.
2. If it's a video, it generates a static *thumbnail* for Hyprlock and for the transition.
3. Applies the wallpaper using `swww` (for images) or `mpvpaper` (for videos).
4. Executes `matugen` to extract the dominant colors from the new wallpaper and apply them to:
    * Hyprland window borders.
    * Waybar.
    * Kitty (terminal).
    * SwayNC (notifications).

### 3. Application and Window Shortcuts

| Action | Shortcut | Command/Program |
| :--- | :--- | :--- |
| **Terminal** | `SUPER + Q` | `kitty` |
| **Browser** | `SUPER + B` | `firefox` |
| **File Manager** | `SUPER + E` | `thunar` |
| **Application Launcher** | `SUPER + Space` | `wofi` |
| **Close Active Window** | `SUPER + C` | `killactive,` |
| **Toggle Floating** | `SUPER + V` | `togglefloating,` |
| **Fullscreen** | `SUPER + F` | `fullscreen` |

### 4. Screenshots

The configuration uses `hyprshot` for taking screenshots.

| Action | Shortcut | Executed Command |
| :--- | :--- | :--- |
| **Capture Region** | `Print` | `hyprshot -m region --clipboard-only` |
| **Capture Window** | `SUPER + Print` | `hyprshot -m window` |
| **Capture Full Screen** | `SHIFT + Print` | `hyprshot -m output` |

## Simplified Installation

To replicate this configuration, you will need the following packages installed:

*   **Window Manager:** `Hyprland`
*   **Status Bar:** `Waybar`
*   **Launcher:** `Wofi`
*   **Screen Locker:** `Hyprlock`
*   **Wallpaper:** `swww` and `mpvpaper` (for videos)
*   **Dynamic Colors:** `matugen`
*   **Notifications:** `SwayNC`
*   **Utilities:** `kitty`, `thunar`, `hyprshot`, `playerctl`, `brightnessctl`, `wpctl`, `ffmpeg`

**Installation with Script (Recommended):**

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Skymebr/my-rice-glass.git
    cd my-rice-glass
    ```
2.  **Install Dependencies:**
    Ensure that all packages listed above (Hyprland, Waybar, Kitty, etc.) are installed on your system. The script **does not** install packages, it only configures the files.
3.  **Execute the Installation Script:**
    The script will create the necessary symbolic links in your `~/.config/` folder and automatically fix the wallpaper script path in `hyprland.conf`.
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
4.  **Restart:**
    After execution, restart Hyprland or your computer for the new settings to take effect.

**Manual Installation (Alternative):**
If you prefer, you can follow the manual steps of creating symbolic links and path correction, as detailed in the previous section.
