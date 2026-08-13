#!/usr/bin/env bash
set -euo pipefail

readonly FLUTTER_VERSION="3.32.8"
readonly COMMAND_LINE_TOOLS_REVISION="15859902"
readonly COMMAND_LINE_TOOLS_SHA256="835b62a26162b229b441d1f6d4680383815a270809eb33522c0d480fa5002c4e"
readonly DEVELOPER_ROOT="${GHOSTEN_DEVELOPER_ROOT:-$HOME/Developer}"
readonly INSTALL_FLUTTER_ROOT="${GHOSTEN_FLUTTER_ROOT:-$DEVELOPER_ROOT/flutter}"
readonly INSTALL_ANDROID_SDK_ROOT="${GHOSTEN_ANDROID_HOME:-$HOME/Library/Android/sdk}"

mkdir -p "$DEVELOPER_ROOT" "$INSTALL_ANDROID_SDK_ROOT/cmdline-tools"

if [[ ! -x "$INSTALL_FLUTTER_ROOT/bin/flutter" ]]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$INSTALL_FLUTTER_ROOT"
  git -C "$INSTALL_FLUTTER_ROOT" switch -c stable
fi

if [[ ! -x "$INSTALL_ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
  readonly TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEMP_DIR"' EXIT
  readonly ARCHIVE="$TEMP_DIR/commandlinetools.zip"
  curl --fail --location --output "$ARCHIVE" \
    "https://dl.google.com/android/repository/commandlinetools-mac_arm64-${COMMAND_LINE_TOOLS_REVISION}_latest.zip"
  echo "$COMMAND_LINE_TOOLS_SHA256  $ARCHIVE" | shasum -a 256 --check
  unzip -q "$ARCHIVE" -d "$TEMP_DIR/unpacked"
  mv "$TEMP_DIR/unpacked/cmdline-tools" "$INSTALL_ANDROID_SDK_ROOT/cmdline-tools/latest"
fi

source "$(dirname "$0")/env.sh"
flutter config --android-sdk "$INSTALL_ANDROID_SDK_ROOT"

cat <<EOF

Toolchains are installed. Android requires one explicit license step:

  source tool/env.sh
  sdkmanager --licenses

After accepting the licenses, install the pinned build packages:

  sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973" "cmake;3.22.1"
  flutter doctor -v
EOF
