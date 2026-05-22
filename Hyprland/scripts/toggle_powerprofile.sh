#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# POWER PROFILE SWITCHER — Cycle through performance profiles
# -----------------------------------------------------------------------------
# Uses powerprofilesctl where available, falls back to cpupower.
# Cycles: balanced -> performance -> power-saver -> balanced
# State tracked in ~/.cache/qs_powerprofile

CACHE_DIR="$HOME/.cache"
STATE_FILE="$CACHE_DIR/qs_powerprofile"

# Detect available tool
if command -v powerprofilesctl &>/dev/null; then
    TOOL="powerprofilesctl"
elif command -v cpupower &>/dev/null; then
    TOOL="cpupower"
else
    notify-send -u critical -a "Power Profile" "No power profile tool found" "Install power-profiles-daemon or cpupower"
    exit 1
fi

get_current() {
    if [ "$TOOL" = "powerprofilesctl" ]; then
        powerprofilesctl get 2>/dev/null
    else
        # cpupower fallback: read governor
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
    fi
}

apply_profile() {
    local profile="$1"
    if [ "$TOOL" = "powerprofilesctl" ]; then
        powerprofilesctl set "$profile" 2>/dev/null
    else
        # cpupower fallback
        case "$profile" in
            performance) timeout 5 bash -c 'echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null' || true ;;
            powersave) timeout 5 bash -c 'echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null' || true ;;
            balanced) timeout 5 bash -c 'echo "ondemand" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null' || true ;;
        esac
    fi
    echo "$profile" > "$STATE_FILE"
}

case "${1:-toggle}" in
    status)
        if [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        else
            get_current
        fi
        exit 0
        ;;
    get)
        get_current
        exit 0
        ;;
    set)
        if [ -n "$2" ]; then
            apply_profile "$2"
            notify-send -a "Power Profile" "⚡ Profile: ${2^}" "CPU governor set to $2"
        fi
        exit 0
        ;;
    cycle|toggle|*)
        CURRENT=$(get_current)
        case "$CURRENT" in
            *performance*)
                apply_profile "balanced"
                notify-send -a "Power Profile" "⚡ Balanced Mode" "Performance and efficiency balanced"
                ;;
            *balanced*|*ondemand*|*schedutil*)
                apply_profile "power-saver"
                notify-send -a "Power Profile" "🔋 Power Saver" "Maximum efficiency, reduced performance"
                ;;
            *power-saver*|*powersave*)
                apply_profile "performance"
                notify-send -a "Power Profile" "🚀 Performance Mode" "Maximum CPU speed, higher power usage"
                ;;
            *)
                apply_profile "balanced"
                notify-send -a "Power Profile" "⚡ Balanced Mode" "Default profile"
                ;;
        esac
        ;;
esac
