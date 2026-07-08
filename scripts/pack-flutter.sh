#!/bin/bash

VERSION="26.1.3"
PACKAGES_DIR="packages"
PLUGINS=(
  "udentify-core-flutter"
  "ocr-flutter"
  "liveness-flutter"
  "mrz-flutter"
  "nfc-flutter"
  "video-call-flutter"
)

set -e
cd "$(dirname "$0")/.."

mkdir -p "$PACKAGES_DIR"
rm -f "$PACKAGES_DIR"/*.tar.gz

for plugin in "${PLUGINS[@]}"; do
  if [ -d "$PACKAGES_DIR/$plugin" ]; then
    echo "Packing $plugin..."
    tar -czf "$PACKAGES_DIR/${plugin}-${VERSION}.tar.gz" -C "$PACKAGES_DIR" "$plugin"
    echo "  Created $PACKAGES_DIR/${plugin}-${VERSION}.tar.gz"
  else
    echo "Skipping $plugin (not found)"
  fi
done

echo ""
echo "All packages created in $PACKAGES_DIR/"
ls -la "$PACKAGES_DIR"/*.tar.gz 2>/dev/null || true
