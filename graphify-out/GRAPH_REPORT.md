# Graph Report - GET.teksi  (2026-10-04)

## Corpus Check
- 143 files · ~263,141 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 68 file(s) not represented in the graph (top: .csv 35, .xml 7, (none) 5)

## Summary
- 3710 nodes · 4884 edges · 118 communities (95 shown, 23 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 7 edges (avg confidence: 0.92)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `93619936`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_localizations.dart
- app_localizations_en.dart
- app_localizations_ms.dart
- models.dart
- SessionStore
- rides.dart
- build
- core.py
- design_system.py
- pricing.dart
- validate_data.py
- draft.dart
- geo.dart
- LocationBridge
- session.dart
- ui.dart
- simulation.dart
- map_view.dart
- bus.dart
- theme.dart
- router.dart
- offers_sheet.dart
- rate_screen.dart
- formats.dart
- destination_search_screen.dart
- _
- supabase_transport.dart
- onboarding_screen.dart
- main.dart
- notifier_test.dart
- _
- routing_test.dart
- StatelessWidget
- What You Must Do When Invoked
- DesignSystemGenerator
- text_scale_test.dart
- otp_screen.dart
- driver_beacon.dart
- rows.dart
- _
- marketplace_test.dart
- storage.dart
- notification_setting_row_test.dart
- profile_sync_test.dart
- DutyService.kt
- UI/UX Pro Max - Design Intelligence
- driver_beacon_test.dart
- MainActivity
- notifier_device.dart
- ../l10n/app_localizations.dart
- l10n_test.dart
- profile_sync.dart
- 20260815120000_marketplace.sql
- wallet_screen.dart
- ../../models/models.dart
- duty_presence_test.dart
- MainActivity.kt
- safety_screen.dart
- intro_screen.dart
- places.dart
- rows_test.dart
- Backend
- Platforms
- Pre-Delivery Checklist (canonical — the only one)
- Quick Reference
- UI/UX accessibility audit
- order_detail_screen.dart
- price_sheet.dart
- BM25
- reasoning_contract.py
- location.dart
- ../theme.dart
- _
- package:flutter_test/flutter_test.dart
- GET.teksi
- manifest.json
- _select_palette_for_mode
- iOS
- package:flutter/material.dart
- graphify reference: extra exports and benchmark
- date_format_test.dart
- README.md
- dart:math
- live-ride.sh
- GET.teksi — working agreements
- graphify reference: query, path, explain
- Findings and fixes
- AppLocalizations
- session-start.sh
- notification_setting_row.dart
- wait-for-tools.sh
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- Build configuration
- concurrency.sh
- extraction-spec.md
- LaunchImage.imageset/README.md
- labels.dart
- 20260820140000_wallet_ledger.sql
- duty.dart
- run.sh
- 20260821050000_guard_profile_columns.sql
- harness.sql
- Android
- The one rule

## God Nodes (most connected - your core abstractions)
1. `SessionStore` - 89 edges
2. `RidesStore` - 78 edges
3. `_` - 41 edges
4. `_` - 40 edges
5. `DraftStore` - 29 edges
6. `_` - 23 edges
7. `search()` - 20 edges
8. `MainActivity` - 16 edges
9. `DesignSystemGenerator` - 15 edges
10. `build` - 14 edges

## Surprising Connections (you probably didn't know these)
- `Running it` --references--> `validate()`  [INFERRED]
  docs/RELEASING.md → .claude/skills/ui-ux-pro-max/scripts/validate_data.py
- `Staying awake on duty` --references--> `MainActivity`  [INFERRED]
  docs/PLATFORMS.md → android/app/src/main/kotlin/my/getgroup/get_teksi/MainActivity.kt
- `_Fixed` --implements--> `PlaceSearch`  [EXTRACTED]
  test/geocoding_test.dart → lib/core/geocoding.dart
- `_ScriptedLocation` --implements--> `LocationService`  [EXTRACTED]
  test/driver_beacon_test.dart → lib/core/location.dart
- `_FakeNotifier` --implements--> `Notifier`  [EXTRACTED]
  test/notification_setting_row_test.dart → lib/core/notifier.dart

## Import Cycles
- None detected.

## Communities (118 total, 23 thin omitted)

### Community 0 - "app_localizations.dart"
Cohesion: 0.00
Nodes (505): about, accept, acceptAmount, activeTripBanner, activity, add, addACommentOptional, addAStop (+497 more)

### Community 1 - "app_localizations_en.dart"
Cohesion: 0.00
Nodes (497): about, accept, acceptAmount, activeTripBanner, activity, add, addACommentOptional, addAStop (+489 more)

### Community 2 - "app_localizations_ms.dart"
Cohesion: 0.00
Nodes (497): about, accept, acceptAmount, activeTripBanner, activity, add, addACommentOptional, addAStop (+489 more)

### Community 3 - "models.dart"
Cohesion: 0.02
Nodes (108): acceptedAt, address, amount, amountOff, AppNotification, arrivedAt, askingPrice, avatarColor (+100 more)

### Community 4 - "SessionStore"
Cohesion: 0.08
Nodes (44): Role, _RouterNotifier, build, createState, EarningsScreen, _EarningsScreenState, _Period, build (+36 more)

### Community 5 - "rides.dart"
Cohesion: 0.03
Nodes (61): acceptOffer, activeRideFor, addTransaction, _announceOfferChange, _announceRideChange, _applyRemote, _busSub, cancelRide (+53 more)

### Community 6 - "build"
Cohesion: 0.13
Nodes (7): build, _finish, build, build, build, build, build

### Community 7 - "core.py"
Cohesion: 0.07
Nodes (30): _contains_phrase(), detect_domain(), _domain_keywords(), _exact_match_diagnostic(), _exact_row_identity(), _exact_stack_identifier(), _file_signature(), _get_bm25() (+22 more)

### Community 8 - "design_system.py"
Cohesion: 0.06
Nodes (17): ansi_ljust(), _detect_page_type(), format_ascii_box(), format_markdown(), format_master_md(), format_page_override_md(), generate_design_system(), _generate_intelligent_overrides() (+9 more)

### Community 9 - "pricing.dart"
Cohesion: 0.06
Nodes (30): PriceToneLabel, 1, adjusted, base, commissionOn, commissionRate, demandFactor, driverNet (+22 more)

### Community 10 - "validate_data.py"
Cohesion: 0.09
Nodes (37): _catalog_date(), _check_app_interface_contract(), _check_catalog_contract(), _check_catalog_summary(), _check_chart_contract(), _check_color_contract(), _check_core_data_contract(), _check_file() (+29 more)

### Community 11 - "draft.dart"
Cohesion: 0.05
Nodes (41): Place, clear, clearRoute, comment, distanceKm, DraftStep, dropoff, durationMinutes (+33 more)

### Community 12 - "geo.dart"
Cohesion: 0.05
Nodes (41): amplitude, avgSpeedKmh, bearing, bearingBetween, clamped, coord, dir, dist (+33 more)

### Community 13 - "LocationBridge"
Cohesion: 0.07
Nodes (10): CoreLocation, Flutter, AppBridge, AppDelegate, LocationBridge, SceneDelegate, RunnerTests, UIKit (+2 more)

### Community 14 - "session.dart"
Cohesion: 0.05
Nodes (36): AppUser, becomeDriver, clearShortcut, copyWith, creditWallet, darkTheme, debitWallet, driverOnline (+28 more)

### Community 15 - "ui.dart"
Cohesion: 0.05
Nodes (34): action, badge, BannerTone, body, border, build, c, child (+26 more)

### Community 16 - "simulation.dart"
Cohesion: 0.05
Nodes (36): _active, advance, _ageBotOrders, _between, _bidLog, _botById, _botsBidOn, _BotTrip (+28 more)

### Community 17 - "map_view.dart"
Cohesion: 0.06
Nodes (29): approach, bearing, bottomPadding, build, _CarPainter, center, _controller, coord (+21 more)

### Community 18 - "bus.dart"
Cohesion: 0.08
Nodes (30): BacklogLoaded, bearing, _bus, BusEvent, by, ChatSent, _controller, coord (+22 more)

### Community 19 - "theme.dart"
Cohesion: 0.06
Nodes (27): accent, AppColors, AppColorsX, bg, body, brand, brandInk, buildTheme (+19 more)

### Community 20 - "router.dart"
Cohesion: 0.06
Nodes (7): bump, dispose, GoRouterConfig, _notifier, _redirect, router, _session

### Community 21 - "offers_sheet.dart"
Cohesion: 0.07
Nodes (35): _Root, _RootState, Offer, PhoneScreen, _PhoneScreenState, ProfileSetupScreen, _ProfileSetupScreenState, NotificationsScreen (+27 more)

### Community 22 - "rate_screen.dart"
Cohesion: 0.18
Nodes (11): build, _comment, createState, dispose, RateScreen, _RateScreenState, rideId, _stars (+3 more)

### Community 23 - "formats.dart"
Cohesion: 0.06
Nodes (30): clockTime, compactCount, currencySymbol, dateLabel, days, digits, distanceLabel, durationLabel (+22 more)

### Community 24 - "destination_search_screen.dart"
Cohesion: 0.05
Nodes (43): _finish, _buildIntroStep, active, build, _choose, controller, _controllerFor, createState (+35 more)

### Community 25 - "_"
Cohesion: 0.07
Nodes (28): _, baseUrl, _categoryFor, _client, countryCodes, _defaultTimeout, display, Geocoding (+20 more)

### Community 26 - "supabase_transport.dart"
Cohesion: 0.06
Nodes (27): _authSub, _backlogFor, _channels, _client, _consumeSelfWrite, _controller, dispose, _emit (+19 more)

### Community 27 - "onboarding_screen.dart"
Cohesion: 0.07
Nodes (27): autofocus, body, build, _buildVehicleStep, _class, _classHint, _classSeats, _color (+19 more)

### Community 28 - "main.dart"
Cohesion: 0.05
Nodes (30): _askedToNotify, _askToNotify, _beacon, build, createState, dispose, _duty, _dutyService (+22 more)

### Community 29 - "notifier_test.dart"
Cohesion: 0.08
Nodes (21): deliver, main, _messageOn, _offerOn, rides, session, _bid, _car (+13 more)

### Community 30 - "_"
Cohesion: 0.08
Nodes (24): _, baseUrl, _client, decodePolyline, _defaultTimeout, distanceKm, durationMinutes, factor (+16 more)

### Community 31 - "routing_test.dart"
Cohesion: 0.10
Nodes (13): _hit, _kl, main, search, _searchReturning, SocketExceptionLike, status, _dropoff (+5 more)

### Community 32 - "StatelessWidget"
Cohesion: 0.10
Nodes (19): GetTeksiApp, _Field, _Attribution, _CarMarker, _PinMarker, ActionTile, AppCard, AppChip (+11 more)

### Community 33 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 34 - "DesignSystemGenerator"
Cohesion: 0.12
Nodes (3): DesignSystemGenerator, _filter_anti_patterns_for_mode(), _resolve_dial()

### Community 35 - "text_scale_test.dart"
Cohesion: 0.06
Nodes (13): draft, _klcc, layout, main, _maxColumnWidth, _midValley, now, _phone (+5 more)

### Community 36 - "otp_screen.dart"
Cohesion: 0.09
Nodes (21): _autofill, build, _code, _controller, createState, dispose, _error, _expected (+13 more)

### Community 37 - "driver_beacon.dart"
Cohesion: 0.10
Nodes (19): activeInterval, _bearing, _cadence, dispose, DriverBeacon, _generation, idleInterval, _intervalNow (+11 more)

### Community 38 - "rows.dart"
Cohesion: 0.09
Nodes (21): chatFromRow, chatToInsert, _coord, _double, driverLocationToRow, fallback, _iso, _maybeDouble (+13 more)

### Community 39 - "_"
Cohesion: 0.10
Nodes (12): _, Backend, _client, _e164, errors, init, isLive, saveProfile (+4 more)

### Community 40 - "marketplace_test.dart"
Cohesion: 0.10
Nodes (14): askingPrice, buildOffer, buildRide, _car, _dropoff, main, matchedAsking, now (+6 more)

### Community 41 - "storage.dart"
Cohesion: 0.10
Nodes (16): _alphabet, body, bytes, clearAll, hex, init, _instance, _prefix (+8 more)

### Community 42 - "notification_setting_row_test.dart"
Cohesion: 0.17
Nodes (9): calls, canOpenSettings, grantsOnRequest, main, openSettings, pump, requestPermission, show (+1 more)

### Community 43 - "profile_sync_test.dart"
Cohesion: 0.11
Nodes (12): ProfileSync, answerWith, _channel, main, messenger, afterSettle, _car, main (+4 more)

### Community 45 - "UI/UX Pro Max - Design Intelligence"
Cohesion: 0.11
Nodes (17): Before Delivering App UI, Example Workflow, If a search returns 0 results, Output Formats, Query Contract, Rule Categories by Priority, Running the search tool, Step 1: Analyze User Requirements (+9 more)

### Community 46 - "driver_beacon_test.dart"
Cohesion: 0.08
Nodes (19): done, finish, geolocation, readDeviceLocation, beaconWith, calls, current, delay (+11 more)

### Community 48 - "notifier_device.dart"
Cohesion: 0.07
Nodes (23): createNotifier, _appChannel, buildNotifier, _channelDescription, _channelId, _channelName, _DeviceNotifier, _ensureReady (+15 more)

### Community 49 - "../l10n/app_localizations.dart"
Cohesion: 0.09
Nodes (18): build, _continue, _controller, createState, _digits, dispose, _error, _sending (+10 more)

### Community 50 - "l10n_test.dart"
Cohesion: 0.12
Nodes (10): en, json, _keysOf, main, ms, _allowed, _inSlot, _inText (+2 more)

### Community 51 - "profile_sync.dart"
Cohesion: 0.12
Nodes (13): _columnsFor, dispose, _flush, isRunning, _listening, _onChanged, _sameAsSent, _sent (+5 more)

### Community 52 - "20260815120000_marketplace.sql"
Cohesion: 0.12
Nodes (7): offers_guard_write, on_auth_user_created, profiles_touch, public.profiles, public.rides, rides_guard_update, rides_touch

### Community 53 - "wallet_screen.dart"
Cohesion: 0.14
Nodes (14): Txn, _card, _cardTail, createState, first, initState, _load, _loading (+6 more)

### Community 54 - "../../models/models.dart"
Cohesion: 0.05
Nodes (35): avatarColors, demoCardName, demoCardTail, driverNames, hash, passengerNames, pickAvatarColor, pickupNotes (+27 more)

### Community 55 - "duty_presence_test.dart"
Cohesion: 0.13
Nodes (12): body, calls, _car, goOnDuty, grant, main, presenceWith, service (+4 more)

### Community 57 - "safety_screen.dart"
Cohesion: 0.10
Nodes (17): _channel, fix, lat, lng, readDeviceLocation, _addContact, build, createState (+9 more)

### Community 58 - "intro_screen.dart"
Cohesion: 0.15
Nodes (11): body, build, createState, _finish, icon, _index, IntroScreen, _IntroScreenState (+3 more)

### Community 59 - "places.dart"
Cohesion: 0.14
Nodes (13): allPlaces, cityCenter, cityName, fuzzySearch, intercityPlaces, _p, places, q (+5 more)

### Community 60 - "rows_test.dart"
Cohesion: 0.14
Nodes (12): RideStatus, _asReadBack, _klcc, main, _midValley, now, _offer, _place (+4 more)

### Community 61 - "Backend"
Cohesion: 0.20
Nodes (10): Applying it to a project, Backend, How it connects to the app, Known gaps, Pointing the app at it, Running the tests, Sign-in, Testing the deployment rather than the schema (+2 more)

### Community 62 - "Platforms"
Cohesion: 0.15
Nodes (12): Android, Device location, iOS, Map tiles in Huawei's home market, Notifications, Per-target notes, Platforms, The map is OpenStreetMap (+4 more)

### Community 63 - "Pre-Delivery Checklist (canonical — the only one)"
Cohesion: 0.15
Nodes (12): Accessibility, Common Rules for Professional UI + Pre-Delivery Checklist, Icons & Visual Elements, Interaction, Interaction (App), Layout, Layout & Spacing, Light/Dark Mode (+4 more)

### Community 64 - "Quick Reference"
Cohesion: 0.15
Nodes (12): 10. Charts & Data (LOW), 1. Accessibility (CRITICAL), 2. Touch & Interaction (CRITICAL), 3. Performance (HIGH), 4. Style Selection (HIGH), 5. Layout & Responsive (HIGH), 6. Typography & Color (MEDIUM), 7. Animation (MEDIUM) (+4 more)

### Community 65 - "UI/UX accessibility audit"
Cohesion: 0.40
Nodes (4): Not addressed, UI/UX accessibility audit, Verification, What the skill was and wasn't used for

### Community 67 - "order_detail_screen.dart"
Cohesion: 0.12
Nodes (15): build, _counter, createState, _Detail, icon, label, _Meta, onTap (+7 more)

### Community 68 - "price_sheet.dart"
Cohesion: 0.07
Nodes (23): build, icon, IdleSheet, label, onTap, _serviceIcons, _Shortcut, sub (+15 more)

### Community 70 - "reasoning_contract.py"
Cohesion: 0.22
Nodes (5): apply_decision_rules(), _object_without_duplicates(), parse_decision_rules(), _validate_action(), _check_reasoning_contract()

### Community 71 - "location.dart"
Cohesion: 0.22
Nodes (6): current, DeviceLocationService, LocationService, SeededLocationService, timeout, _ScriptedLocation

### Community 72 - "../theme.dart"
Cohesion: 0.15
Nodes (11): DriverDocument, document, _DocumentRow, _edit, first, VehicleScreen, createState, dispose (+3 more)

### Community 73 - "_"
Cohesion: 0.18
Nodes (10): _, AppConfig, hasBackend, hasGeocoding, hasRouting, nominatimUrl, osrmUrl, supabaseKey (+2 more)

### Community 74 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.11
Nodes (11): _kl, main, pumpMap, found, _hasTextField, _labels, main, out (+3 more)

### Community 75 - "GET.teksi"
Cohesion: 0.18
Nodes (11): Architecture, Backend, GET.teksi, Going multi-device, Notes and limits, Platforms, Tests, The core idea (+3 more)

### Community 76 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 77 - "_select_palette_for_mode"
Cohesion: 0.22
Nodes (5): _contrast_ratio(), _derive_dark_palette(), _palette_is_dark(), _relative_luminance(), _select_palette_for_mode()

### Community 78 - "iOS"
Cohesion: 0.29
Nodes (7): Background delivery, Before submitting, iOS, Running it, Status, The seven secrets, What you have to do by hand, once

### Community 80 - "package:flutter/material.dart"
Cohesion: 0.06
Nodes (23): createState, DriverHomeScreen, _DriverHomeScreenState, _lastRatedRide, createState, icon, initState, label (+15 more)

### Community 81 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 82 - "date_format_test.dart"
Cohesion: 0.25
Nodes (4): formatted, main, _monthYearIn, pumpWidget

### Community 83 - "README.md"
Cohesion: 0.32
Nodes (3): `graphify/` — codebase knowledge graph, Project skills, `ui-ux-pro-max/` — UI/UX design intelligence

### Community 85 - "dart:math"
Cohesion: 0.29
Nodes (4): _klcc, main, _midValley, _penang

### Community 86 - "live-ride.sh"
Cohesion: 0.48
Nodes (5): api(), bad(), ok(), live-ride.sh script, step()

### Community 87 - "GET.teksi — working agreements"
Cohesion: 0.33
Nodes (5): CI, GET.teksi — working agreements, graphify, Local gates, Verification

### Community 88 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 89 - "Findings and fixes"
Cohesion: 0.29
Nodes (7): 1. Colour contrast — the light theme was largely unusable, 2. Touch targets below the platform minimum, 3. Reduced motion was not respected, 4. Colour was the only indicator of driver duty state, 5. Fixed-height rows would clip at large text sizes, 6. Layout broke at large system text sizes, Findings and fixes

### Community 90 - "AppLocalizations"
Cohesion: 0.33
Nodes (5): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, AppLocalizationsMs, of

### Community 91 - "session-start.sh"
Cohesion: 0.50
Nodes (3): note(), PATH, session-start.sh script

### Community 92 - "notification_setting_row.dart"
Cohesion: 0.13
Nodes (11): build, createState, didChangeAppLifecycleState, dispose, initState, NotificationSettingRow, _NotificationSettingRowState, _notifier (+3 more)

### Community 93 - "wait-for-tools.sh"
Cohesion: 0.83
Nodes (3): ready(), say(), wait-for-tools.sh script

### Community 94 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 95 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 96 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 105 - "labels.dart"
Cohesion: 0.09
Nodes (19): cancelReasonsDriver, cancelReasonsPassenger, driverRatingTagsBad, driverRatingTagsGood, hintIn, labelIn, PaymentMethodLabel, promoCodes (+11 more)

### Community 106 - "20260820140000_wallet_ledger.sql"
Cohesion: 0.22
Nodes (6): public.wallet_transactions, rides_settle_on_completion, wallet_transactions_append_only, wallet_transactions_apply_delta, wallet_transactions_one_per_ride_role_idx, wallet_transactions_user_idx

### Community 107 - "duty.dart"
Cohesion: 0.20
Nodes (8): AndroidDutyService, _channel, createDutyService, DutyService, NoDutyService, start, stop, _RecordingDuty

### Community 118 - "Android"
Cohesion: 0.22
Nodes (9): Android, Building by hand, Publishing, Releasing, Running the workflow, Status, The four secrets, What CI already guarantees (+1 more)

### Community 122 - "The one rule"
Cohesion: 0.50
Nodes (4): The one rule, Why `accept_offer` is a function, Why the helpers live in `private`, Why the wallet is append-only

## Knowledge Gaps
- **2751 isolated node(s):** `PATH`, `CoreLocation`, `UserNotifications`, `XCTest`, `Backend` (+2746 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 3046 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SessionStore` connect `SessionStore` to `rides.dart`, `build`, `session.dart`, `simulation.dart`, `router.dart`, `offers_sheet.dart`, `rate_screen.dart`, `destination_search_screen.dart`, `onboarding_screen.dart`, `main.dart`, `notifier_test.dart`, `StatelessWidget`, `text_scale_test.dart`, `driver_beacon.dart`, `marketplace_test.dart`, `profile_sync_test.dart`, `driver_beacon_test.dart`, `../l10n/app_localizations.dart`, `profile_sync.dart`, `wallet_screen.dart`, `../../models/models.dart`, `duty_presence_test.dart`, `intro_screen.dart`, `order_detail_screen.dart`, `price_sheet.dart`, `../theme.dart`, `package:flutter/material.dart`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Why does `validate()` connect `validate_data.py` to `iOS`, `reasoning_contract.py`?**
  _High betweenness centrality (0.052) - this node is a cross-community bridge._
- **Why does `Running it` connect `iOS` to `validate_data.py`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `PATH`, `CoreLocation`, `UserNotifications` to the rest of the system?**
  _2751 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_localizations.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.00392156862745098 - nodes in this community are weakly interconnected._
- **Should `app_localizations_en.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.004016064257028112 - nodes in this community are weakly interconnected._
- **Should `app_localizations_ms.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.004016064257028112 - nodes in this community are weakly interconnected._