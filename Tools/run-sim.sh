#!/bin/sh
# Geliştirme aracı: Debug sürümü derleyip simülatöre kurar ve yeniden başlatır.
#   Tools/run-sim.sh [uygulamaya geçilecek başlatma argümanları]
set -eu
cd "$(dirname "$0")/.."
DEVICE=${SIM_DEVICE:-booted}
BUNDLE=$("$(dirname "$0")/bundle-id.sh")
xcodegen generate --quiet
mkdir -p build
if ! xcodebuild build -project InstaLite.xcodeproj -scheme InstaLite -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO -quiet > build/last-build.log 2>&1; then
  grep -E "error:" build/last-build.log || tail -20 build/last-build.log
  exit 1
fi
grep -E "warning:" build/last-build.log | grep -v appintentsmetadataprocessor || true
xcrun simctl install "$DEVICE" build/DerivedData/Build/Products/Debug-iphonesimulator/InstaLite.app
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
xcrun simctl launch "$DEVICE" "$BUNDLE" "$@" >/dev/null
echo "çalışıyor"
