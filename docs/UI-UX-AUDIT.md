# UI/UX accessibility audit

Run against the vendored **ui-ux-pro-max** skill (`.claude/skills/ui-ux-pro-max/`),
using its `references/pro-rules.md` pre-delivery checklist for native/mobile app
UI plus targeted `--domain ux` and `--stack flutter` queries.

Every finding below was measured or observed, not assumed. The contrast numbers
are WCAG relative-luminance ratios computed from the actual token values, and
they are now locked in by `test/contrast_test.dart` so the palette cannot
silently regress.

Findings 1–7 came from that skill pass. **Findings 8–14 did not** — they came
from rendering the built app in a browser and from reading Chromium's own
accessibility tree, and each one was invisible to a gate that reported
covering the screen it was on. What they have in common is set out after
finding 14.

---

## What the skill was and wasn't used for

The skill's `--design-system` mode returned a **landing-page** shape for a
"ride hailing" query — `Hero → product video → feature breakdown → CTA` — and a
generic slate/blue palette. That is the right answer for a marketing site and
the wrong one for an in-app mobile UI, and adopting its colours would have
discarded the product's own brand.

Per the skill's own query contract ("verify the returned domain/category and fit
for the user's product and platform before applying it… retry once with a
narrower rewrite"), the design-system output was **not** applied. The targeted
domain and stack queries were, and those are where the real findings came from.

---

## Findings and fixes

### 1. Colour contrast — the light theme was largely unusable

Measured against all four surfaces in each theme. Text roles need 4.5:1;
non-text indicators need 3:1.

| Token | Theme | Was | Now |
|---|---|---|---|
| `textMute` | dark | 2.8:1 ❌ | 5.1:1 ✅ |
| `danger` | dark | 4.4:1 ❌ | 4.6:1 ✅ |
| `textMute` | light | 2.7:1 ❌ | 4.8:1 ✅ |
| `danger` | light | 3.8:1 ❌ | 5.4:1 ✅ |
| `warn` | light | 3.2:1 ❌ | 4.8:1 ✅ |
| `ok` | light | 2.9:1 ❌ | 4.9:1 ✅ |
| `info` | light | 3.9:1 ❌ | 4.9:1 ✅ |
| `brand` as text | light | **1.7:1** ❌ | replaced, see below |

The worst of these was the brand lime used as a foreground colour. At 1.7:1 on
white it was effectively invisible in light mode — and it was being used for
icons, the star in every rating, the fare verdict text, the focus ring on the
route fields, selected-state borders, the slider track, and the pickup dot.

**Fix:** split the single `brand` token into two semantic roles.

- `brand` — the vivid fill. Buttons, the route polyline, map pins, the wallet
  card gradient, chat bubbles. Unchanged, and correct: `brandInk` on `brand`
  measures 14.4:1 in dark and 9.3:1 in light.
- `accent` — brand identity drawn *as text or an icon on a surface*. Identical
  to `brand` in dark mode; a darker green (`#5A7200`) in light mode.

52 usages were reclassified. Fills stayed on `brand`; foreground and
state-indicator usages moved to `accent`.

### 2. Touch targets below the platform minimum

The checklist requires ≥44pt on iOS and ≥48dp on Android, expanding the hit
area when the visual element is smaller.

| Control | Was | Now |
|---|---|---|
| Service/quick-phrase/rating chips | ~33dp tall | 52dp (pill visual unchanged, hit box padded out) |
| Map FABs (menu, notifications) | 44dp | 48dp |
| Offer decline button | 38dp | 48dp |
| Offer accept button | 40dp | 48dp |
| Driver bid stepper (−/+) | 46dp | 48dp |
| Ride action tiles (chat/call/share/safety) | ~44dp | 56dp |

Chips also gained `HitTestBehavior.opaque` so the padded area is genuinely
tappable rather than just visually larger.

### 3. Reduced motion was not respected

`RadarBar` — shown while waiting for driver bids and while a driver's offer is
pending — looped a sweeping gradient indefinitely with no escape. The skill
rates ignoring `prefers-reduced-motion` as **High** severity.

**Fix:** under `MediaQuery.disableAnimationsOf(context)` the controller stops
and the bar renders as a static accent-tinted rule. The surrounding copy
("Looking for drivers…", "Waiting for … to reply") already carries the meaning,
so nothing is lost.

### 4. Colour was the only indicator of driver duty state

The earnings pill on the driver map showed a green or grey dot and nothing
else — the sole signal of whether you were online. Fails "color is not the only
indicator".

**Fix:** the dot is now paired with an explicit `On`/`Off` label, and the whole
pill carries a semantic label announcing earnings and duty state together.

### 5. Fixed-height rows would clip at large text sizes

The service-chip strip and the chat quick-phrase strip were hard-coded to 36dp
and 40dp. They clipped once targets grew, and would have clipped anyway under
Dynamic Type at large system text sizes. Both now size to the taller targets.

---

### 6. Layout broke at large system text sizes

Addressed after the original audit, which had recorded this as not done: "the
app has not been walked end to end at maximum system text size". It is now
walked on every build, by `test/text_scale_test.dart`, which lays out all 23
screens at 1.0x and at 2.0x and fails on any overflow.

The app does not clamp the text scale — `MaterialApp.router` passes the
platform's value through — so 2.0x is a setting a real user can choose, and
Android's accessibility slider reaches it. iOS's larger accessibility sizes go
further still, so 2.0x is a floor rather than a ceiling.

Nine screens overflowed at 2.0x, and **VehicleScreen overflowed by 27 pixels
at the normal text size** — a layout bug in the shipping app, not an
accessibility one, and not visible in release, where an overflow clips
silently instead of painting the debug stripe.

What was wrong fell into four shapes:

- **Label-and-value rows with neither side flexed** — the fare breakdown in
  RideDetail, the vehicle category, the market price on OrderDetail, the fare
  on RateScreen. Both sides are `Flexible` now, so the text wraps instead of
  being clipped.
- **A row of three independent facts** (distance, duration, reference) that
  cannot fit on one line at any phone width once the text is large. Now a
  `Wrap`.
- **Columns taller than the viewport**, where a `Spacer` silently collapses to
  zero and everything below it is cut off: PhoneScreen's terms and Continue
  button, IntroScreen's slide body. Both scroll now, but only once they have
  to — `ConstrainedBox` plus `IntrinsicHeight` keeps the `Spacer` working
  while there is room.
- **Pills in a top bar**, where the fix had a trap in it. Wrapping the
  DriverHome earnings pill in `Flexible` *introduced* a 30-pixel overflow at
  the normal text size, because a `Flexible` between two `Spacer`s is a third
  flex child competing for the same free space and was handed a third of it.
  One `Expanded` holding a `Center` does what the two `Spacer`s were for.

One deliberate exception: the map pin's label chip caps its scale at 1.3x. It
sits in a fixed-size marker box anchored to a coordinate, so unbounded growth
either clips the name or walks the pin off the place it marks — and the same
pickup and dropoff names are in the sheet below at the full system size,
through `RouteStops`.

#### And then again, in Malay

The walk above was real, and it was also only half the app. `wrap` set
`supportedLocales` but never a `locale`, so the harness fell back to English
and all 23 screens were laid out twice in one of the two languages the app
ships. Nothing said so; the gate reported 23 screens and meant it.

Malay is not a rounding error on an English layout. Across the 498 strings the
two locales share it runs **17% longer overall** and is longer in **70% of
them**, and the worst growth is in the short strings with the least room:

| English | Malay | Growth |
|---|---|---|
| "RM5 off any trip" | "Potongan RM5 untuk mana-mana perjalanan" | **+144%** |
| "Today" | "Hari ini" | +60% |

Two more overflows, both of them live in the shipping app, and both invisible
in English at the same text size:

- **RideDetailScreen, 59 pixels.** The fare was given `Expanded` and a
  `scaleDown` `FittedBox` in the pass above; the date and time beside it were
  left bare. "Today · 14:32" fits at 2.0x. "Hari ini · 14:32" does not.
- **HistoryScreen, 26 pixels.** The rating line — an icon, a gap and a
  `Text` — had nothing flexed in it at all. "You rated 5" becomes "Anda
  menilai 5".

Both are the first shape in the list above, the one this finding had already
fixed nine instances of. English simply never pushed these two over the line.

The gate now runs locale × scale, so 92 screen layouts rather than 46. It was
scoped to layout deliberately: the semantics gate asserts that labels are
*present*, and they are present in Malay by construction — the same
`l.something` call sites, and `app_ms.arb` complete at 498 of 498 keys — so a
locale axis there would cost runtime and cover nothing new.

### 7. Controls that announced nothing to a screen reader

The audit had recorded only that labels "were added to the icon-only
controls". `test/semantics_test.dart` now checks every screen on every build,
for the two failures that are mechanical enough to gate:

- a control a screen reader would stop on and have nothing to read out;
- an input missing from the semantics tree, which is *unusable* rather than
  merely unlabelled, because Flutter routes typing through that node when a
  screen reader is attached.

The second is the OtpScreen bug, found earlier by driving the built app in a
browser with accessibility switched on: the one-time-code field was dropped
from the tree by `Opacity`, so with VoiceOver or TalkBack running the code
could not be typed at all. Sign-in is phone plus that code, so one transparent
subtree closed the entire app. Every screen is now checked for it; none is
currently affected.

The first found two things.

**The back button, on 19 screens.** Each hand-rolled
`IconButton(icon: Icon(Icons.arrow_back_rounded))`, and not one passed a
tooltip — so the most-used control in the app announced nothing at all. Now one
`AppBackButton` in `lib/widgets/ui.dart`, taking its word from
`MaterialLocalizations`, which is already translated for every supported
locale.

**The five rating stars.** These *had* a label, wrapped around the button as
`Semantics(button: true, label: '…')` — and it did nothing, because a plain
`Semantics` creates no node of its own. The label annotated a parent while
`IconButton` made its own unlabelled node beside it, so a screen reader
focused five buttons and announced nothing, on the screen whose only purpose
is choosing one of them. The label was also hardcoded English, which
`no_hardcoded_strings_test` could not catch because it is spoken and never
drawn. Now `IconButton(tooltip: l.starRating(n))`, with a new pluralised
string in both `.arb` files.

That `Semantics`-wrapper mistake is the one worth remembering: it looks
exactly like a fix, and it is the reason a gate was needed rather than a
reading of the code.

### 8. The redirect matched by prefix, so a driver could not open their profile

`lib/router.dart` decided which section a path belonged to with
`path.startsWith('/p')`. That also matches `/profile`, `/places` and
`/promos`, so a signed-in driver who tapped Profile in the menu was bounced to
the driver home — along with Saved places, Promotions, and the Promotions
button on the wallet. Four entry points, all dead, for one of the app's two
roles.

Nothing here could have caught it. These are not layout bugs, so the
text-scale gate had nothing to say, and the screens are reachable in a widget
test because a widget test builds them directly and never consults the router.
It took opening them in a browser as a driver and reading the address bar.

`test/route_guard_test.dart` drives the real `GoRouterConfig` through
`MaterialApp.router` instead of building a screen: seven tests covering both
roles against all three routes, plus the role separation the guard is actually
for.

### 9. Characters standing in for icons

Two, both found by rendering in a browser and neither visible to any widget
test — the test font draws every glyph as an identical box, so a tofu and a
star are the same pixels and a box is what passing looks like.

**The earnings rating** was a literal `U+2605` in the string: `48.6 km · ★ 5`.
That character is in no font the app ships, so it renders only where the
platform font happens to carry one. On the web build it did not.

**The phone screen's country code** was `'🇲🇾 +60'`. A flag emoji is a pair of
regional indicators drawn by whatever emoji font the device has; Android and
iOS carry one, the web build does not. The first screen anyone sees opened
with two empty boxes.

`test/no_glyph_icons_test.dart` scans `lib/` with comments stripped and fails
on runes in the arrow, technical, geometric, dingbat and emoji blocks.
Punctuation the copy genuinely needs — `·`, `—`, `’` — is outside those ranges,
and the test asserts that distinction itself rather than trusting the range
list.

Worth recording that the gate was wrong on its first outing: its emoji range
started at `U+1F300`, and regional indicators are at `U+1F1E6..U+1F1FF`, below
it. It reported green with a tofu live on the sign-in screen — a check that
greps for the wrong string, passing and meaningless at the same time. The
range starts at `U+1F000` now and the self-check asserts a flag is caught.

### 10. Two auth steps could be reached without a phone number

`/auth/otp` and `/auth/profile` take the number in `extra` rather than in the
path, because a phone number does not belong in a URL. On a phone that is
enough: the only way in is the step before. On the web every route is
addressable and `extra` does not survive a page load, so a reload on the OTP
screen — the screen people reload, because they are waiting for a message —
arrived with nothing, and both screens rendered anyway.

| Route | What it did with no number |
|---|---|
| `/auth/otp` | "Sent to +60" with no digits, and a Verify that would have called `verifyOtp('', code)` |
| `/auth/profile` | Its submit button only checks the name, so typing one and tapping Start riding called `signIn('')` |

The second matters more than it looks: the phone number is the identity. It
keys the stored profile, picks the avatar colour, and is what a returning user
is matched on, so an account whose number is the empty string matches every
other account whose number is the empty string.

The redirect sends either route back to `/auth/phone` when the number is
missing; the guard and both builders read `extra` through one function so they
cannot disagree about what counts as having one; and `SessionStore.signIn`
asserts the same rule where no route can reach around it.
`test/auth_deeplink_test.dart` covers both directions — the deep links *and*
the real flow, because a guard that blocked everything would have made the
first half pass too.

### 11. What a screen reader is told was not what was written

Finding 7 gates whether a control announces *something*. It cannot see whether
what it announces makes sense, and the audit said so. Half of that turns out
to be mechanically checkable after all: Flutter web builds a real DOM
semantics tree, and Chromium will hand over the accessibility tree a screen
reader actually consumes. Read against the web build, screen by screen:

```
wrote "Earnings, RM18,945.00, offline"
read  "Earnings, RM18,945.00, offline RM18,945 Off"

wrote "Notifications, 1 unread"
read  "Notifications, 1 unread 1"
```

`Semantics(label:)` does not replace what the child announces, it adds to it.
Seven `Semantics` widgets in `lib/` at the time and none set
`excludeSemantics` — but only the three wrapping visible text were wrong,
because an icon-only control has nothing to merge. (A first count said
thirteen. That was a grep for `Semantics(` catching `ExcludeSemantics`,
`MergeSemantics` and the `earningsSemantics` message name along with the
widgets; the number reached #27's description before it was checked.)

Three more the tree showed, each a different kind of wrong:

| Screen | Read out | Now |
|---|---|---|
| Promos | `"Use"`, three times, with nothing to tell them apart | `"Use TEKSI50"`, `"Use WELCOME5"`, `"Use KLIA15"` |
| Earnings | `"48.6 km · 5"` — a number with nothing saying what it counts | `"48.6 km · Rating 5"` |
| Phone | `"12 345 6789"`, the example in its hint, so it never said what to type | `"Phone number"` |

The Promos fix is a `semanticsLabel` on the `Text`, not a `Semantics` wrapper
round the button: `excludeSemantics` there takes the button's own node and its
tap action with it, leaving something that announces "button" and does nothing
when activated. Checked in the browser that all three are still tappable.

The phone field is deliberately *not* excluded — the field has to stay in the
tree or there is nothing to type into, which is finding 7's OtpScreen bug.

`test/semantics_label_leak_test.dart` compares what each `Semantics` widget
declared against the label the rendered node carries, reporting only a node
whose label *begins with* the declared one. The first version compared
declared ≠ spoken and produced two false positives, because `getSemantics`
answers with the nearest node — so a bare mismatch also means "that label
belongs to something else".

### 12. The error states had never been drawn

There are failure strings in the `.arb` files that nothing had ever rendered.
Every one sits behind a guard of this shape:

```dart
if (!Backend.isLive) { …demo path…; return; }
```

`Backend._client` is null in a widget test *and* in the demo web build, so
that early return is always taken. The error branches were unreachable from
the gates and from the browser alike — never laid out at double the text size,
never in Malay, never walked for what a screen reader is given — while the two
gates above both reported covering every screen.

`Backend.debugUnreachable` makes `isLive` true with a null client, so the
calls throw exactly where an unreachable backend makes them throw. It models
"configured but unreachable", which is the state a passenger on a bad
connection is in, rather than "not configured".

**It found OtpScreen overflowing by 132 pixels at 2.0x with an error showing.**
Its column pushes the Verify button down with a `Spacer` and had no scroll
view, so past the viewport the Spacer collapses and the resend link and Verify
are cut off — while the error line is the only thing telling the user the code
was wrong. PhoneScreen already had the fix and its comment describes the
failure exactly.

`test/error_states_test.dart` drives six states in both locales at both text
sizes, each with a proof string asserted before the layout check. That earned
its place immediately: the wallet sheet is behind the same `isLive` guard, so
four of its own tests were measuring a working screen until the proof failed
them.

### 13. The empty states had never been drawn either

The mirror image, and a consequence of the fix recorded under *What "all 23
screens" was worth*. Filling the fixture's lists stopped the gates measuring
empty screens — and because every gate resets the same way, it made the empty
screens unreachable instead. `EmptyState(` appears in ten files and no test had
ever rendered one; the only mention of it anywhere under `test/` was the
comment explaining why the fixture prevents them.

Empty is what a new account opens on. History, Wallet, Notifications and
Earnings all start there.

`reset(populate: false)` is the day-one account, and
`test/empty_states_test.dart` walks all 23 screens with it in both locales at
both text sizes, asking what finding 7's gate asks of the controls that remain.

**It found nothing.** Everything lays out and every control announces itself.
Worth stating plainly: the value is the 120 checks that now run, not a bug
count. What it carries is the proof that it is asking anything at all — the
four screens that really do go empty asserted empty, the populated fixture
asserted *not* empty, and a deliberate overflow through its own copy of the
capture. That last one reported nothing on the first attempt, because `wrap`
gives unbounded height and a tall column simply grows.

Only four of the ten `EmptyState` files are reachable from a day-one account.
The other six need no ride, no documents or no messages; a missing ride has
tests under finding 12.

### 14. Nothing ever walked a journey

Findings 8 and 10 drive the real router, and both ask the same single
question: open one location, see what rendered. Nothing had ever navigated
*from* one screen *to* the next, so every multi-screen journey in the app was
unexercised as a journey.

`test/ride_flow_test.dart` walks both sides — home to destination search and
back, an order opened and left, and a finished ride through rating to the
right home for the role — reading the route rather than the rendered widget,
because a redirect can land somewhere that looks similar.

**It found an overflow in the price sheet.** The row carrying the trip
distance beside its vehicle class is a `spaceBetween` `Row` with neither child
flexible, and the class label is not a short name: `carEconomy` is "Everyday
cars, 4 seats", and in Malay "Kereta harian, 4 tempat duduk".

An overflow is an uncaught `FlutterError` and an uncaught `FlutterError` fails
the test it happens in, so the walk doubles as a layout check for every state
it passes through. That is the only reason this surfaced: the price sheet
appears once a draft has both ends, and a fixture does not take a journey.

The measurement caveat belongs here. The overflow read 145 pixels under the
test font, where every glyph is a fixed-width box, so that number overstates
real widths and does not show the row overflows at 1.0x with a real font. What
stands on its own is that the row had no flex at all and the Malay label is 29
characters.

### What these seven have in common

Every one was invisible to a gate that reported covering the thing it was in.
The shape repeats: a gate walks *screens*, and what it misses is **states** —
a screen as the other role sees it, as a new account sees it, as it looks when
something failed, and as it looks part-way through a journey. Each new gate
here is the same walk with a different fixture, and four of the seven found a
real defect the moment a fixture reached that state for the first time.

## Verification

- `test/contrast_test.dart` — 24 tests asserting every text token clears 4.5:1
  on every surface in both themes, that button and chat-bubble labels clear
  4.5:1 on the brand fill, and that `accent` clears 3:1 as a focus ring.
- Light mode was built and opened in a browser for the first time during this
  pass; the settings and fare screens were checked visually after the fix.
- Chip hit box measured in the running app: **104 × 52** (was ~33 tall).
- Full suite: **583 tests**, `flutter analyze --fatal-infos --fatal-warnings`
  clean. (79 at the time of the original audit, 379 when findings 1–7 were
  written.)

Gates added by findings 8–14, each proven to fail against the defect it was
written for before being relied on:

| Gate | Asks |
|---|---|
| `route_guard_test.dart` | can each role reach the routes its menu links to |
| `no_glyph_icons_test.dart` | does any screen draw a picture with a character |
| `auth_deeplink_test.dart` | is an auth step reachable without what it needs |
| `semantics_label_leak_test.dart` | is a declared label what actually gets read |
| `error_states_test.dart` | do the failure screens lay out, in both locales at both text sizes |
| `empty_states_test.dart` | does a new account's app lay out, and announce itself |
| `ride_flow_test.dart` | does a journey land where each screen says it will |

Findings 8–14 came from rendering the built app in a browser and from reading
Chromium's accessibility tree, not from the skill. The skill's contribution is
findings 1–7.

### What "all 23 screens" was worth when findings 6 and 7 were written

Less than it reads. Both gates walk every screen, but the fixture they walk
them with published one ride and nothing else — no notifications, no
transactions, no chat messages, no finished rides. So five screens were
rendering an empty state, and **NotificationsScreen rendered three `Text`
widgets and zero `Row`s**: the text-scale gate's entire job is catching a
`Row` whose children no longer fit, and on that screen it could not have
failed whatever the text size. It still counted as one of the twenty-three.

Measured before and after populating the fixture, `Text`/`Row` per screen:

| Screen | Before | After |
|---|---|---|
| NotificationsScreen | 3 / **0** | 16 / 5 |
| WalletScreen | 14 / 4 | 30 / 10 |
| HistoryScreen | 5 / 1 | 13 / 8 |
| EarningsScreen | 21 / 3 | 23 / 4 |
| ChatScreen | 7 / 5 | 12 / 5 |

No screen renders an `EmptyState` with the populated fixture. Populating it
surfaced no new overflow, so those five layouts are clean — but that is only
worth saying because the gate was then checked for its ability to fail:
forcing a 600-pixel minimum into the notification row gives a 379-pixel
overflow with the current fixture, and `All tests passed` with the old one.

Fixing this half is what made the other half unreachable, which is finding 13.
`reset(populate: false)` is the day-one account now, and the walks run over
both.

Two things the fixture has to get right, both of which fail silently. Completed
rides carry a rating from *both* sides, or the home screens push to `/rate/...`
from a post-frame callback and throw for want of a `GoRouter` before laying out
at all. And EarningsScreen opens on a midnight cutoff, so its seeded trip is
clamped to just after midnight rather than a flat `now - 30 minutes` — which
would land yesterday for any run between 00:00 and 00:30, empty the screen, and
quiet the gate once a month at an hour nobody is watching.

## Not addressed

- **Whether labels read well aloud.** Narrowed twice: finding 7 gates labels
  and reachability on every screen, and finding 11 gates whether a declared
  label is what actually gets read. Neither can judge whether the words make
  sense spoken. Two candidates were found by reading the accessibility tree
  and deliberately left, because the fix is a wording judgement rather than a
  mechanical one: MenuScreen announces the avatar initials (`"NA Nurul Ain
  binti Abdullah"`) and a context-free `"4.9"`, and SafetyScreen has a bare
  `"Add"`. A widget test can prove a control says something; only a person
  with VoiceOver can tell you it says the right thing.
- **Screen-reader traversal order.** Still not gated, but no longer unlooked
  at: the accessibility tree read under finding 11 collected the traversal
  order of every control on nineteen screens. Several orderings looked wrong —
  Back appearing after the field it precedes visually, a text field listed
  twice — but Flutter web's semantics DOM is a plausible cause for each, and
  telling a framework artefact from a real ordering bug needs a screen reader
  and a person listening. Recorded rather than acted on.
- **The mid-ride sheets.** Four of the app's six sheets — price, offers,
  tracking and active-ride — only exist while a ride is in a particular
  state, so the screen-walking gates never lay them out. Finding 14 reached
  the price sheet and found an overflow in it on the first try. The other
  three remain unmeasured.
- **Landscape and tablet layouts.** The app is portrait-locked
  (`SystemChrome.setPreferredOrientations`) and constrained to a 480 px column,
  so the checklist's landscape/tablet items don't currently apply. Revisit if
  the orientation lock is lifted.
