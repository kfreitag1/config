#!/bin/sh
status=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null)
if printf '%s\n' "$status" | grep -q ':wifi:connected$'; then
  nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }'
elif printf '%s\n' "$status" | grep -q ':ethernet:connected$'; then
  printf '%s\n' "$status" | awk -F: '$2 == "ethernet" && $3 == "connected" { print $1; exit }'
else
  echo offline
fi
