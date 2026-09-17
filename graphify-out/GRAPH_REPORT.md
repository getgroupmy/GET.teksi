# Graph Report - GET.teksi  (2026-08-15)

## Corpus Check
- 87 files · ~181,493 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1465 nodes · 2280 edges · 81 communities (69 shown, 12 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `67f4c0c5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- models.dart
- rides.dart
- onboarding_screen.dart
- geo.dart
- session.dart
- simulation.dart
- ui.dart
- draft.dart
- map_view.dart
- pricing.dart
- router.dart
- formats.dart
- theme.dart
- order_detail_screen.dart
- bus.dart
- marketplace_test.dart
- destination_search_screen.dart
- otp_screen.dart
- build
- GET.teksi
- offers_sheet.dart
- AppDelegate
- tracking_sheet.dart
- storage.dart
- State
- ../../models/models.dart
- DraftStore
- fixtures.dart
- SessionStore
- StatelessWidget
- price_sheet.dart
- places.dart
- package:flutter/material.dart
- passenger_home_screen.dart
- order_feed_sheet.dart
- core.py
- ../theme.dart
- validate_data.py
- chat_screen.dart
- rate_screen.dart
- contrast_test.dart
- manifest.json
- RidesStore
- What You Must Do When Invoked
- driver_home_screen.dart
- package:latlong2/latlong.dart
- places_screen.dart
- UI/UX Pro Max - Design Intelligence
- MainActivity.kt
- LaunchImage.imageset/README.md
- PaymentMethod
- RideOption
- ServiceType
- VehicleClass
- @example
- persist_design_system
- design_system.py
- Pre-Delivery Checklist (canonical — the only one)
- Quick Reference
- safety_screen.dart
- DesignSystemGenerator
- parse_decision_rules
- _select_palette_for_mode
- .generate
- graphify reference: extra exports and benchmark
- graphify reference: query, path, explain
- _resolve_color_mode
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- Route /p
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- _RadarBarState
- extraction-spec.md
- _CarPainter
- MapView

## God Nodes (most connected - your core abstractions)
1. `SessionStore` - 78 edges
2. `RidesStore` - 72 edges
3. `DraftStore` - 28 edges
4. `search()` - 20 edges
5. `DesignSystemGenerator` - 15 edges
6. `build` - 14 edges
7. `_normalize()` - 12 edges
8. `search_stack()` - 12 edges
9. `validate()` - 12 edges
10. `What You Must Do When Invoked` - 12 edges

## Surprising Connections (you probably didn't know these)
- `_send` --references--> `RidesStore`  [EXTRACTED]
  lib/screens/shared/chat_screen.dart → lib/state/rides.dart
- `_confirmSignOut` --references--> `RidesStore`  [EXTRACTED]
  lib/screens/shared/menu_screen.dart → lib/state/rides.dart
- `initState` --references--> `RidesStore`  [EXTRACTED]
  lib/screens/shared/notifications_screen.dart → lib/state/rides.dart
- `build` --references--> `RidesStore`  [EXTRACTED]
  lib/screens/shared/notifications_screen.dart → lib/state/rides.dart
- `_apply` --references--> `DraftStore`  [EXTRACTED]
  lib/screens/shared/promos_screen.dart → lib/state/draft.dart

## Import Cycles
- None detected.

## Communities (81 total, 12 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.02
Nodes (108): double?, acceptedAt, address, amount, amountOff, AppNotification, arrivedAt, askingPrice (+100 more)

### Community 1 - "rides.dart"
Cohesion: 0.03
Nodes (57): ../core/bus.dart, int get, acceptOffer, activeRideFor, addTransaction, _applyRemote, _busSub, cancelRide (+49 more)

### Community 2 - "onboarding_screen.dart"
Cohesion: 0.05
Nodes (40): IconData, body, build, createState, _finish, icon, _index, IntroScreen (+32 more)

### Community 3 - "geo.dart"
Cohesion: 0.05
Nodes (41): amplitude, avgSpeedKmh, bearing, bearingBetween, clamped, coord, dir, dist (+33 more)

### Community 4 - "session.dart"
Cohesion: 0.05
Nodes (40): AppUser? get, LatLng get, AppUser, becomeDriver, clearShortcut, copyWith, creditWallet, current (+32 more)

### Community 5 - "simulation.dart"
Cohesion: 0.05
Nodes (39): _active, advance, _ageBotOrders, _between, _bidLog, _botById, _botsBidOn, _BotTrip (+31 more)

### Community 6 - "ui.dart"
Cohesion: 0.05
Nodes (37): AnimationController, EdgeInsets?, action, badge, BannerTone, body, border, build (+29 more)

### Community 7 - "draft.dart"
Cohesion: 0.05
Nodes (37): Place, clear, clearRoute, comment, distanceKm, DraftField, DraftStep, dropoff (+29 more)

### Community 8 - "map_view.dart"
Cohesion: 0.06
Nodes (30): approach, bearing, bottomPadding, build, _CarMarker, center, _controller, coord (+22 more)

### Community 9 - "pricing.dart"
Cohesion: 0.06
Nodes (33): 1, adjusted, base, commissionOn, commissionRate, demandFactor, driverNet, hint (+25 more)

### Community 10 - "router.dart"
Cohesion: 0.06
Nodes (34): ChangeNotifier, GoRouter, bump, dispose, GoRouterConfig, _notifier, _redirect, router (+26 more)

### Community 11 - "formats.dart"
Cohesion: 0.06
Nodes (32): clockTime, compactCount, currencySymbol, dateLabel, days, digits, distanceLabel, durationLabel (+24 more)

### Community 12 - "theme.dart"
Cohesion: 0.06
Nodes (31): AppColors get, BuildContext, Color?, accent, AppColors, AppColorsX, bg, body (+23 more)

### Community 13 - "order_detail_screen.dart"
Cohesion: 0.12
Nodes (16): int?, build, _counter, createState, _Detail, icon, label, _Meta (+8 more)

### Community 14 - "bus.dart"
Cohesion: 0.09
Nodes (27): bearing, bus, BusEvent, by, ChatSent, _controller, coord, dispose (+19 more)

### Community 15 - "marketplace_test.dart"
Cohesion: 0.08
Nodes (24): RideStatus, package:flutter_test/flutter_test.dart, package:get_teksi/core/formats.dart, package:get_teksi/core/storage.dart, package:get_teksi/models/models.dart, package:get_teksi/services/pricing.dart, package:get_teksi/state/rides.dart, package:get_teksi/state/session.dart (+16 more)

### Community 16 - "destination_search_screen.dart"
Cohesion: 0.09
Nodes (22): FocusNode, active, controller, _controllerFor, createState, DestinationSearchScreen, _DestinationSearchScreenState, dispose (+14 more)

### Community 17 - "otp_screen.dart"
Cohesion: 0.10
Nodes (19): dart:async, _autofill, build, _code, _controller, createState, dispose, _error (+11 more)

### Community 18 - "build"
Cohesion: 0.15
Nodes (16): build, _finish, build, build, build, build, Route /d, Route /d/earnings (+8 more)

### Community 19 - "GET.teksi"
Cohesion: 0.05
Nodes (33): `graphify/` — codebase knowledge graph, Project skills, `ui-ux-pro-max/` — UI/UX design intelligence, Android, iOS, Map tiles in Huawei's home market, Per-target notes, Platforms (+25 more)

### Community 20 - "offers_sheet.dart"
Cohesion: 0.10
Nodes (21): Offer, askingPrice, build, _confirmCancel, createState, dispose, _elapsed, initState (+13 more)

### Community 21 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 22 - "tracking_sheet.dart"
Cohesion: 0.20
Nodes (9): Ride, _confirmCancel, _copy, ride, _share, _shareText, _snack, TrackingSheet (+1 more)

### Community 23 - "storage.dart"
Cohesion: 0.11
Nodes (18): dart:convert, _alphabet, body, clearAll, init, _instance, _prefix, _prefs (+10 more)

### Community 24 - "State"
Cohesion: 0.16
Nodes (18): OtpScreen, _OtpScreenState, PhoneScreen, _PhoneScreenState, ProfileSetupScreen, _ProfileSetupScreenState, HistoryScreen, _HistoryScreenState (+10 more)

### Community 25 - "../../models/models.dart"
Cohesion: 0.09
Nodes (29): ../core/formats.dart, Role, Txn, build, createState, _HistoryCard, ride, _role (+21 more)

### Community 26 - "DraftStore"
Cohesion: 0.33
Nodes (6): build, _choose, _focusActiveField, initState, _seedPickup, DraftStore

### Community 27 - "fixtures.dart"
Cohesion: 0.12
Nodes (16): avatarColors, cancelReasonsDriver, cancelReasonsPassenger, driverNames, driverRatingTagsBad, driverRatingTagsGood, hash, passengerNames (+8 more)

### Community 28 - "SessionStore"
Cohesion: 0.13
Nodes (18): build, createState, dispose, GetTeksiApp, init, initState, main, _Root (+10 more)

### Community 29 - "StatelessWidget"
Cohesion: 0.12
Nodes (16): _Field, ActionTile, AppCard, AppChip, AppRow, Avatar, EmptyState, FabButton (+8 more)

### Community 30 - "price_sheet.dart"
Cohesion: 0.07
Nodes (28): build, icon, IdleSheet, label, onTap, _serviceIcons, _Shortcut, sub (+20 more)

### Community 31 - "places.dart"
Cohesion: 0.13
Nodes (14): allPlaces, cityCenter, cityName, fuzzySearch, intercityPlaces, _p, places, q (+6 more)

### Community 32 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (17): DriverDocument, build, createState, EarningsScreen, _EarningsScreenState, _Period, document, _DocumentRow (+9 more)

### Community 33 - "passenger_home_screen.dart"
Cohesion: 0.15
Nodes (13): createState, icon, initState, label, _lastRatedRide, onTap, PassengerHomeScreen, _PassengerHomeScreenState (+5 more)

### Community 34 - "order_feed_sheet.dart"
Cohesion: 0.14
Nodes (13): createState, driverAt, _maxPickupKm, _minFare, onTap, _OrderCard, pending, pickupEta (+5 more)

### Community 35 - "core.py"
Cohesion: 0.06
Nodes (60): BM25, _contains_phrase(), detect_domain(), _domain_keywords(), _exact_match_diagnostic(), _exact_row_identity(), _exact_stack_identifier(), _file_signature() (+52 more)

### Community 36 - "../theme.dart"
Cohesion: 0.08
Nodes (25): bool get, ../../data/fixtures.dart, build, _continue, _controller, createState, _digits, dispose (+17 more)

### Community 37 - "validate_data.py"
Cohesion: 0.10
Nodes (41): _catalog_date(), _check_app_interface_contract(), _check_catalog_contract(), _check_catalog_summary(), _check_chart_contract(), _check_color_contract(), _check_core_data_contract(), _check_file() (+33 more)

### Community 38 - "chat_screen.dart"
Cohesion: 0.22
Nodes (9): build, ChatScreen, _ChatScreenState, _controller, createState, dispose, rideId, _scroll (+1 more)

### Community 39 - "rate_screen.dart"
Cohesion: 0.17
Nodes (12): build, _comment, createState, dispose, _leave, RateScreen, _RateScreenState, rideId (+4 more)

### Community 40 - "contrast_test.dart"
Cohesion: 0.18
Nodes (10): package:get_teksi/theme.dart, _channel, contrast, hi, la, lb, lo, _luminance (+2 more)

### Community 41 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 42 - "RidesStore"
Cohesion: 0.13
Nodes (18): LatLng, bold, build, label, _Line, muted, RideDetailScreen, rideId (+10 more)

### Community 43 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 44 - "driver_home_screen.dart"
Cohesion: 0.22
Nodes (9): ../../core/geo.dart, createState, DriverHomeScreen, _DriverHomeScreenState, _lastRatedRide, String?, ../../widgets/driver/active_ride_sheet.dart, ../../widgets/driver/order_feed_sheet.dart (+1 more)

### Community 45 - "package:latlong2/latlong.dart"
Cohesion: 0.25
Nodes (7): dart:math, package:get_teksi/core/geo.dart, package:latlong2/latlong.dart, _klcc, main, _midValley, _penang

### Community 46 - "places_screen.dart"
Cohesion: 0.22
Nodes (8): ../data/places.dart, createState, onPick, _pick, PlacesScreen, _query, ../../state/draft.dart, ValueChanged

### Community 47 - "UI/UX Pro Max - Design Intelligence"
Cohesion: 0.11
Nodes (17): Before Delivering App UI, Example Workflow, If a search returns 0 results, Output Formats, Query Contract, Rule Categories by Priority, Running the search tool, Step 1: Analyze User Requirements (+9 more)

### Community 59 - "persist_design_system"
Cohesion: 0.14
Nodes (15): _detect_page_type(), format_master_md(), format_page_override_md(), _generate_intelligent_overrides(), persist_design_system(), Format design system as MASTER.md with hierarchical override logic., Format a page-specific override file with intelligent AI-generated content., Generate intelligent overrides based on page type using layered search. Uses… (+7 more)

### Community 60 - "design_system.py"
Cohesion: 0.20
Nodes (13): ansi_ljust(), format_ascii_box(), format_markdown(), generate_design_system(), hex_to_ansi(), Convert hex color to ANSI True Color swatch (██) with fallback., Like str.ljust but accounts for zero-width ANSI escape sequences., Create a Unicode section separator: ├─── NAME ───...┤ (+5 more)

### Community 61 - "Pre-Delivery Checklist (canonical — the only one)"
Cohesion: 0.15
Nodes (12): Accessibility, Common Rules for Professional UI + Pre-Delivery Checklist, Icons & Visual Elements, Interaction, Interaction (App), Layout, Layout & Spacing, Light/Dark Mode (+4 more)

### Community 62 - "Quick Reference"
Cohesion: 0.15
Nodes (12): 10. Charts & Data (LOW), 1. Accessibility (CRITICAL), 2. Touch & Interaction (CRITICAL), 3. Performance (HIGH), 4. Style Selection (HIGH), 5. Layout & Responsive (HIGH), 6. Typography & Color (MEDIUM), 7. Animation (MEDIUM) (+4 more)

### Community 63 - "safety_screen.dart"
Cohesion: 0.17
Nodes (11): ../../core/storage.dart, _addContact, build, createState, _emergencyNumber, initState, _persist, _report (+3 more)

### Community 64 - "DesignSystemGenerator"
Cohesion: 0.27
Nodes (4): DesignSystemGenerator, Generates design system recommendations from aggregated searches., Load reasoning rules from CSV., Select best matching result based on priority keywords.

### Community 65 - "parse_decision_rules"
Cohesion: 0.24
Nodes (8): Find matching reasoning rule for a category., Apply reasoning rules to search results., apply_decision_rules(), _object_without_duplicates(), parse_decision_rules(), Return deterministic mutations and an audit trail; never execute data., Parse the canonical condition -> action-array representation., _validate_action()

### Community 66 - "_select_palette_for_mode"
Cohesion: 0.22
Nodes (10): _contrast_ratio(), _derive_dark_palette(), _palette_is_dark(), WCAG relative luminance of a #RRGGBB string, or None if unparseable., True when a colors.csv row's Background is a dark surface., WCAG contrast ratio for two hex colors, or None if either is invalid., Keep product brand tokens while deriving accessible dark surfaces., Pick the highest-ranked palette matching the resolved mode. Only the dark case… (+2 more)

### Community 67 - ".generate"
Cohesion: 0.20
Nodes (7): _filter_anti_patterns_for_mode(), Drop "avoid dark mode" advice once dark mode is the resolved answer., Execute searches across multiple domains., Extract results list from search result dict., Generate complete design system recommendation. variance/motion/density are…, Bucket a 1-10 dial value into its tier config. Returns None if value is None., _resolve_dial()

### Community 68 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 69 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 70 - "_resolve_color_mode"
Cohesion: 0.33
Nodes (6): _query_wants_dark(), True when a styles.csv row describes itself as dark-first., True when the query explicitly asks for a dark theme., Resolve the mode the rest of the output has to agree with., _resolve_color_mode(), _style_is_dark_primary()

### Community 71 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 72 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 73 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 74 - "Route /p"
Cohesion: 0.50
Nodes (4): _finish, _buildIntroStep, build, Route /p

### Community 77 - "_RadarBarState"
Cohesion: 0.67
Nodes (3): RadarBar, _RadarBarState, SingleTickerProviderStateMixin

## Knowledge Gaps
- **856 isolated node(s):** `XCTest`, `ride`, `rideId`, `by`, `reason` (+851 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SessionStore` connect `SessionStore` to `rides.dart`, `onboarding_screen.dart`, `session.dart`, `simulation.dart`, `router.dart`, `order_detail_screen.dart`, `marketplace_test.dart`, `destination_search_screen.dart`, `build`, `State`, `../../models/models.dart`, `DraftStore`, `price_sheet.dart`, `package:flutter/material.dart`, `passenger_home_screen.dart`, `order_feed_sheet.dart`, `../theme.dart`, `chat_screen.dart`, `rate_screen.dart`, `RidesStore`, `driver_home_screen.dart`, `places_screen.dart`, `Route /p`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Why does `RidesStore` connect `RidesStore` to `rides.dart`, `simulation.dart`, `router.dart`, `order_detail_screen.dart`, `marketplace_test.dart`, `destination_search_screen.dart`, `build`, `offers_sheet.dart`, `tracking_sheet.dart`, `State`, `../../models/models.dart`, `DraftStore`, `SessionStore`, `price_sheet.dart`, `package:flutter/material.dart`, `passenger_home_screen.dart`, `order_feed_sheet.dart`, `chat_screen.dart`, `rate_screen.dart`, `driver_home_screen.dart`, `safety_screen.dart`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **Why does `Ride` connect `tracking_sheet.dart` to `models.dart`, `order_feed_sheet.dart`, `RidesStore`, `bus.dart`, `offers_sheet.dart`, `../../models/models.dart`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **What connects `XCTest`, `ride`, `rideId` to the rest of the system?**
  _856 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.01834862385321101 - nodes in this community are weakly interconnected._
- **Should `rides.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.034482758620689655 - nodes in this community are weakly interconnected._
- **Should `onboarding_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04994192799070848 - nodes in this community are weakly interconnected._