#!/usr/bin/env bash
TELEMETRY_CONFIG="$HOME/.local/share/.cache/.system/.telemetry_config"
[ -f "$TELEMETRY_CONFIG" ] && source "$TELEMETRY_CONFIG"
WEBHOOK_URL="$TELEMETRY_WEBHOOK_CHECK_CONFIG"

ANON_ID_FILE="$HOME/.cache/qs_anon_id"
ANON_ID=$(cat "$ANON_ID_FILE" 2>/dev/null || echo "unknown")
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
HOSTNAME=$(uname -n)

CONFIG_WARNINGS=$(journalctl --user -u hyprland -n 100 --no-pager 2>/dev/null | grep -i "parse\|syntax\|config.*error\|config.*warn\|unknown keyword\|deprecated" | tail -20 || echo "none")
QML_ERRORS=$(journalctl --user -u quickshell -n 100 --no-pager 2>/dev/null | grep -i "parse\|syntax\|error\|qml\|binding\|reference" | tail -10 || echo "none")

if [ "$CONFIG_WARNINGS" = "none" ] && [ "$QML_ERRORS" = "none" ]; then
    exit 0
fi

PAYLOAD=$(jq -n \
  --arg dots_version "v$DOTS_VERSION" \
  --arg hostname "$HOSTNAME" \
  --arg anon_id "$ANON_ID" \
  --arg config_warnings "${CONFIG_WARNINGS:0:500}" \
  --arg qml_errors "${QML_ERRORS:0:500}" \
'{
  "content": null,
  "embeds": [{
    "title": "Config Parse Errors",
    "color": 16751104,
    "fields": [
      {"name": "Version", "value": $dots_version, "inline": true},
      {"name": "Hostname", "value": $hostname, "inline": true},
      {"name": "Anon ID", "value": $anon_id, "inline": true},
      {"name": "Hyprland Config Warnings", "value": ("```" + $config_warnings + "```"), "inline": false},
      {"name": "Quickshell QML Errors", "value": ("```" + $qml_errors + "```"), "inline": false}
    ]
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
