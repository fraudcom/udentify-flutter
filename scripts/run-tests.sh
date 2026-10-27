#!/bin/bash
#
# Runs the Dart unit tests of every plugin.
#
# Usage:
#   ./scripts/run-tests.sh                 # all plugins
#   ./scripts/run-tests.sh nfc-flutter     # only the given plugin(s)
#
# These cover the Dart layer: models, method-channel calls and the events the native side sends.
# The Kotlin and Swift code is verified by building the test app, not by these tests.

set -e
cd "$(dirname "$0")/.."

source scripts/flutter-standard.sh
require_standard_flutter

ALL_PLUGINS=(udentify-core-flutter ocr-flutter liveness-flutter mrz-flutter nfc-flutter video-call-flutter)

if [ "$#" -gt 0 ]; then
  PLUGINS=("$@")
else
  PLUGINS=("${ALL_PLUGINS[@]}")
fi

failed=()
for plugin in "${PLUGINS[@]}"; do
  echo "== $plugin"
  if [ ! -d "packages/$plugin/test" ]; then
    echo "  no tests"
    continue
  fi
  (cd "packages/$plugin" && flutter test) || failed+=("$plugin")
done

if [ "${#failed[@]}" -gt 0 ]; then
  echo ""
  echo "FAILED: ${failed[*]}"
  exit 1
fi
echo ""
echo "All plugin tests passed."
