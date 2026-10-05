# Graph Report - GET.teksi  (2026-10-05)

## Corpus Check
- 179 files · ~301,687 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 70 file(s) not represented in the graph (top: .csv 35, .xml 7, (none) 5)

## Summary
- 4006 nodes · 5332 edges · 134 communities (104 shown, 30 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `17894548`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_localizations.dart
- app_localizations_en.dart
- app_localizations_ms.dart
- models.dart
- SessionStore
- rides.dart
- intro_screen.dart
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
- Push notifications: the decision, not the design
- formats.dart
- destination_search_screen.dart
- _
- supabase_transport.dart
- onboarding_screen.dart
- main.dart
- auth_deeplink_test.dart
- _
- package:latlong2/latlong.dart
- StatelessWidget
- What You Must Do When Invoked
- DesignSystemGenerator
- screens.dart
- otp_screen.dart
- driver_beacon.dart
- rows.dart
- _
- marketplace_test.dart
- storage.dart
- notification_setting_row_test.dart
- otp_semantics_test.dart
- DutyService.kt
- UI/UX Pro Max - Design Intelligence
- build
- MainActivity
- notifier_device.dart
- wallet_screen.dart
- driver_beacon_test.dart
- profile_sync.dart
- 20260815120000_marketplace.sql
- ../../models/models.dart
- package:flutter/material.dart
- duty_presence_test.dart
- MainActivity.kt
- webpush.ts
- notification_setting_row.dart
- profile_sync_test.dart
- rows_test.dart
- Backend
- Platforms
- Pre-Delivery Checklist (canonical — the only one)
- Quick Reference
- duty.dart
- rate_screen.dart
- order_detail_screen.dart
- return
- BM25
- reasoning_contract.py
- location.dart
- safety_screen.dart
- price_sheet.dart
- ride_flow_test.dart
- GET.teksi
- manifest.json
- _select_palette_for_mode
- iOS
- _
- passenger_home_screen.dart
- graphify reference: extra exports and benchmark
- ../l10n/app_localizations.dart
- README.md
- notifier.dart
- ride_sheets_test.dart
- live-ride.sh
- GET.teksi — working agreements
- graphify reference: query, path, explain
- Findings and fixes
- AppLocalizations
- session-start.sh
- contrast_test.dart
- wait-for-tools.sh
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- Build configuration
- push_web.dart
- concurrency.sh
- extraction-spec.md
- LaunchImage.imageset/README.md
- labels.dart
- 20260820140000_wallet_ledger.sql
- push.dart
- run.sh
- chat_messages_sender_idx
- 20260821050000_guard_profile_columns.sql
- harness.sql
- Android
- 20260822170000_push_on_row_change.sql
- UI/UX accessibility audit
- dart:async
- public.push_tokens
- semantics.dart
- run-tests.sh
- package:flutter_test/flutter_test.dart
- _RadarBarState

## God Nodes (most connected - your core abstractions)
1. `SessionStore` - 90 edges
2. `RidesStore` - 79 edges
3. `_` - 41 edges
4. `_` - 40 edges
5. `DraftStore` - 30 edges
6. `_` - 26 edges
7. `search()` - 20 edges
8. `Findings and fixes` - 19 edges
9. `MainActivity` - 16 edges
10. `DesignSystemGenerator` - 15 edges

## Surprising Connections (you probably didn't know these)
- `Running it` --references--> `validate()`  [INFERRED]
  docs/RELEASING.md → .claude/skills/ui-ux-pro-max/scripts/validate_data.py
- `What arrives today, and what does not` --references--> `DutyService`  [INFERRED]
  docs/PUSH.md → android/app/src/main/kotlin/my/get/teksi/DutyService.kt
- `What was built` --references--> `PushBridge`  [INFERRED]
  docs/PUSH.md → ios/Runner/AppDelegate.swift
- `Staying awake on duty` --references--> `MainActivity`  [INFERRED]
  docs/PLATFORMS.md → android/app/src/main/kotlin/my/get/teksi/MainActivity.kt
- `_Fixed` --implements--> `PlaceSearch`  [EXTRACTED]
  test/geocoding_test.dart → lib/core/geocoding.dart

## Import Cycles
- None detected.

## Communities (134 total, 30 thin omitted)

### Community 0 - "app_localizations.dart"
Cohesion: 0.00
Nodes (511): about, accept, acceptAmount, activeTripBanner, activity, add, addACommentOptional, addAStop (+503 more)

### Community 1 - "app_localizations_en.dart"
Cohesion: 0.00
Nodes (503): about, accept, acceptAmount, activeTripBanner, activity, add, addACommentOptional, addAStop (+495 more)

### Community 2 - "app_localizations_ms.dart"
Cohesion: 0.00
Nodes (503): about, accept, acceptAmount, activeTripBanner, activity, add, addACommentOptional, addAStop (+495 more)

### Community 3 - "models.dart"
Cohesion: 0.02
Nodes (108): acceptedAt, address, amount, amountOff, AppNotification, arrivedAt, askingPrice, avatarColor (+100 more)

### Community 4 - "SessionStore"
Cohesion: 0.07
Nodes (46): DriverDocument, Role, _RouterNotifier, createState, DriverHomeScreen, _DriverHomeScreenState, _lastRatedRide, build (+38 more)

### Community 5 - "rides.dart"
Cohesion: 0.03
Nodes (61): acceptOffer, activeRideFor, addTransaction, _announceOfferChange, _announceRideChange, _applyRemote, _busSub, cancelRide (+53 more)

### Community 6 - "intro_screen.dart"
Cohesion: 0.15
Nodes (11): body, build, createState, _finish, icon, _index, IntroScreen, _IntroScreenState (+3 more)

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
Nodes (11): CoreLocation, Flutter, AppBridge, AppDelegate, LocationBridge, PushBridge, SceneDelegate, RunnerTests (+3 more)

### Community 14 - "session.dart"
Cohesion: 0.05
Nodes (36): AppUser, becomeDriver, clearShortcut, copyWith, creditWallet, darkTheme, debitWallet, driverOnline (+28 more)

### Community 15 - "ui.dart"
Cohesion: 0.05
Nodes (36): action, badge, BannerTone, body, border, build, c, child (+28 more)

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
Nodes (8): _authStepRedirect, bump, dispose, _notifier, _redirect, router, _session, trim

### Community 21 - "offers_sheet.dart"
Cohesion: 0.08
Nodes (29): Offer, PhoneScreen, _PhoneScreenState, NotificationsScreen, _NotificationsScreenState, _PlacePicker, _PlacePickerState, OrderFeedSheet (+21 more)

### Community 22 - "Push notifications: the decision, not the design"
Cohesion: 0.13
Nodes (15): APNs — iOS, and the one with no real downside, Four ways to go, HMS Push — Huawei AppGallery builds only, Push notifications: the decision, not the design, Still to do before it works, The four transports, and what each actually costs, The language question, which is not settled, UnifiedPush / self-hosted — GMS Android without Google (+7 more)

### Community 23 - "formats.dart"
Cohesion: 0.06
Nodes (30): clockTime, compactCount, currencySymbol, dateLabel, days, digits, distanceLabel, durationLabel (+22 more)

### Community 24 - "destination_search_screen.dart"
Cohesion: 0.04
Nodes (51): active, build, _choose, controller, _controllerFor, createState, DestinationSearchScreen, _DestinationSearchScreenState (+43 more)

### Community 25 - "_"
Cohesion: 0.07
Nodes (28): _, baseUrl, _categoryFor, _client, countryCodes, _defaultTimeout, display, Geocoding (+20 more)

### Community 26 - "supabase_transport.dart"
Cohesion: 0.07
Nodes (27): _authSub, _backlogFor, _channels, _client, _consumeSelfWrite, _controller, dispose, _emit (+19 more)

### Community 27 - "onboarding_screen.dart"
Cohesion: 0.07
Nodes (27): autofocus, body, build, _buildVehicleStep, _class, _classHint, _classSeats, _color (+19 more)

### Community 28 - "main.dart"
Cohesion: 0.05
Nodes (34): _askedToNotify, _askToNotify, _beacon, build, createState, dispose, _duty, _dutyService (+26 more)

### Community 29 - "auth_deeplink_test.dart"
Cohesion: 0.06
Nodes (30): draft, main, open, rides, session, deliver, main, _messageOn (+22 more)

### Community 30 - "_"
Cohesion: 0.08
Nodes (24): _, baseUrl, _client, decodePolyline, _defaultTimeout, distanceKm, durationMinutes, factor (+16 more)

### Community 31 - "package:latlong2/latlong.dart"
Cohesion: 0.08
Nodes (18): _channel, fix, lat, lng, readDeviceLocation, _hit, _kl, main (+10 more)

### Community 32 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): GetTeksiApp, _Field, _Attribution, _CarMarker, _PinMarker, ActionTile, AppBackButton, AppCard (+12 more)

### Community 33 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 34 - "DesignSystemGenerator"
Cohesion: 0.12
Nodes (3): DesignSystemGenerator, _filter_anti_patterns_for_mode(), _resolve_dial()

### Community 35 - "screens.dart"
Cohesion: 0.04
Nodes (33): app, complaintsAfter, main, states, tapVisible, accepted, appLocales, base (+25 more)

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
Nodes (13): _, Backend, _client, debugUnreachable, _e164, errors, init, isLive (+5 more)

### Community 40 - "marketplace_test.dart"
Cohesion: 0.11
Nodes (14): askingPrice, buildOffer, buildRide, _car, _dropoff, main, matchedAsking, now (+6 more)

### Community 41 - "storage.dart"
Cohesion: 0.10
Nodes (16): _alphabet, body, bytes, clearAll, hex, init, _instance, _prefix (+8 more)

### Community 42 - "notification_setting_row_test.dart"
Cohesion: 0.18
Nodes (9): calls, canOpenSettings, grantsOnRequest, main, openSettings, pump, requestPermission, show (+1 more)

### Community 43 - "otp_semantics_test.dart"
Cohesion: 0.12
Nodes (11): _kl, main, pumpMap, found, _hasTextField, _labels, main, out (+3 more)

### Community 45 - "UI/UX Pro Max - Design Intelligence"
Cohesion: 0.11
Nodes (17): Before Delivering App UI, Example Workflow, If a search returns 0 results, Output Formats, Query Contract, Rule Categories by Priority, Running the search tool, Step 1: Analyze User Requirements (+9 more)

### Community 46 - "build"
Cohesion: 0.12
Nodes (9): _finish, build, _buildIntroStep, _finish, build, build, build, build (+1 more)

### Community 48 - "notifier_device.dart"
Cohesion: 0.12
Nodes (12): _appChannel, buildNotifier, _channelDescription, _channelId, _channelName, _ensureReady, openSettings, _plugin (+4 more)

### Community 49 - "wallet_screen.dart"
Cohesion: 0.12
Nodes (15): Txn, build, _card, _cardTail, createState, first, initState, _load (+7 more)

### Community 50 - "driver_beacon_test.dart"
Cohesion: 0.11
Nodes (15): beaconWith, calls, current, delay, fixes, _jitter, main, _north (+7 more)

### Community 51 - "profile_sync.dart"
Cohesion: 0.12
Nodes (13): _columnsFor, dispose, _flush, isRunning, _listening, _onChanged, _sameAsSent, _sent (+5 more)

### Community 52 - "20260815120000_marketplace.sql"
Cohesion: 0.12
Nodes (7): offers_guard_write, on_auth_user_created, profiles_touch, public.profiles, public.rides, rides_guard_update, rides_touch

### Community 53 - "../../models/models.dart"
Cohesion: 0.10
Nodes (18): avatarColors, demoCardName, demoCardTail, driverNames, hash, passengerNames, pickAvatarColor, pickupNotes (+10 more)

### Community 54 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (33): Ride, ActiveRideSheet, build, _confirmCancel, driverAt, ride, createState, driverAt (+25 more)

### Community 55 - "duty_presence_test.dart"
Cohesion: 0.13
Nodes (12): body, calls, _car, goOnDuty, grant, main, presenceWith, service (+4 more)

### Community 57 - "webpush.ts"
Cohesion: 0.07
Nodes (37): RFC-8188, RFC-8291, RFC-8292, handlePush(), json(), PushRow, Call, Alert (+29 more)

### Community 58 - "notification_setting_row.dart"
Cohesion: 0.13
Nodes (11): build, createState, didChangeAppLifecycleState, dispose, initState, NotificationSettingRow, _NotificationSettingRowState, _notifier (+3 more)

### Community 59 - "profile_sync_test.dart"
Cohesion: 0.08
Nodes (21): allPlaces, cityCenter, cityName, fuzzySearch, intercityPlaces, _p, places, q (+13 more)

### Community 60 - "rows_test.dart"
Cohesion: 0.14
Nodes (12): RideStatus, _asReadBack, _klcc, main, _midValley, now, _offer, _place (+4 more)

### Community 61 - "Backend"
Cohesion: 0.14
Nodes (14): Applying it to a project, Backend, How it connects to the app, Known gaps, Pointing the app at it, Running the tests, Sign-in, Testing the deployment rather than the schema (+6 more)

### Community 62 - "Platforms"
Cohesion: 0.15
Nodes (12): Android, Device location, iOS, Map tiles in Huawei's home market, Notifications, Per-target notes, Platforms, The map is OpenStreetMap (+4 more)

### Community 63 - "Pre-Delivery Checklist (canonical — the only one)"
Cohesion: 0.15
Nodes (12): Accessibility, Common Rules for Professional UI + Pre-Delivery Checklist, Icons & Visual Elements, Interaction, Interaction (App), Layout, Layout & Spacing, Light/Dark Mode (+4 more)

### Community 64 - "Quick Reference"
Cohesion: 0.15
Nodes (12): 10. Charts & Data (LOW), 1. Accessibility (CRITICAL), 2. Touch & Interaction (CRITICAL), 3. Performance (HIGH), 4. Style Selection (HIGH), 5. Layout & Responsive (HIGH), 6. Typography & Color (MEDIUM), 7. Animation (MEDIUM) (+4 more)

### Community 65 - "duty.dart"
Cohesion: 0.18
Nodes (8): AndroidDutyService, _channel, createDutyService, DutyService, NoDutyService, start, stop, _RecordingDuty

### Community 66 - "rate_screen.dart"
Cohesion: 0.17
Nodes (12): build, _comment, createState, dispose, _leave, RateScreen, _RateScreenState, rideId (+4 more)

### Community 67 - "order_detail_screen.dart"
Cohesion: 0.12
Nodes (15): build, _counter, createState, _Detail, icon, label, _Meta, onTap (+7 more)

### Community 68 - "return"
Cohesion: 0.25
Nodes (4): formatted, main, _monthYearIn, pumpWidget

### Community 70 - "reasoning_contract.py"
Cohesion: 0.22
Nodes (5): apply_decision_rules(), _object_without_duplicates(), parse_decision_rules(), _validate_action(), _check_reasoning_contract()

### Community 71 - "location.dart"
Cohesion: 0.22
Nodes (6): current, DeviceLocationService, LocationService, SeededLocationService, timeout, _ScriptedLocation

### Community 72 - "safety_screen.dart"
Cohesion: 0.11
Nodes (15): _channel, readPushAddress, token, _addContact, build, createState, _emergencyNumber, initState (+7 more)

### Community 73 - "price_sheet.dart"
Cohesion: 0.12
Nodes (15): _chooseClass, _chooseOptions, _choosePayment, _editComment, icon, label, _MetaButton, onTap (+7 more)

### Community 74 - "ride_flow_test.dart"
Cohesion: 0.12
Nodes (10): GoRouterConfig, app, config, here, main, settle, start, app (+2 more)

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

### Community 79 - "_"
Cohesion: 0.18
Nodes (11): _, AppConfig, hasBackend, hasGeocoding, hasRouting, nominatimUrl, osrmUrl, supabaseKey (+3 more)

### Community 80 - "passenger_home_screen.dart"
Cohesion: 0.14
Nodes (10): createState, icon, initState, label, _lastRatedRide, onTap, PassengerHomeScreen, _PassengerHomeScreenState (+2 more)

### Community 81 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 82 - "../l10n/app_localizations.dart"
Cohesion: 0.08
Nodes (20): build, _continue, _controller, createState, _digits, dispose, _error, _sending (+12 more)

### Community 83 - "README.md"
Cohesion: 0.31
Nodes (3): `graphify/` — codebase knowledge graph, Project skills, `ui-ux-pro-max/` — UI/UX design intelligence

### Community 84 - "notifier.dart"
Cohesion: 0.17
Nodes (11): createNotifier, _DeviceNotifier, NotificationPermission, Notifier, openSettings, readyAfterInitialize, requestPermission, show (+3 more)

### Community 85 - "ride_sheets_test.dart"
Cohesion: 0.05
Nodes (25): app, goesEmpty, layout, main, app, main, offersSheet, openAndLayout (+17 more)

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
Cohesion: 0.10
Nodes (20): 10. Two auth steps could be reached without a phone number, 11. What a screen reader is told was not what was written, 12. The error states had never been drawn, 13. The empty states had never been drawn either, 14. Nothing ever walked a journey, 15. The sheets that only exist part-way through a ride, 16. What two shared widgets said, which is what twelve files said, 17. The sheets that only exist after a tap (+12 more)

### Community 90 - "AppLocalizations"
Cohesion: 0.33
Nodes (5): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, AppLocalizationsMs, of

### Community 91 - "session-start.sh"
Cohesion: 0.50
Nodes (3): note(), PATH, session-start.sh script

### Community 92 - "contrast_test.dart"
Cohesion: 0.12
Nodes (13): _channel, contrast, hi, la, lb, lo, _luminance, main (+5 more)

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

### Community 100 - "push_web.dart"
Cohesion: 0.12
Nodes (13): auth, _decodeVapidKey, endpoint, json, keys, p256dh, permission, readPushAddress (+5 more)

### Community 105 - "labels.dart"
Cohesion: 0.09
Nodes (19): cancelReasonsDriver, cancelReasonsPassenger, driverRatingTagsBad, driverRatingTagsGood, hintIn, labelIn, PaymentMethodLabel, promoCodes (+11 more)

### Community 106 - "20260820140000_wallet_ledger.sql"
Cohesion: 0.22
Nodes (6): public.wallet_transactions, rides_settle_on_completion, wallet_transactions_append_only, wallet_transactions_apply_delta, wallet_transactions_one_per_ride_role_idx, wallet_transactions_user_idx

### Community 107 - "push.dart"
Cohesion: 0.14
Nodes (9): address, auth, isDeliverable, p256dh, platform, PushAddress, registerForPush, token (+1 more)

### Community 118 - "Android"
Cohesion: 0.22
Nodes (9): Android, Building by hand, Publishing, Releasing, Running the workflow, Status, The four secrets, What CI already guarantees (+1 more)

### Community 122 - "20260822170000_push_on_row_change.sql"
Cohesion: 0.29
Nodes (3): offers_push_passenger, private.push_on_offer(), rides_push_status

### Community 125 - "UI/UX accessibility audit"
Cohesion: 0.29
Nodes (6): Not addressed, Shipping, which is not a UI question, UI/UX accessibility audit, Verification, What "all 23 screens" was worth when findings 6 and 7 were written, What the skill was and wasn't used for

### Community 126 - "dart:async"
Cohesion: 0.25
Nodes (4): done, finish, geolocation, readDeviceLocation

### Community 128 - "public.push_tokens"
Cohesion: 0.60
Nodes (3): public.push_tokens, push_tokens_touch, push_tokens_user_idx

### Community 129 - "semantics.dart"
Cohesion: 0.25
Nodes (7): announcesSomething, controls, describeNode, flattenSemantics, kinds, out, walk

### Community 138 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (27): en, json, _keysOf, main, ms, blockOf, code, main (+19 more)

## Knowledge Gaps
- **2929 isolated node(s):** `PATH`, `CoreLocation`, `UserNotifications`, `XCTest`, `Backend` (+2924 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 3240 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **30 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `validate()` connect `validate_data.py` to `iOS`, `reasoning_contract.py`?**
  _High betweenness centrality (0.076) - this node is a cross-community bridge._
- **Why does `iOS` connect `iOS` to `Android`?**
  _High betweenness centrality (0.075) - this node is a cross-community bridge._
- **Why does `Running it` connect `iOS` to `validate_data.py`?**
  _High betweenness centrality (0.075) - this node is a cross-community bridge._
- **What connects `PATH`, `CoreLocation`, `UserNotifications` to the rest of the system?**
  _2929 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_localizations.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.003875968992248062 - nodes in this community are weakly interconnected._
- **Should `app_localizations_en.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.003968253968253968 - nodes in this community are weakly interconnected._
- **Should `app_localizations_ms.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.003968253968253968 - nodes in this community are weakly interconnected._