#!/usr/bin/env bash
# ─── USB/Device Plug/Unplug Sound ─────────────────────────────────────────
# Plays notification sounds when devices are plugged/unplugged.
# Triggered by:
#   - udev rules for USB storage + USB devices
#   - audio_autoswitch.sh for headphones/Bluetooth
#
# When triggered by udev (via su), the environment is minimal.
# We set XDG_RUNTIME_DIR explicitly so pw-play can reach PipeWire.
#
# Usage:
#   usb_sound.sh plug     — Play plug-in sound
#   usb_sound.sh unplug   — Play un-plug sound
# ──────────────────────────────────────────────────────────────────────────

# Ensure PipeWire/PulseAudio can connect (critical when udev triggers this)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

SOUND_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sounds"
SOUND_PLUG="$SOUND_DIR/plug-in.mp3"
SOUND_UNPLUG="$SOUND_DIR/un-plug.mp3"
RATE_LIMIT_FILE="/tmp/.usb-sound-last"

# Skip during first 60s of uptime — avoids boot-time device enumeration noise
read -r uptime_sec _ < /proc/uptime
uptime_sec="${uptime_sec%.*}"
[ "${uptime_sec:-0}" -lt 60 ] && exit 0

# Rate limit: skip if a sound was played less than 2 seconds ago
_now_ms() { date +%s%3N 2>/dev/null || echo 0; }

_play() {
    local file="$1"
    local now
    now="$(_now_ms)"

    if [ -f "$RATE_LIMIT_FILE" ]; then
        local last
        last=$(cat "$RATE_LIMIT_FILE" 2>/dev/null || echo 0)
        [ "$((now - last))" -lt 2000 ] && return 0
    fi

    echo "$now" > "$RATE_LIMIT_FILE"
    pw-play "$file" 2>/dev/null || paplay "$file" 2>/dev/null || true
}

# ─── Main ─────────────────────────────────────────────────────────────────
case "${1:-}" in
    plug|add|in)
        _play "$SOUND_PLUG"
        ;;
    unplug|remove|out)
        _play "$SOUND_UNPLUG"
        ;;
    --test)
        # Bypass rate limit + boot guard for manual testing
        rm -f "$RATE_LIMIT_FILE"
        pw-play "$SOUND_PLUG" 2>/dev/null || paplay "$SOUND_PLUG" 2>/dev/null || echo "FAIL: could not play plug sound"
        sleep 0.5
        pw-play "$SOUND_UNPLUG" 2>/dev/null || paplay "$SOUND_UNPLUG" 2>/dev/null || echo "FAIL: could not play unplug sound"
        echo "OK: test complete (you should have heard two chimes)"
        ;;
    --check)
        echo "SOUND_PLUG=$SOUND_PLUG ($([ -f "$SOUND_PLUG" ] && echo 'EXISTS' || echo 'MISSING'))"
        echo "SOUND_UNPLUG=$SOUND_UNPLUG ($([ -f "$SOUND_UNPLUG" ] && echo 'EXISTS' || echo 'MISSING'))"
        echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
        echo "pw-play: $(command -v pw-play || echo 'NOT FOUND')"
        echo "paplay: $(command -v paplay || echo 'NOT FOUND')"
        echo "uptime_sec=${uptime_sec:-0} ($([ "${uptime_sec:-0}" -lt 60 ] && echo 'BOOT GUARD ACTIVE' || echo 'OK'))"
        ;;
    *)
        echo "Usage: $0 <plug|unplug|--test|--check>"
        exit 1
        ;;
esac
