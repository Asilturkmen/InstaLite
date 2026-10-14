#!/bin/sh
# Geliştirme aracı: derleyip kabloyla bağlı iPhone'a kurar ve başlatır.
#   INSTALITE_DEVICE=<UDID> Tools/run-device.sh [Debug|Release]
set -eu
cd "$(dirname "$0")/.."
PHONE=${INSTALITE_DEVICE:?INSTALITE_DEVICE=<UDID> ver (xcrun devicectl list devices)}
BUNDLE=${INSTALITE_BUNDLE:-com.asilturkmen.instalite}
CONFIG=${1:-Debug}
xcodegen generate --quiet
mkdir -p build
if ! xcodebuild build -project InstaLite.xcodeproj -scheme InstaLite -configuration "$CONFIG" \
  -destination "platform=iOS,id=$PHONE" -derivedDataPath build/DerivedData -allowProvisioningUpdates \
  -quiet > build/last-device-build.log 2>&1; then
  grep -E "error:" build/last-device-build.log || tail -20 build/last-device-build.log
  exit 1
fi
xcrun devicectl device install app --device "$PHONE" "build/DerivedData/Build/Products/$CONFIG-iphoneos/InstaLite.app" >/dev/null
xcrun devicectl device process launch --device "$PHONE" --terminate-existing "$BUNDLE" >/dev/null
echo "telefonda çalışıyor ($CONFIG)"
