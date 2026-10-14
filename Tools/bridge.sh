#!/bin/sh
# Geliştirme aracı: çalışan InstaLite'ın (Debug) web görünümüyle konuşur. Varsayılan hedef
# açık simülatördür; INSTALITE_DEVICE=<UDID> verilirse kabloyla bağlı iPhone kullanılır.
#
#   Tools/bridge.sh js 'return document.title'   sayfada JS gövdesi çalıştırır (await kullanılabilir)
#   Tools/bridge.sh go /direct/inbox/            sayfaya gider
#   Tools/bridge.sh shot [dosya.png]             ekran görüntüsü alır (yalnız simülatör)
#
# SIM_DEVICE (varsayılan: booted) ve INSTALITE_BUNDLE ile hedef, BRIDGE_TIMEOUT (sn) ile bekleme değiştirilir.
set -eu

SIM=${SIM_DEVICE:-booted}
PHONE=${INSTALITE_DEVICE:-}
BUNDLE=${INSTALITE_BUNDLE:-com.asilturkmen.instalite}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

devicectl_copy() {
  xcrun devicectl device copy "$1" --device "$PHONE" --source "$2" --destination "$3" \
    --domain-type appDataContainer --domain-identifier "$BUNDLE" >/dev/null 2>&1
}

send() {
  if [ -n "$PHONE" ]; then
    devicectl_copy to "$1" Documents/bridge/cmd.js
  else
    dir="$(xcrun simctl get_app_container "$SIM" "$BUNDLE" data)/Documents/bridge"
    cp "$1" "$dir/cmd.js.tmp" && mv "$dir/cmd.js.tmp" "$dir/cmd.js"
  fi
}

fetch() {
  if [ -n "$PHONE" ]; then
    devicectl_copy from Documents/bridge/out.json "$1"
  else
    cp "$(xcrun simctl get_app_container "$SIM" "$BUNDLE" data)/Documents/bridge/out.json" "$1" 2>/dev/null
  fi
}

run_js() {
  id="$$-$(date +%s)"
  printf 'return JSON.stringify({id: "%s", value: await (async () => {\n%s\n})()});\n' "$id" "$1" > "$WORK/cmd.js"
  send "$WORK/cmd.js"
  deadline=$(($(date +%s) + ${BRIDGE_TIMEOUT:-30}))
  while ! { fetch "$WORK/out.json" && grep -q "$id" "$WORK/out.json"; }; do
    if [ "$(date +%s)" -gt "$deadline" ]; then
      echo "zaman aşımı: uygulama açık ve Debug sürümü mü?" >&2
      exit 1
    fi
    sleep 0.3
  done
  cat "$WORK/out.json"
  echo
}

case "${1:-}" in
  js) run_js "$2" ;;
  go) run_js "location.assign($(printf '%s' "$2" | sed "s/.*/'&'/")); return location.href" ;;
  shot) xcrun simctl io "$SIM" screenshot "${2:-screenshot.png}" >/dev/null 2>&1 && echo "${2:-screenshot.png}" ;;
  *) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
