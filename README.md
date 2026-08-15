# GET.teksi

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

**Shared**
Phone + OTP auth · profile and ratings · wallet with top-ups and transaction ledger · promo codes and referrals · saved places · notifications · safety centre with emergency contacts and trip sharing · settings with dark/light theme.

---

## Platforms

| Target | Status |
|---|---|
| Web | Built and driven end-to-end in a browser |
| Android | Configured, GMS-free; needs the Android SDK to build |
| iOS | Configured; needs macOS + Xcode to build |
| Huawei | Same GMS-free Android build runs on HarmonyOS 2–4 / EMUI; HarmonyOS NEXT needs the OpenHarmony Flutter fork |

**Huawei support is real, not incidental.** The usual thing that breaks a Flutter ride-hailing app on Huawei is `google_maps_flutter`, which needs Google Play Services. This app uses `flutter_map` over OpenStreetMap tiles instead — no Google SDK, no API key, no GMS anywhere in the dependency graph (verified by scanning every resolved package's Gradle files). The same release build you ship to Play runs on Huawei and passes AppGallery review on that axis.

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
    formats.dart        Money (sen everywhere), distance, time, phone
    bus.dart            Realtime transport seam
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

Today the app is single-device: the simulated marketplace and one real user share a process, so ride events fan out over a plain broadcast stream.

`lib/core/bus.dart` is the one seam for changing that. It defines a two-member `RealtimeTransport` interface and ships a `LocalTransport`. A production transport implements the same interface against websockets, Supabase Realtime, or MQTT — publishing `BusEvent`s to a server and surfacing remote ones on `events`. Nothing above that file changes.

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
- **Routes** are synthesised geometry, not real road routing. Distances apply a 1.35× urban detour factor to straight-line distance. Wire in OSRM/Valhalla/Mapbox in `lib/core/geo.dart` for real turn-by-turn.
- **Auth** has no SMS gateway: the OTP screen shows the code it "sent" and accepts it. Anything real needs a server.
- **Location** ships seeded to the city centre behind a `LocationService` interface, so every target builds without a GPS plugin. See PLATFORMS.md for wiring up `geolocator` or HMS Location Kit.
- **Fares** are loosely calibrated to Klang Valley street pricing (MYR). Tariffs live in `lib/services/pricing.dart`.
- **Release signing** still uses the Android debug key. Replace it before any store submission.
- Commission is 9.9% of the fare, shown to drivers on every order before they bid.
