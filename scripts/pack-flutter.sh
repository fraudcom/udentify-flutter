#!/bin/bash
#
# Usage:
#   ./scripts/pack-flutter.sh                # pack every plugin
#   ./scripts/pack-flutter.sh ocr-flutter    # pack only the given plugin(s)

VERSION="26.3.0928"
PACKAGES_DIR="packages"
ALL_PLUGINS=(
  "udentify-core-flutter"
  "ocr-flutter"
  "liveness-flutter"
  "mrz-flutter"
  "nfc-flutter"
  "video-call-flutter"
)

# What must never reach the customer. Local build state carries this machine's absolute paths and
# makes the archive non-reproducible; editor folders and OS files are noise; the rest is maintainer
# tooling (tests, lint config, Flutter tool metadata, lockfiles) that a plugin consumer has no use for.
# Patterns starting with "/" are anchored to the plugin's own root.
EXCLUDES=(
  --exclude=".DS_Store"
  --exclude="._*"
  --exclude=".dart_tool/"
  --exclude=".gradle/"
  --exclude="build/"
  --exclude="Pods/"
  --exclude=".symlinks/"
  --exclude=".idea/"
  --exclude=".vscode/"
  --exclude="*.iml"
  --exclude="*.log"
  --exclude="local.properties"
  --exclude="/test/"
  --exclude="/android/src/test/"
  --exclude="/.metadata"
  --exclude="/.gitignore"
  --exclude="/android/.gitignore"
  --exclude="/ios/.gitignore"
  --exclude="/pubspec.lock"
  --exclude="/analysis_options.yaml"
  --exclude="/OCR_UI_WIRING.md"
)

set -e
cd "$(dirname "$0")/.."

source scripts/flutter-standard.sh
require_standard_flutter

if [ "$#" -gt 0 ]; then
  PLUGINS=("$@")
else
  PLUGINS=("${ALL_PLUGINS[@]}")
fi

mkdir -p "$PACKAGES_DIR"

# Build each archive from a filtered copy, so the exclusions above are exact (tar's own patterns
# match at any depth) and nothing local can slip in.
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE:?}"' EXIT

for plugin in "${PLUGINS[@]}"; do
  if [ -d "$PACKAGES_DIR/$plugin" ]; then
    archive="$PACKAGES_DIR/${plugin}-${VERSION}.tar.gz"
    echo "Packing $plugin..."
    # Only remove the archive being rebuilt, so packing a single plugin leaves the rest intact.
    rm -f "$archive"
    mkdir -p "$STAGE/$plugin"
    rsync -a --delete "${EXCLUDES[@]}" "$PACKAGES_DIR/$plugin/" "$STAGE/$plugin/"
    COPYFILE_DISABLE=1 tar -czf "$archive" -C "$STAGE" "$plugin"
    echo "  Created $archive"
  else
    echo "Skipping $plugin (not found)"
  fi
done

# Fingerprint every archive so a vendor re-spun under the same version string can be told
# apart from the previous one. Rebuilt from all archives on disk, not just the ones packed now.
(cd "$PACKAGES_DIR" && shasum -a 256 *.tar.gz > SHA256SUMS)

echo ""
echo "Packages available in $PACKAGES_DIR/"
ls -la "$PACKAGES_DIR"/*.tar.gz 2>/dev/null || true
