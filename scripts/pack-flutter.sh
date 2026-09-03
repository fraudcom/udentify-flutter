#!/bin/bash
#
# Usage:
#   ./scripts/pack-flutter.sh                # pack every plugin
#   ./scripts/pack-flutter.sh ocr-flutter    # pack only the given plugin(s)

VERSION="26.3.0814"
PACKAGES_DIR="packages"
ALL_PLUGINS=(
  "udentify-core-flutter"
  "ocr-flutter"
  "liveness-flutter"
  "mrz-flutter"
  "nfc-flutter"
  "video-call-flutter"
)

# Local build state must never reach the customer: it carries this machine's absolute
# paths and would make the archive non-reproducible.
EXCLUDES=(
  "--exclude=.DS_Store"
  "--exclude=._*"
  "--exclude=.dart_tool"
  "--exclude=.gradle"
  "--exclude=build"
  "--exclude=Pods"
  "--exclude=.symlinks"
)

set -e
cd "$(dirname "$0")/.."

if [ "$#" -gt 0 ]; then
  PLUGINS=("$@")
else
  PLUGINS=("${ALL_PLUGINS[@]}")
fi

mkdir -p "$PACKAGES_DIR"

for plugin in "${PLUGINS[@]}"; do
  if [ -d "$PACKAGES_DIR/$plugin" ]; then
    archive="$PACKAGES_DIR/${plugin}-${VERSION}.tar.gz"
    echo "Packing $plugin..."
    # Only remove the archive being rebuilt, so packing a single plugin leaves the rest intact.
    rm -f "$archive"
    COPYFILE_DISABLE=1 tar "${EXCLUDES[@]}" -czf "$archive" -C "$PACKAGES_DIR" "$plugin"
    echo "  Created $archive"
  else
    echo "Skipping $plugin (not found)"
  fi
done

echo ""
echo "Packages available in $PACKAGES_DIR/"
ls -la "$PACKAGES_DIR"/*.tar.gz 2>/dev/null || true
