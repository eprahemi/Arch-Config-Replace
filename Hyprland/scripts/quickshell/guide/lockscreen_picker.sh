#!/usr/bin/env bash
WALL_DIR="$HOME/.config/hypr/Lockscreen Wallpaper"
mkdir -p "$WALL_DIR"

CHOSEN=$(find "$HOME/Pictures/Wallpapers" "$HOME" -maxdepth 3 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) 2>/dev/null \
  | head -200 \
  | rofi -dmenu -p "Select Wallpaper" -theme-str 'listview {lines: 12;}')

[ -z "$CHOSEN" ] && exit 0

EXT="${CHOSEN##*.}"
cp -f "$CHOSEN" "$WALL_DIR/lock.$EXT"

notify-send -t 3000 -a "Eprahemi Dots" -u low "Lock Screen Set" "$(basename "$CHOSEN")"

if [ "${1:-}" = "--sddm" ]; then
  SDDM_DIR="/usr/share/sddm/themes/matugen-minimal"
  if [ -d "$SDDM_DIR" ]; then
    cp -f "$CHOSEN" "$SDDM_DIR/wallpaper.png" 2>/dev/null || pkexec cp -f "$CHOSEN" "$SDDM_DIR/wallpaper.png" 2>/dev/null
    if [ -f "$SDDM_DIR/wallpaper.png" ]; then
      notify-send -t 3000 -a "Eprahemi Dots" -u normal "Login Screen Set" "SDDM wallpaper updated"
    else
      notify-send -t 5000 -a "Eprahemi Dots" -u critical "Permission Denied" "Could not copy to SDDM directory"
    fi
  else
    notify-send -t 5000 -a "Eprahemi Dots" -u critical "SDDM Not Found" "Could not find SDDM theme directory"
  fi
fi
