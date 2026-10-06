# Ghosten Player Fork Maintenance

This fork is the maintained, coexistence-safe TV build used on the S901
projector. It intentionally uses the package id `com.ghosten.player.fork` so it
can be installed alongside the upstream application.

## Repositories

- App: `AAAAsea/Ghosten-Player`
- Player and native packages: `AAAAsea/Ghosten-Player-flutter-packages`
- Upstream app: `GhostenEditor/Ghosten-Player`
- Upstream packages: `GhostenEditor/Ghosten-Player-flutter-packages`

The long-lived branch in both fork repositories is `fork-main`. Feature
branches target `fork-main`. Keep experimental UI work, including
`ui/tv-redesign`, separate until it has its own review and regression pass.

## Dependency update order

The app pins `video_player` to an exact commit in the package fork.

1. Change and test the package repository.
2. Push the package commit.
3. Update the SHA in `pubspec.yaml` and run `flutter pub get` in the app.
4. Commit both `pubspec.yaml` and `pubspec.lock`.
5. Run app analysis, Android unit tests, and a TV APK build.

Never point a release at a moving package branch.

## Toolchain

- Flutter `3.32.8`
- Java `17`
- Android compile SDK `36`
- Android NDK `27.0.12077973`
- Minimum Android SDK `21`
- Projector ABI: `armeabi-v7a`

The Media3 FFmpeg extension is vendored in `android/app/libs`. Its upstream
provenance and hashes are documented beside the AAR. Do not remove it: TrueHD
and DTS support on the projector depend on it.

## Versioning and releases

Fork releases use `v<upstream-version>-fork.<revision>`, for example
`v2.4.7-fork.4`. The release workflow derives a monotonically increasing
Android version code from all four numeric components.

Release APKs are signed by the fork signing identity. The certificate SHA-256
is:

`97821f8dea4b7706d42b067d2e6c54618ac63d106d97f13e3a18e5c103f8262d`

Signing material is stored only in GitHub Actions secrets and the maintainer's
private local backup. Never commit keystores or passwords.

To publish, tag the tested `fork-main` commit:

```bash
git tag v2.4.7-fork.5
git push origin v2.4.7-fork.5
```

The fork release workflow builds signed TV APKs for `armeabi-v7a` and
`arm64-v8a`, records checksums, and publishes the GitHub release.

## Required regression checks

Automated checks:

- `flutter analyze`
- Dart track-preference tests
- Android SSA sanitizer tests
- TV debug APK compilation

Device checks on the S901 projector:

1. Official and fork packages remain installed side by side.
2. TrueHD and DTS audio tracks are selectable.
3. Selected audio and subtitle tracks survive app restart.
4. A selected subtitle size (`60%` through `140%`) survives app restart and
   affects both embedded ASS and ordinary text subtitles.
5. `Thor The Dark World` bilingual ASS subtitles render; this file contains
   invalid `PlayResX: 0` and `PlayResY: 0` metadata.
6. Subtitle tracks with valid play resolutions are unchanged.
7. The build is Release/AOT and does not have the `DEBUGGABLE` package flag.
8. TMDB scraping works after the user supplies a TMDB v3 API key in TV
   settings. Never log or commit that key.

## Upstream sync

Fetch upstream regularly, review release notes and diffs, and merge deliberately
into a short-lived branch based on `fork-main`. Resolve the package repository
first when upstream changes player APIs. Do not force-push `fork-main` or
silently replace the pinned package SHA.
