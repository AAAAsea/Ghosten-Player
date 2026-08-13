#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tool/env.sh"
cd "$PROJECT_ROOT"

flutter pub get
flutter build apk \
  --target=lib/main_tv.dart \
  --flavor=tv \
  --target-platform=android-arm,android-arm64 \
  "$@"
