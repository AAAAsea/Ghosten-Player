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
The default TV build contains both 32-bit and 64-bit ARM libraries so it also
runs on projector firmware whose userspace is limited to `armeabi-v7a`.
TV builds use the separate Android package `com.ghosten.player.enhanced` and
the name `Ghosten Player Enhanced`. The upstream self-update mechanism is
disabled so future releases remain under this fork's control.

The upstream API runtime is distributed as a precompiled AAR. Its native
libraries are reused unchanged, while `android/compat/api` provides a
source-built Android service adapter. The adapter preserves the public
upstream API identity under Enhanced's independent package and signing key.

Release signing uses `android/app/.signing/ghosten-enhanced.jks`. Its password
is stored in the macOS Keychain service
`com.ghosten.player.enhanced.signing`, not in the repository. Back up the
keystore separately; losing it prevents in-place upgrades of installed builds.

## Git remotes

- `origin`: personal fork (`AAAAsea/Ghosten-Player`), push enabled
- `upstream`: official project (`GhostenEditor/Ghosten-Player`), fetch only

Fetch upstream changes without changing local work:

```sh
git fetch upstream
```
