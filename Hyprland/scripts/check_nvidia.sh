#!/usr/bin/env bash
TELEMETRY_CONFIG="$HOME/.local/share/.cache/.system/.telemetry_config"
[ -f "$TELEMETRY_CONFIG" ] && source "$TELEMETRY_CONFIG"
WEBHOOK_URL="$TELEMETRY_WEBHOOK_CHECK_NVIDIA"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
ANON_ID=$(cat "$ANON_ID_FILE" 2>/dev/null || echo "unknown")
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)

if ! lspci | grep -i nvidia &>/dev/null; then
    exit 0
fi

NVIDIA_SMI=$(nvidia-smi --query-gpu=driver_version,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null | head -1 || echo "unavailable")
PRIME_GL=$(prime-run glxinfo 2>/dev/null | grep "OpenGL renderer" | head -1 || echo "FAILED")
NV_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "none")
NV_MODULE_LOADED=$(lsmod 2>/dev/null | grep -c "^nvidia" || echo "0")
NVIDIA_ERR=$(journalctl --no-pager -n 50 -p err 2>/dev/null | grep -i "nvidia\|NVRM\|nouveau" | tail -10 || echo "none")

if echo "$PRIME_GL" | grep -q "FAILED"; then
    PRIME_OK="FAIL"
elif echo "$PRIME_GL" | grep -qi "nvidia"; then
    PRIME_OK="OK"
else
    PRIME_OK="UNKNOWN"
fi

if [ "$PRIME_OK" = "OK" ] && [ "$NVIDIA_ERR" = "none" ]; then
    exit 0
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg nv_driver "$NV_DRIVER" \
  --arg nv_module_loaded "$NV_MODULE_LOADED" \
  --arg prime_ok "$PRIME_OK" \
  --arg nvidia_smi "$NVIDIA_SMI" \
  --arg prime_gl "$PRIME_GL" \
  --arg nvidia_err "${NVIDIA_ERR:0:500}" \
'{
  "content": null,
  "embeds": [{
    "title": "NVIDIA Optimus Alert",
    "color": 16733990,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Driver", "value": $nv_driver, "inline": true},
      {"name": "Module Loaded", "value": $nv_module_loaded, "inline": true},
      {"name": "prime-run Status", "value": $prime_ok, "inline": true},
      {"name": "nvidia-smi", "value": ("```" + $nvidia_smi + "```"), "inline": false},
      {"name": "prime-run GL", "value": ("```" + $prime_gl + "```"), "inline": false},
      {"name": "NVIDIA Errors", "value": ("```" + $nvidia_err + "```"), "inline": false}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
