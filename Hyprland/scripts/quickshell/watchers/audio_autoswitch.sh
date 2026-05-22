#!/usr/bin/env bash

BUILT_IN_PATTERN="pci.*analog-stereo"
EXTERNAL_PATTERN="(headphone|headset|bluez|bluetooth|usb)"

# ─── HELPERS ──────────────────────────────────────────────────────────────

_external_sink() {
  pactl list sinks short | grep -iE "$EXTERNAL_PATTERN" | head -1 | awk '{print $2}'
}

_builtin_sink() {
  pactl list sinks short | grep -iE "$BUILT_IN_PATTERN" | head -1 | awk '{print $2}'
}

_default_sink() {
  pactl info | grep "Default Sink" | awk -F': ' '{print $2}'
}

_switch_to() {
  local target="$1"
  local current
  current="$(_default_sink)"
  [ "$target" != "$current" ] && pactl set-default-sink "$target"
}

# ─── APPLY ON STARTUP ────────────────────────────────────────────────────
# If an external sink is already connected when this script starts, switch to it

startup_external="$(_external_sink)"
if [ -n "$startup_external" ]; then
  _switch_to "$startup_external"
fi

# ─── EVENT LISTENER ──────────────────────────────────────────────────────
# Only react to sink 'new' (device plugged) and 'remove' (device unplugged).
# Sink 'change' events include user manual default-sink switches — we IGNORE
# those so users can freely choose between multiple connected devices.

# ─── USB DEVICE MONITOR (background) ─────────────────────────────────────
# Uses udevadm monitor (no root needed, works in user space).
# Same method as battery_fetch.sh — user process with full PipeWire access.
# Replaces the old udev RUN → su → pw-play chain which was unreliable.

(
  udevadm monitor --udev --property --subsystem-match=usb --subsystem-match=block 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      UDEV\ *|KERNEL\ *) unset a s d b v;;
      *=*)
        k="${line%%=*}"; val="${line#*=}"
        case "$k" in
          ACTION) a="$val";; SUBSYSTEM) s="$val";; DEVTYPE) d="$val";; ID_BUS) b="$val";; ID_VENDOR_ID) v="$val";;
        esac;;
      "")
        [ "$a" != "add" ] && [ "$a" != "remove" ] && continue
        # USB device (not root hub): usb subsystem, usb_device type, vendor != 1d6b
        is_usb=false; [ "$s" = "usb" ] && [ "$d" = "usb_device" ] && [ "${v:-}" != "1d6b" ] && is_usb=true
        # USB storage: block subsystem, partition type, on usb bus
        is_block=false; [ "$s" = "block" ] && [ "$d" = "partition" ] && [ "$b" = "usb" ] && is_block=true
        if $is_usb || $is_block; then
          dir="plug"; [ "$a" = "remove" ] && dir="unplug"
          nohup "$HOME/.config/hypr/scripts/usb_sound.sh" "$dir" >/dev/null 2>&1 &
        fi;;
    esac
  done
) &

# ─── AUDIO SINK LISTENER ────────────────────────────────────────────────
# Reacts to headphone/Bluetooth/USB audio sink plug/unplug

pactl subscribe | while read -r raw_event; do
  # Parse: Event 'new' on sink #43
  read -r _ event_type _ object_type _ <<< "$raw_event"
  event_type="${event_type//\'/}"
  object_type="${object_type//\'/}"

  # Only react to sink add/remove
  if [ "$object_type" != "sink" ] || { [ "$event_type" != "new" ] && [ "$event_type" != "remove" ]; }; then
    continue
  fi

  # Play notification sound for headphone/Bluetooth plug/unplug
  dir="plug"; [ "$event_type" = "remove" ] && dir="unplug"
  nohup "$HOME/.config/hypr/scripts/usb_sound.sh" "$dir" >/dev/null 2>&1 &

  sleep 0.3

  external="$(_external_sink)"

  if [ -n "$external" ]; then
    # At least one external device is present — switch to the first one
    _switch_to "$external"
  else
    # Last external was removed — revert to built-in
    built_in="$(_builtin_sink)"
    [ -n "$built_in" ] && _switch_to "$built_in"
  fi
done
