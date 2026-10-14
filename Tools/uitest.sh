#!/bin/sh
# Geliştirme aracı: projeyi yeniden üretir, gerçek dokunuşla akış kaydırma testini telefonda çalıştırır
# ve ölçüm özetini yazar.
#   INSTALITE_DEVICE=<UDID> Tools/uitest.sh [kaydırma sayısı] [noinject]
set -eu
cd "$(dirname "$0")/.."
PHONE=${INSTALITE_DEVICE:?INSTALITE_DEVICE=<UDID> ver (xcrun devicectl list devices)}
export TEST_RUNNER_SWIPES=${1:-40}
if [ "${2:-}" = noinject ]; then export TEST_RUNNER_NOINJECT=1; fi
xcodegen generate --quiet
mkdir -p build
if ! xcodebuild test -project InstaLite.xcodeproj -scheme InstaLite -destination "platform=iOS,id=$PHONE" \
  -derivedDataPath build/DerivedData -allowProvisioningUpdates -only-testing:InstaLiteUITests/FeedScrollUITests \
  > build/last-uitest.log 2>&1; then
  grep -E "error:" build/last-uitest.log | grep -v DVTDevice || tail -20 build/last-uitest.log
  exit 1
fi
Tools/metrics.sh
