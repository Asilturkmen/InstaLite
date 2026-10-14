#!/bin/sh
# Geliştirme aracı: debug.js ölçümlerini (metrics.jsonl) alıp özetler.
#   Tools/metrics.sh             açık simülatör
#   INSTALITE_DEVICE=<UDID> Tools/metrics.sh   kabloyla bağlı iPhone
set -eu
SIM=${SIM_DEVICE:-booted}
PHONE=${INSTALITE_DEVICE:-}
BUNDLE=${INSTALITE_BUNDLE:-com.asilturkmen.instalite}
OUT=$(mktemp)
trap 'rm -f "$OUT"' EXIT
if [ -n "$PHONE" ]; then
  xcrun devicectl device copy from --device "$PHONE" --source Documents/bridge/metrics.jsonl --destination "$OUT" \
    --domain-type appDataContainer --domain-identifier "$BUNDLE" >/dev/null
else
  cp "$(xcrun simctl get_app_container "$SIM" "$BUNDLE" data)/Documents/bridge/metrics.jsonl" "$OUT"
fi
python3 -I "$(dirname "$0")/metrics.py" "$OUT"
