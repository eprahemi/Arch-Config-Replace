#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# THEME PROFILES — Save and restore desktop theme profiles
# -----------------------------------------------------------------------------
# Saves: wallpaper, power profile, night light state, DND state, caffeine state
# Profiles stored in ~/.config/hypr/theme_profiles/

PROFILE_DIR="$HOME/.config/hypr/theme_profiles"
mkdir -p "$PROFILE_DIR"

case "${1:-list}" in
    list)
        echo "Available profiles:"
        for p in "$PROFILE_DIR"/*.json; do
            [ -f "$p" ] && basename "$p" .json
        done
        exit 0
        ;;
    save)
        NAME="$2"
        [ -z "$NAME" ] && echo "Usage: $0 save <profile_name>" && exit 1
        
        PROFILE_FILE="$PROFILE_DIR/$NAME.json"
        
        # Get current wallpaper
        WALLPAPER=""
        if pgrep -a "mpvpaper" > /dev/null; then
            WALLPAPER=$(pgrep -a mpvpaper | grep -o "$HOME/Pictures/Wallpapers/[^' ]*" | head -1)
        fi
        if [ -z "$WALLPAPER" ] && command -v awww >/dev/null; then
            WALLPAPER=$(awww query 2>/dev/null | head -1)
        fi
        
        # Get states
POWER_PROFILE=$(cat "$HOME/.cache/qs_powerprofile" 2>/dev/null || echo "balanced")
NIGHT_LIGHT=$(cat "$HOME/.cache/qs_nightlight" 2>/dev/null || echo "inactive")
DND=$(cat "$HOME/.cache/qs_dnd" 2>/dev/null || echo "0")
CAFFEINE=$(cat "$HOME/.cache/qs_caffeine" 2>/dev/null || echo "inactive")
GAMING=$(cat "$HOME/.cache/qs_gaming" 2>/dev/null || echo "inactive")
        
        cat > "$PROFILE_FILE" << EOF
{
    "name": "$NAME",
    "saved_at": "$(date -Iseconds)",
    "wallpaper": "$WALLPAPER",
    "power_profile": "$POWER_PROFILE",
    "night_light": "$NIGHT_LIGHT",
    "dnd": "$DND",
    "caffeine": "$CAFFEINE",
    "gaming": "$GAMING"
}
EOF
        notify-send -a "Theme Profiles" "💾 Profile Saved" "$NAME"
        ;;
    load)
        NAME="$2"
        [ -z "$NAME" ] && echo "Usage: $0 load <profile_name>" && exit 1
        
        PROFILE_FILE="$PROFILE_DIR/$NAME.json"
        [ ! -f "$PROFILE_FILE" ] && notify-send -u critical -a "Theme Profiles" "Profile not found" "$NAME" && exit 1
        
        # Parse JSON
        POWER_PROFILE=$(python3 -c "import json; print(json.load(open('$PROFILE_FILE'))['power_profile'])")
        NIGHT_LIGHT=$(python3 -c "import json; print(json.load(open('$PROFILE_FILE'))['night_light'])")
        DND=$(python3 -c "import json; print(json.load(open('$PROFILE_FILE'))['dnd'])")
        CAFFEINE=$(python3 -c "import json; print(json.load(open('$PROFILE_FILE'))['caffeine'])")
        GAMING=$(python3 -c "import json; print(json.load(open('$PROFILE_FILE'))['gaming'])")
        WALLPAPER=$(python3 -c "import json; print(json.load(open('$PROFILE_FILE'))['wallpaper'])")
        
        # Apply power profile
        ~/.config/hypr/scripts/toggle_powerprofile.sh set "$POWER_PROFILE" 2>/dev/null
        
        # Apply night light
        if [ "$NIGHT_LIGHT" = "active" ]; then
            ~/.config/hypr/scripts/toggle_nightlight.sh on 2>/dev/null
        else
            ~/.config/hypr/scripts/toggle_nightlight.sh off 2>/dev/null
        fi
        
        # Apply DND
        [ "$DND" = "1" ] && ~/.config/hypr/scripts/toggle_dnd.sh on 2>/dev/null || ~/.config/hypr/scripts/toggle_dnd.sh off 2>/dev/null
        
        # Apply caffeine
        [ "$CAFFEINE" = "active" ] && ~/.config/hypr/scripts/toggle_caffeine.sh on 2>/dev/null || ~/.config/hypr/scripts/toggle_caffeine.sh off 2>/dev/null
        
        # Apply wallpaper directly (not just toggle picker)
        if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
            if command -v awww &>/dev/null; then
                awww img "$WALLPAPER" --transition-type fade --transition-pos 0.5,0.5 --transition-fps 60 --transition-duration 1 2>/dev/null || true
                cp "$WALLPAPER" "$HOME/.cache/current_wallpaper.png" 2>/dev/null || true
            else
                ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper 2>/dev/null || true
            fi
        fi
        
        notify-send -a "Theme Profiles" "♻ Profile Loaded" "$NAME"
        ;;
    *)
        echo "Usage: $0 {list|save|load} [profile_name]"
        ;;
esac
