# GET.teksi

[![CI](https://github.com/getgroupmy/GET.teksi/actions/workflows/ci.yml/badge.svg)](https://github.com/getgroupmy/GET.teksi/actions/workflows/ci.yml)

A ride-hailing app built on the inDrive model: **the passenger names the fare, drivers bid, the passenger picks who to ride with.** Passenger and driver live in the same app — one account, one wallet, one history, switch sides whenever you like.

One Flutter codebase targeting **Android, iOS, Web and Huawei**.

```bash
flutter pub get
flutter run            # any connected device
flutter run -d chrome  # web
```

---

## The core idea

Unlike a metered service, there is no price the platform imposes. GET.teksi computes a *recommended* fare and uses it purely as an anchor:

1. Passenger sets a destination and drags the fare where they want it. Live feedback says whether the offer reads as **below market / fair / great / above market**.
2. The order is published. Nearby drivers see the destination, the distance, and the passenger's price *before* deciding anything.
3. Each driver either **takes the asking price** or **counter-offers** their own.
4. The passenger sees every bid — price, ETA, rating, trip count, car — and picks one. Or raises their price if nobody is biting.
5. Pickup → arrival → trip → payment → both sides rate each other.

Bids expire after 90 seconds so a stale list never blocks the passenger, accepting one bid voids the rest, and an order nobody takes expires rather than lingering in the driver feed.

---

## What's in it

**Passenger**
Map with live nearby cars · destination search with recents, saved places and offline geocoding · multi-stop routes · five service verticals (City, Intercity, Delivery, Moto, Freight) · Economy / Comfort / XL · fare slider with market feedback · payment method, passenger count, note to driver, seven trip options · live bid list with accept/decline · raise-your-price · live driver tracking · in-trip chat with quick phrases · call, share trip, SOS · cancel with reasons · rate, tag and tip · history with full fare receipts.

**Driver**
Onboarding with vehicle and document set · go online/offline · order feed sorted by nearest / highest / newest, filtered by minimum fare and pickup distance · accept the asking price or counter-offer, with net-of-commission shown live · withdraw a pending offer · job card driving the trip forward one button at a time (on my way → arrived → start → finish) · earnings dashboard by day/week/all-time with per-hour and per-trip breakdowns · vehicle and document management.

**Languages**
English and Bahasa Melayu, switched in Settings. Every screen is translated — 491 keys, with a test that fails if an English key has no Malay entry. What is still English is text the stores write rather than the screens: notification titles and bodies, wallet ledger descriptions and the driver's document labels. Those are persisted records written without a `BuildContext`, and the server writes the ledger half in English too, so localising the client half alone would produce a two-language wallet. Making them translatable means storing a key and arguments instead of a sentence, which changes the persisted shape.

The Malay is machine-written and wants a native speaker's pass before it ships.

**Notifications**
An in-app centre with an unread badge, fed by real events from both sides: a driver bidding on your order, your bid being accepted or declined, each stage of the trip, and a cancellation by the other party. Those also surface as ordinary OS notifications — Android's `NotificationManager` and iOS's `UNUserNotificationCenter`, asked for once after sign-in — with one exception: things you did yourself are recorded in the centre but never buzz the phone that just tapped them. What still does not exist is *push*: the notification manager can only fire while the process is alive, so nothing arrives while the app is closed. Firebase Cloud Messaging is the usual answer and is ruled out here: it would put Play Services back in the dependency graph and fail the GMS scan. See [docs/PLATFORMS.md](docs/PLATFORMS.md) for what a GMS-free push transport would take.

**Shared**
Phone + OTP auth · profile and ratings · wallet with top-ups and transaction ledger · promo codes and referrals · saved places · notifications · safety centre with emergency contacts and trip sharing · settings with dark/light theme.

---

## Platforms

| Target | Status |
|---|---|
| Web | Built in CI; driven end-to-end in a browser |
| Android | Release APK + AAB built in CI, GMS-free |
| iOS | Compiled unsigned in CI on macOS; signing needs your certificates |
| Huawei | Same GMS-free Android build runs on HarmonyOS 2–4 / EMUI; HarmonyOS NEXT needs the OpenHarmony Flutter fork |

**Huawei support is real, not incidental.** The usual thing that breaks a Flutter ride-hailing app on Huawei is `google_maps_flutter`, which needs Google Play Services. This app uses `flutter_map` over OpenStreetMap tiles instead — no Google SDK, no API key, no GMS anywhere in the dependency graph. That isn't a claim you have to take on faith: CI unpacks the release APK's dex bytecode on every push and fails the build if a single `com.google.android.gms`, `com.google.firebase`, or `com.huawei.hms` class descriptor shows up. The same release build you ship to Play runs on Huawei and passes AppGallery review on that axis.

---

## Backend

The app runs with no backend at all — on-device transport, simulated
marketplace, local persistence — which is what lets the whole demo work with
nothing to provision. Point the same build at a Supabase project and rides,
bids and chat travel between real devices instead.

The schema is in [`supabase/`](supabase/), and the marketplace rules are
enforced there rather than in the client: a driver cannot see a rival's bid, a
passenger cannot lower the ask once drivers have bid or assign themselves a
driver, a driver cannot move the fare after winning it, and exactly one bid can
ever win a ride. Every one of those is a test that runs on each push against a
real PostgreSQL — including a concurrency test that races two accepts of the
same ride and fails if the lock protecting it is ever weakened.

A project is live in Singapore and both migrations are applied, so pointing the
app at it is one flag:

```sh
flutter run --dart-define-from-file=config/get-teksi.json
```

Leave the flag off and the app runs entirely on-device with the simulated
marketplace, exactly as before — which is what keeps it demonstrable with
nothing provisioned.

**[supabase/README.md](supabase/README.md)** covers the design, the full rule
table, how to run the suite locally, and what is still missing.

**[docs/PLATFORMS.md](docs/PLATFORMS.md)** has the full picture: exact build commands per target, what was and wasn't verified here, the HarmonyOS NEXT toolchain steps, and the map-tile and CanvasKit changes you need before shipping into mainland China.

---

## Trying it out

The **simulated marketplace** is on by default (Settings → Simulated marketplace). A fleet of bot drivers circulates on the map, bids on your orders — some at your price, some countering — then actually drives to you and completes the trip. In driver mode, bot passengers post orders into your feed and weigh up your bids: a generous offer gets taken quickly, a greedy one often gets declined.

Bot trips are **time-compressed**: a pickup leg that would take minutes plays out in 15–45 seconds, and the main leg in 30–75 seconds, so the whole lifecycle is watchable in one sitting. Longer trips still take proportionally longer than short ones.

---

## Architecture

```
lib/
  models/models.dart    One domain model shared by both roles
  core/
    geo.dart            Haversine, bearings, route synthesis, path interpolation
    routing.dart        Road routes via OSRM, with the on-device estimate behind the same seam
    formats.dart        Money (sen everywhere), distance, time, phone
    bus.dart            Realtime transport seam
    location.dart       Device position, per platform, behind one interface
    notifier.dart       OS notifications, silent where the platform has none
    storage.dart        Namespaced persistence over SharedPreferences
  services/
    pricing.dart        Fare anchor, price verdicts, commission
    simulation.dart     Bot drivers and passengers
  state/
    session.dart        Auth, profile, prefs, wallet, driver profile
    rides.dart          Rides, offers, chat, notifications, ledger
    draft.dart          The passenger's in-progress order
  widgets/              Map, UI primitives, passenger sheets, driver sheets
  screens/              auth / passenger / driver / shared
```

State is `ChangeNotifier` + `provider`; routing is `go_router`, with the auth and role guards in one `redirect`.

**Money** is stored in minor units (sen) everywhere and formatted only at the edges.

**Persistence** writes through on every mutation, so a cold start mid-trip resumes exactly where you were.

### Going multi-device

`lib/core/bus.dart` is the seam. It defines a two-member `RealtimeTransport` interface with two implementations: `LocalTransport`, which keeps ride events in-process for the single-device demo, and `SupabaseTransport`, which carries the same events through Postgres so other devices see them.

Which one is in use is decided once at startup by whether a backend is configured. Nothing above that file knows the difference — the stores publish `BusEvent`s and react to `BusEvent`s either way, which is why the whole backend integration is four files under `lib/core/` and no screen changed.

---

## Tooling

Two third-party skills are vendored under `.claude/skills/` so they travel with
the repo — see [`.claude/skills/README.md`](.claude/skills/README.md) for
sources, licences and local changes.

**[ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** —
searchable UX guidelines, styles and per-stack rules, including a `flutter`
stack. The accessibility pass in [`docs/UI-UX-AUDIT.md`](docs/UI-UX-AUDIT.md)
was run against its native-app checklist; it found a light theme where the
brand colour sat at 1.7:1 as foreground, six touch targets under the platform
minimum, and an animation that ignored reduced-motion.

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py "touch target size" --domain ux
```

**[graphify](https://github.com/Graphify-Labs/graphify)** — maps the repo into a
queryable knowledge graph instead of grepping. Dev tool, not an app dependency;
the Dart pass is deterministic and costs no API calls.

```bash
pip install graphifyy
graphify update .        # 1160 nodes, 1827 edges, 59 communities
```

Only `graphify-out/GRAPH_REPORT.md` is committed; the ~2 MB `graph.json` and
`graph.html` regenerate from the command above.

## Tests

```bash
flutter analyze   # clean
flutter test      # 79 tests
```

Covering colour contrast (every text token against every surface in both themes), the fare engine (class ordering, minimums, peak pressure, commission reconciliation), geometry (haversine, bearings, route endpoints, path interpolation), and the marketplace state machine end to end: publishing, bid ordering, accept-one-declines-the-rest, refusing bids on a closed order, raise-price only while searching, cancellation voiding bids, settlement crediting the driver net of commission, TTL sweeps, the rating queue, unread chat counts, and persistence across a store restart.

---

## Notes and limits

- **Maps** use OpenStreetMap raster tiles — no key, but also no tiles when offline; pins, routes and cars still render correctly over the empty canvas. OSM's public tile server is not licensed for production traffic: point it at your own before shipping.
- **Routes** come from a real road network when one is configured, and from an on-device estimate when not. Point `OSRM_URL` at an [OSRM](https://project-osrm.org) instance and distances, durations and the drawn line are measured along the roads; leave it unset and the app applies a 1.35× urban detour factor to straight-line distance, which is right on average across a city and wrong for any particular trip. The estimate always shows first — the fare never waits on a network call — and the routed numbers replace it when they arrive. The public demo server at `router.project-osrm.org` is explicitly not for production traffic; run your own.
- **Auth** sends a real SMS code when a backend is configured; without one the OTP screen shows the code it "sent" and accepts it, which is what keeps the demo runnable with nothing provisioned.
- **Location** is read from the device — GPS on Android, CoreLocation on iOS, the browser on web — and falls back to the city centre when permission is refused, location is off, or no fix arrives. Android reads `LocationManager` directly rather than using `geolocator`, whose Android implementation would put Play Services back in the graph and break the Huawei build.
- **Fares** are loosely calibrated to Klang Valley street pricing (MYR). Tariffs live in `lib/services/pricing.dart`.
- **Release signing** still uses the Android debug key. Replace it before any store submission.
- Commission is 9.9% of the fare, shown to drivers on every order before they bid.
