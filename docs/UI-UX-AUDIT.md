# UI/UX accessibility audit

Run against the vendored **ui-ux-pro-max** skill (`.claude/skills/ui-ux-pro-max/`),
using its `references/pro-rules.md` pre-delivery checklist for native/mobile app
UI plus targeted `--domain ux` and `--stack flutter` queries.

Every finding below was measured or observed, not assumed. The contrast numbers
are WCAG relative-luminance ratios computed from the actual token values, and
they are now locked in by `test/contrast_test.dart` so the palette cannot
silently regress.

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

## Verification

- `test/contrast_test.dart` — 24 tests asserting every text token clears 4.5:1
  on every surface in both themes, that button and chat-bubble labels clear
  4.5:1 on the brand fill, and that `accent` clears 3:1 as a focus ring.
- Light mode was built and opened in a browser for the first time during this
  pass; the settings and fare screens were checked visually after the fix.
- Chip hit box measured in the running app: **104 × 52** (was ~33 tall).
- Full suite: 79 tests, `flutter analyze` clean.

## Not addressed

- **Landscape and tablet layouts.** The app is portrait-locked
  (`SystemChrome.setPreferredOrientations`) and constrained to a 480 px column,
  so the checklist's landscape/tablet items don't currently apply. Revisit if
  the orientation lock is lifted.
- **Dynamic Type at the largest settings.** Rows were fixed where they were
  obviously brittle, but the app has not been walked end to end at maximum
  system text size.
- **Screen-reader traversal order.** Semantic labels were added to the
  icon-only controls, but the full focus order has not been audited with a real
  screen reader.
