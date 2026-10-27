#!/bin/bash
#
# The Flutter version every shipped archive is tested and packed with. Sourced by run-tests.sh and
# pack-flutter.sh, which refuse to run on anything else, so an archive never comes from a tree that was
# only checked on another toolchain. Raise it here when the standard moves.
#
# To use another version deliberately (a bug repro, say), run with ALLOW_OTHER_FLUTTER=1.
# The Flutter SDK itself is not part of the repo: get 3.38.10 from the stable archive,
# https://docs.flutter.dev/install/archive, and put its bin/ on PATH.

STANDARD_FLUTTER_VERSION="3.38.10"

require_standard_flutter() {
  if [ "${ALLOW_OTHER_FLUTTER:-}" = "1" ]; then
    return 0
  fi
  if ! command -v flutter >/dev/null 2>&1; then
    echo "error: flutter is not on PATH. Shipping uses Flutter $STANDARD_FLUTTER_VERSION." >&2
    exit 1
  fi
  local actual
  actual="$(flutter --version --machine 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])' 2>/dev/null)"
  if [ "$actual" != "$STANDARD_FLUTTER_VERSION" ]; then
    echo "error: Flutter ${actual:-unknown} is on PATH ($(command -v flutter)); shipping uses Flutter $STANDARD_FLUTTER_VERSION." >&2
    echo "       Put Flutter $STANDARD_FLUTTER_VERSION first on PATH, or set ALLOW_OTHER_FLUTTER=1 to override." >&2
    exit 1
  fi
}
