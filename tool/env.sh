#!/usr/bin/env bash

# Source this file when working on Ghosten Player:
#   source tool/env.sh

export FLUTTER_ROOT="${GHOSTEN_FLUTTER_ROOT:-$HOME/Developer/flutter}"
export ANDROID_HOME="${GHOSTEN_ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="${GHOSTEN_JAVA_HOME:-$(/usr/libexec/java_home -v 17)}"
export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
