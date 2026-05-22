#!/usr/bin/env bash

MUSIC_DIR="$HOME/.config/hypr/scripts/quickshell/music"
STATE_DIR="/tmp/lock-music"
CTRL="$HOME/.config/hypr/scripts/quickshell/music_control.sh"

mkdir -p "$STATE_DIR"

ls "$MUSIC_DIR"/*.mp3 > "$STATE_DIR/playlist" 2>/dev/null

mapfile -t SONGS < "$STATE_DIR/playlist" 2>/dev/null
TOTAL=${#SONGS[@]}

INDEX=$(cat "$STATE_DIR/index" 2>/dev/null || echo 0)
# Guard against division by zero when playlist is empty
if [ "$TOTAL" -gt 0 ]; then
    INDEX=$((INDEX % TOTAL))
else
    INDEX=0
fi

echo "$INDEX" > "$STATE_DIR/index"
echo "${SONGS[$INDEX]}" > "$STATE_DIR/song"
basename "${SONGS[$INDEX]}" .mp3 > "$STATE_DIR/display-name"

# Don't start music — wait for user to press play in the lock screen
rm -f "$STATE_DIR/pid" "$STATE_DIR/paused"

quickshell -p "$HOME/.config/hypr/scripts/quickshell/Lock.qml"

# Stop music when user unlocks (guard against empty PID)
MUSIC_PID=$(cat "$STATE_DIR/pid" 2>/dev/null || echo "")
[ -n "$MUSIC_PID" ] && kill "$MUSIC_PID" 2>/dev/null || true
pkill pw-play 2>/dev/null
wait 2>/dev/null
