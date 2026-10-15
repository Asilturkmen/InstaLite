#!/bin/sh
# Uygulama kimliğini imza ayarlarından okur (Local.xcconfig, Signing.xcconfig'i ezer).
cd "$(dirname "$0")/../Config"
for file in Local.xcconfig Signing.xcconfig; do
  [ -f "$file" ] || continue
  id=$(sed -n 's/^[[:space:]]*INSTALITE_BUNDLE_ID[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*/\1/p' "$file" | tail -1)
  if [ -n "$id" ]; then
    echo "$id"
    exit 0
  fi
done
echo "INSTALITE_BUNDLE_ID bulunamadı" >&2
exit 1
