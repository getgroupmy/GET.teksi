# Platforms

One Flutter codebase, four targets. This file records exactly how each one is
built, and — importantly — which of them are actually built and verified
versus which still need a machine with the relevant SDK.

## Verification status

| Target | Build command | Verified |
|---|---|---|
| **Web** | `flutter build web --release --no-web-resources-cdn` | ✅ Built in CI; served and driven end-to-end in Chromium |
| **Android** | `flutter build apk --release` / `appbundle` | ✅ Release APK and AAB built in CI (`build-android`) |
| **iOS** | `flutter build ios --release --no-codesign` | ✅ Compiled unsigned in CI on macOS (`build-ios`); a signed `ipa` still needs your certificates |
| **HarmonyOS NEXT** | `flutter build hap --release` (OpenHarmony fork) | ⚠️ Not built — needs the OpenHarmony Flutter SDK fork, which has no hosted runner |

Every push runs [`.github/workflows/ci.yml`](../.github/workflows/ci.yml), which
also enforces the properties this app's platform story depends on:

- `dart format --set-exit-if-changed` and `flutter analyze --fatal-infos
  --fatal-warnings` — clean, no errors, lints, or infos.
- `flutter test` — 79 tests covering the fare engine, geometry, the full
  marketplace state machine (bid → accept → complete → settle), and WCAG
  contrast for every colour token on every surface in both themes.
- **GMS-free is asserted, not assumed.** The `huawei-compatibility` job
  unpacks the release APK's `classes*.dex`, extracts its strings, and fails the
  build if any `Lcom/google/android/gms`, `Lcom/google/firebase`, or
  `Lcom/huawei/hms` class descriptor appears. The scan self-checks by requiring
  the app's own `Lmy/getgroup/get_teksi` classes to be present, so a silently
  failed extraction can't pass as a clean result.
- **CanvasKit is bundled, not fetched.** The web job asserts
  `canvaskit.wasm` is in the output *and* that the build config carries
  `"useLocalCanvasKit":true` — the flag that makes the loader resolve to the
  local copy rather than gstatic, which is unreachable in mainland China.

The only remaining unbuilt target is HarmonyOS NEXT, because its toolchain is a
vendor fork of Flutter that no hosted runner provides. Build it locally with the
steps below before shipping to AppGallery.

---

## Why this app runs on Huawei at all

Huawei phones sold since 2019 ship **without Google Play Services (GMS)**. The
usual thing that breaks a Flutter ride-hailing app on them is
`google_maps_flutter`, which is a thin wrapper over the GMS Maps SDK: no GMS,
no map, and often no app launch at all.

This app was built to avoid that dependency from the start:

- **Maps** use `flutter_map` drawing OpenStreetMap raster tiles over a plain
  HTTP fetch. No Google SDK, no API key, no GMS.
- **Storage** is `shared_preferences`, which is AndroidX only.
- **Push, analytics, crash reporting** — none. Nothing pulls in Firebase.

Verified by scanning every resolved package's Gradle files plus this repo's own
`android/` and `ios/` trees for `com.google.android.gms`, `com.google.firebase`,
`google-services`, and `com.huawei.hms`: **zero matches**. The only plugins
contributing Android code are `shared_preferences_android`,
`path_provider_android`, `jni`, and `jni_flutter`.

You can re-run that check any time:

```bash
grep -rIn -E "com\.google\.android\.gms|com\.google\.firebase|google-services" android/ ios/
```

### The two Huawei tiers

Huawei support is not one thing. It splits by OS generation, and the split
matters:

**1. HarmonyOS 2/3/4 and EMUI — the vast majority of Huawei phones in use.**
These keep an AOSP-compatible layer and run ordinary Android APKs. Our
GMS-free release build installs and runs as-is. Ship the same artefact you ship
to Play:

```bash
flutter build appbundle --release   # or: flutter build apk --release
```

Then upload to AppGallery Connect. Because the app requests no GMS APIs, it
passes AppGallery's review on that axis without an HMS variant or an
`agconnect-services.json`. `minSdk` is set to 23, which covers EMUI 4/5 devices.

**2. HarmonyOS NEXT (5.x) — the clean-room release with no AOSP layer.**
APKs do not run here; apps are `.hap` packages. Flutter does not support this
in the upstream SDK. The OpenHarmony SIG maintains a fork that adds an `ohos`
target:

```bash
# One-time: install the forked SDK alongside stock Flutter
git clone -b master https://gitee.com/openharmony-sig/flutter_flutter.git
export PATH="$PWD/flutter_flutter/bin:$PATH"

# Needs DevEco Studio + the OpenHarmony SDK, with these set:
export OHOS_SDK_HOME=/path/to/ohos-sdk
export HOS_SDK_HOME=/path/to/hms-sdk

flutter config --enable-ohos
flutter create --platforms ohos .   # generates the ohos/ module
flutter build hap --release
```

The `ohos/` module is deliberately **not** committed here: it must be generated
by the forked toolchain that will build it, and a hand-written one would be
guesswork that breaks on the first real build. Two things to expect when you do
generate it:

- `shared_preferences` needs an OpenHarmony implementation. The SIG publishes
  ports of the common plugins; if one is missing, `Store` in
  `lib/core/storage.dart` is a single small class and is trivial to back with
  OpenHarmony preferences directly.
- `flutter_map` is pure Dart over HTTP, so it needs no port.

### Map tiles in Huawei's home market

`tile.openstreetmap.org` is unreliable or blocked inside mainland China, and
OSM's public tile server has a usage policy that forbids production traffic
anyway. Before shipping to AppGallery in CN, point the tile URL at your own
server or a commercial provider. It is one line:

```dart
// lib/widgets/map_view.dart
urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
```

The same applies to the web build: `--no-web-resources-cdn` is used so CanvasKit
is served from your own origin rather than `gstatic.com`, which is also blocked
in CN. Build web without that flag and the app will not start there.

---

## Per-target notes

### Web

```bash
flutter build web --release --no-web-resources-cdn
```

Output in `build/web/`, servable as static files. The UI is constrained to a
480 px column and centred, so it reads as a phone on desktop rather than
stretching. Installable as a PWA via the generated `manifest.json`.

### Android

```bash
flutter build apk --release        # sideload / direct download
flutter build appbundle --release  # Play Store and AppGallery
```

Configured in `android/app/build.gradle.kts`:
- `applicationId` `my.getgroup.get_teksi`
- `minSdk 23`, R8 shrinking on in release
- **Signing still uses the debug key.** Replace `signingConfig` with a real
  upload key before any store submission.

Permissions declared in `AndroidManifest.xml` are `INTERNET` and
`ACCESS_NETWORK_STATE` only. Location hardware is declared `required="false"`,
so the app stays installable on devices without GPS — the pickup pin can always
be placed on the map.

### iOS

```bash
flutter build ipa --release
```

Requires macOS with Xcode. Set the team and bundle identifier in
`ios/Runner.xcodeproj`. Display name is `GET.teksi`. No `Info.plist` usage
descriptions are needed as shipped, because the app requests no location,
camera, or contacts permission — add `NSLocationWhenInUseUsageDescription` at
the same time you wire up a real GPS provider.

---

## Wiring up real device location

The app deliberately ships without a GPS plugin so that every target — including
HarmonyOS — builds without a per-platform dependency. Location lives behind one
interface in `lib/state/session.dart`:

```dart
abstract class LocationService {
  Future<LatLng?> current();
}
```

To use real GPS, add `geolocator` and implement that interface, then pass it in
`main.dart`:

```dart
ChangeNotifierProvider(create: (_) => SessionStore(location: GeolocatorLocation())..locate()),
```

Add the matching permissions (`ACCESS_FINE_LOCATION` on Android,
`NSLocationWhenInUseUsageDescription` on iOS). On HarmonyOS NEXT use the HMS
Location Kit behind the same interface. Nothing else in the app touches the
platform.
