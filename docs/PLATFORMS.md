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
- `flutter test` — 199 tests covering the fare engine, geometry, the full
  marketplace state machine (bid → accept → complete → settle), what the
  notification layer declines to send, and WCAG contrast for every colour token
  on every surface in both themes.
- **GMS-free is asserted, not assumed.** The `build-android` job
  unpacks the release APK's `classes*.dex`, extracts its strings, and fails the
  build if any `Lcom/google/android/gms`, `Lcom/google/firebase`, or
  `Lcom/huawei/hms` class descriptor appears. The scan self-checks by requiring
  the app's own `Lmy/getgroup/get_teksi` classes to be present, so a silently
  failed extraction can't pass as a clean result. It runs before the artifact
  upload, so an APK that fails the scan is never published.
- **The marketplace rules are enforced by the database.** The `database` job
  applies the migration to a stock PostgreSQL and runs the policy suite and a
  concurrency test; see [supabase/README.md](../supabase/README.md).
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
- **Notifications** go through `android.app.NotificationManager` and
  `UNUserNotificationCenter` directly — see [Notifications](#notifications).
  No Firebase Cloud Messaging, which is the usual answer and would put GMS back
  in the graph for the same reason `google_maps_flutter` does.
- **Analytics, crash reporting, push transport** — none. Nothing pulls in
  Firebase.

Verified by scanning every resolved package's Gradle files plus this repo's own
`android/` and `ios/` trees for `com.google.android.gms`, `com.google.firebase`,
`google-services`, and `com.huawei.hms`: **zero matches**. The plugins
contributing Android code are `app_links`, `flutter_local_notifications`, `jni`,
`jni_flutter`, `shared_preferences_android`, and `url_launcher_android`.

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
- Core library desugaring on, because `flutter_local_notifications` schedules
  against `java.time`, which is API 26+
- **Signing still uses the debug key.** Replace `signingConfig` with a real
  upload key before any store submission.

Permissions declared in `AndroidManifest.xml` are `INTERNET`,
`ACCESS_NETWORK_STATE`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` and
`POST_NOTIFICATIONS`, `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION`.
Location hardware is declared `required="false"`, so the
app stays installable on devices without GPS — the pickup pin can always be
placed on the map, and a rider who declines the permission gets exactly that.

### iOS

```bash
flutter build ipa --release
```

Requires macOS with Xcode. Set the team and bundle identifier in
`ios/Runner.xcodeproj`. Display name is `GET.teksi`. The only `Info.plist`
usage description is `NSLocationWhenInUseUsageDescription`; the app requests no
camera or contacts permission. Notification permission is requested at runtime
after sign-in and needs no `Info.plist` entry.

---

## Notifications

The bell in the app is a screen you have to visit. A driver waiting for orders
is looking at the road, and a passenger who pocketed their phone finds out the
driver arrived when they take it out again — so the same events that reach the
in-app centre are also handed to the platform.

`lib/core/notifier.dart` is the interface; `lib/core/notifier_device.dart` is
the only implementation, and `SilentNotifier` is what everything falls back to.

| Target | What happens |
|---|---|
| Android | `NotificationManager`, one channel, `POST_NOTIFICATIONS` asked on 13+ |
| iOS | `UNUserNotificationCenter`, permission asked after sign-in |
| Web | Nothing — see below |
| Anything else | Nothing, and no error |

While a driver is on duty the process is also held open by a foreground
service, so those notifications keep arriving with the app behind another one.

**Not Firebase Cloud Messaging.** FCM is how a ride-hailing app normally does
this, and it is the same trap as `google_maps_flutter`: the APK stops working
on a Huawei device, and the CI dex scan would fail the build before it got
there. What the platform's own notification manager gives up in exchange is
real: **it can only fire while the process is alive.** Closing that gap
entirely needs a push transport, and the GMS-free routes to one are HMS Push
for AppGallery builds, APNs directly for iOS, and Web Push for the browser —
three transports, three sets of credentials, and a server that holds them.

Keeping the process alive is the cheaper half of that problem, and on Android
it is solved — see [Staying awake on duty](#staying-awake-on-duty).

Which alerts are worth interrupting someone for is a decision the store makes,
not the platform: `RidesStore.notify(alert:)` is false for things this device's
own user just tapped — raising your own price, cancelling your own ride,
confirming your own SOS. A phone that buzzes half a second after your own thumb
is a phone people turn notifications off on. `test/notifier_test.dart` covers
that split, and covers the backlog, which must not ring at all.

**Asking twice is not possible, so there is a row in Settings.** Every platform
offers this permission once and then stops: Android will not show the prompt
again after a refusal, iOS never shows it twice, and a browser remembers a
denial for the origin. A single reflexive dismissal used to turn the feature
off permanently with nothing anywhere to say so. The Notifications row in
Settings reads the live status, asks when there is still a prompt to show, and
falls through to the system screen when there is not —
`MainActivity.openNotificationSettings()` on Android, `UIApplication`'s
settings URL on iOS, over the `get.teksi/app` channel. It re-reads on resume,
because the answer changes somewhere the app cannot see.

**That row is also how the web gets asked at all.** Browsers honour
`Notification.requestPermission()` during a user gesture and nowhere else, and
a frame after sign-in is not one — so the app does not ask there on startup. A
tap is a gesture. There is no settings screen to fall through to on the web,
so `openSettings()` returns false and the row says so rather than doing
nothing.

**iOS needs one line in `AppDelegate.swift`** — setting the
`UNUserNotificationCenter` delegate. Without it, a notification raised while
the app is in the foreground is delivered to nobody, with no error, which is
most of what this app raises.

---

## Staying awake on duty

A backgrounded Android process gets frozen. It reports no position, receives no
realtime event and raises no notification, while still looking online to the
server — and on the devices this app cares about most, the ones with no Play
Services, OEM battery managers make that happen within a minute or two of
leaving the app. A driver who switches to Waze has backgrounded this app by
definition, so this is the normal case rather than the edge one.

`DutyService.kt` is an ordinary Android foreground service: an ongoing
notification in exchange for not being killed. `MainActivity` starts and stops
it over the `get.teksi/duty` channel, and Dart decides when — `DutyPresence`
in `lib/services/duty_presence.dart`, on the same condition as the position
beacon, which is the point of it.

The service is declared `foregroundServiceType="location"`, which is not
paperwork: from API 29 that type is what stops Android throttling a
backgrounded app's location updates to a handful an hour, and from API 34 the
framework refuses to start such a service unless the location permission is
already granted. `MainActivity` checks that before asking, and answers `false`
rather than throwing when it is missing.

**A refusal is a normal outcome.** The permission may be gone, or the OS may
decline the start outright. `DutyPresence.start` returns false, the app keeps
working exactly as it did before any of this existed — fine in the foreground,
at the mercy of the OS behind it — and the same request is not made again until
something actually changes. There is no retry loop.

**What still ends it:** swiping the app out of the recents list. That destroys
the Activity and the Flutter engine with it, so the service takes its own
notification down (`onTaskRemoved`) rather than advertising a driver as online
with nothing behind it able to take an order. `MainActivity.onDestroy` does the
same for the other ways an Activity can go. A notification that lies is worse
than no notification.

iOS has no equivalent that can be had for the asking — staying alive in the
background there means a background mode entitlement and a conversation with
App Review — so `NoDutyService` says no and means it. Web has no concept of it.

The notification's own words come from the ARB files rather than from the
Kotlin, so the one notification a driver looks at all evening is in their own
language, and switching language while on duty updates it in place.

---

## Device location

Location lives behind one interface in `lib/core/location.dart`:

```dart
abstract class LocationService {
  Future<LatLng?> current();
}
```

`DeviceLocationService` implements it per platform, chosen by a conditional
import so no target carries another's code:

| Target | Implementation |
|---|---|
| Android | `LocationManager` in `MainActivity.kt`, over a method channel |
| iOS | `CLLocationManager` in `LocationBridge.swift`, same channel |
| Web | `navigator.geolocation`, no channel — the browser is the platform |
| Anything else | No handler, so the channel raises and the seed stands |

**Android does not use `geolocator`.** Its Android implementation depends on
Play Services' location library, which would put GMS back into the dependency
graph — the CI dex scan would fail the build, and rightly: an APK that needs
Play Services to find a rider cannot find one on a Huawei device.
`android.location.LocationManager` has been in the platform since API 1 and
needs nothing from Google. What it gives up is the fused provider's sensor
blending, which for placing a pickup pin the rider can drag is not much.

Every failure returns null rather than throwing — permission refused, location
switched off, no fix inside the timeout, no implementation at all — and the app
carries on from the city centre. `test/location_test.dart` covers each of those
paths, because what matters about a location feature is not that it gets a fix
but what it does to the app when it cannot.

On HarmonyOS NEXT, implement the same interface over HMS Location Kit; nothing
above `lib/core/location.dart` touches the platform.
