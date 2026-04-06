# Skywall

`skywall` is a manual wallpaper picker written in `C + GTK4 + gtk4-layer-shell`
that sits on top of the existing `hypr/scripts/wallpaper.sh` backend.

It keeps the current wallpaper pipeline intact and only replaces the manual
selection UI.

## Features

- native Wayland layer-shell window
- real fullscreen/transparency without Xwayland or `hyprctl`
- glass-style background instead of a fully transparent canvas
- staggered rows and hover emphasis
- image and video support
- cached previews in `~/.cache/skywall/previews`
- click-to-apply through `wallpaper.sh pick`
- configurable spacing, shape, density, and idle/hover treatment

## Runtime Dependencies

- `gcc`
- `gtk4`
- `gtk4-layer-shell`
- `gdk-pixbuf2`
- `cairo`
- `ffmpeg`

## Config

`skywall` reads `~/.config/skywall/config.env`.

Available shape values:

- `rectangle`
- `soft`
- `parallelogram`

Main knobs:

- `SKYWALL_COLUMNS`
- `SKYWALL_MIN_COLUMNS`
- `SKYWALL_MAX_COLUMNS`
- `SKYWALL_CARD_WIDTH`
- `SKYWALL_MIN_CARD_WIDTH`
- `SKYWALL_MAX_CARD_WIDTH`
- `SKYWALL_SPACING`
- `SKYWALL_ROW_SPACING`
- `SKYWALL_SHAPE`
- `SKYWALL_SLANT`
- `SKYWALL_STAGGER_ROWS`
- `SKYWALL_ROW_OFFSET_RATIO`
- `SKYWALL_LAYER_NAMESPACE`
- `SKYWALL_GRAYSCALE_IDLE`
- `SKYWALL_THUMB_IDLE_ALPHA`
- `SKYWALL_THUMB_CURRENT_ALPHA`
- `SKYWALL_THUMB_HOVER_ALPHA`
- `SKYWALL_GLASS_ALPHA_TOP`
- `SKYWALL_GLASS_ALPHA_BOTTOM`
- `SKYWALL_CARD_GLASS_ALPHA`
- `SKYWALL_CARD_SHADOW_ALPHA`
- `SKYWALL_HOVER_SCALE`
- `SKYWALL_BORDER_WIDTH`

`SKYWALL_LAYER_NAMESPACE` defaults to `skywall` and the repository ships a
matching blur/no-animation layerrule in `hyprland.conf`.

The grid adapts to the available width and is meant to feel cinematic and
customizable rather than generic: large thumbnails, staggered rows, muted idle
states, and stronger focus on the current or hovered wallpaper.

## Manual Run

```bash
~/.config/skywall/skywall
```

Fullscreen is the default behavior and is handled by the layer-shell window itself.

The binary is built locally on first launch and reused after that, so startup stays
fast after the first compile.

## Manual Hyprland Bind Example

This repository does not edit `hyprland.conf` for you.

```conf
bind = SUPER, Z, exec, ~/.config/hypr/scripts/skywall.sh
```

## Optional Arguments

```bash
~/.config/skywall/skywall --windowed
~/.config/skywall/skywall --wallpaper-dir ~/Pictures/wallpapers
~/.config/skywall/skywall --script ~/.config/hypr/scripts/wallpaper.sh
```
