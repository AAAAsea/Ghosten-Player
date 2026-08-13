# macOS development setup

This fork pins Flutter `3.32.8`, matching the version used by the upstream GitHub Actions workflows.

## Local layout

- Project: `~/Developer/Ghosten-Player`
- Flutter: `~/Developer/flutter`
- Android SDK: `~/Library/Android/sdk`
- Java: JDK 17

The paths can be overridden with `GHOSTEN_DEVELOPER_ROOT`, `GHOSTEN_FLUTTER_ROOT`, `GHOSTEN_ANDROID_HOME`, and `GHOSTEN_JAVA_HOME`.

## First-time setup

```sh
cd ~/Developer/Ghosten-Player
./tool/bootstrap_macos.sh
source tool/env.sh
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973" "cmake;3.22.1"
flutter doctor -v
```

The Android license command is intentionally interactive and is never accepted automatically by the bootstrap script.

## Daily workflow

Load the project toolchain in each new shell:

```sh
cd ~/Developer/Ghosten-Player
source tool/env.sh
```

Run all local checks:

```sh
./tool/check.sh
```

Build the Android TV debug APK:

```sh
./tool/build_tv.sh --debug
```

The APK is written under `build/app/outputs/flutter-apk/`.

## Git remotes

- `origin`: personal fork (`AAAAsea/Ghosten-Player`), push enabled
- `upstream`: official project (`GhostenEditor/Ghosten-Player`), fetch only

Fetch upstream changes without changing local work:

```sh
git fetch upstream
```
