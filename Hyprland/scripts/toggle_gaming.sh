#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# GAMING MODE TOGGLE — Optimize system for gaming
# -----------------------------------------------------------------------------
# Disables compositor effects, sets performance governor,
# blocks notifications, and prevents sleep.
# State tracked in ~/.cache/qs_gaming

CACHE_DIR="$HOME/.cache"
STATE_FILE="$CACHE_DIR/qs_gaming"

# Save original states for restore
ORIG_GOVERNOR_FILE="$CACHE_DIR/qs_gaming_orig_governor"
ORIG_COMPOSITE_FILE="$CACHE_DIR/qs_gaming_orig_composite"

apply_gaming() {
    # Save current governor
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null > "$ORIG_GOVERNOR_FILE"
    
    # Set performance governor
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set performance 2>/dev/null
    fi
    timeout 5 bash -c 'echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null' || true
    
    # Disable compositor animations (Hyprland)
    hyprctl keyword animations:enabled false 2>/dev/null
    hyprctl keyword decoration:blur:enabled false 2>/dev/null
    hyprctl keyword decoration:shadow:enabled false 2>/dev/null
    
    # Enable DND (suppress notifications)
    ~/.config/hypr/scripts/toggle_dnd.sh on 2>/dev/null
    
    # Caffeine mode (prevent suspend)
    ~/.config/hypr/scripts/toggle_caffeine.sh on 2>/dev/null
    
    echo "active" > "$STATE_FILE"
    notify-send -a "Gaming Mode" "🎮 Gaming Mode On" "Performance maxed, compositor off, DND on"
}

restore_normal() {
    # Restore CPU governor
    if [ -f "$ORIG_GOVERNOR_FILE" ]; then
        ORIG_GOV=$(cat "$ORIG_GOVERNOR_FILE")
        timeout 5 bash -c 'echo "$0" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null' "$ORIG_GOV" || true
        if command -v powerprofilesctl &>/dev/null; then
            powerprofilesctl set "$ORIG_GOV" 2>/dev/null
        fi
    fi
    
    # Re-enable compositor
    hyprctl keyword animations:enabled true 2>/dev/null
    hyprctl keyword decoration:blur:enabled true 2>/dev/null
    hyprctl keyword decoration:shadow:enabled true 2>/dev/null
    
    # Disable DND
    ~/.config/hypr/scripts/toggle_dnd.sh off 2>/dev/null
    
    # Disable caffeine
    ~/.config/hypr/scripts/toggle_caffeine.sh off 2>/dev/null
    
    echo "inactive" > "$STATE_FILE"
    notify-send -a "Gaming Mode" "🎮 Gaming Mode Off" "Normal settings restored"
}

case "${1:-toggle}" in
    status)
        if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "active" ]; then
            echo "active"
        else
            echo "inactive"
        fi
        exit 0
        ;;
    on)
        if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "active" ]; then
            exit 0
        fi
        apply_gaming
        ;;
    off)
        restore_normal
        ;;
    toggle|*)
        if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "active" ]; then
            restore_normal
        else
            apply_gaming
        fi
        ;;
esac
