# GET.teksi

A ride-hailing app built on the inDrive model: **the passenger names the fare, drivers bid, the passenger picks who to ride with.** Passenger and driver live in the same app — one account, one wallet, one history, switch sides whenever you like.

Mobile-first PWA. React 19 + TypeScript + Vite, Leaflet over OpenStreetMap, Zustand for state. No API keys, no backend to provision — it runs offline out of the box.

```bash
npm install
npm run dev      # http://localhost:5173
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
Onboarding with vehicle and document set · go online/offline · order feed sorted by nearest / highest / newest, filtered by minimum fare and pickup distance · accept the asking price or counter-offer, with net-of-commission shown live · withdraw a pending offer · job card driving the trip forward one button at a time (on my way → arrived → start → finish) · navigation hand-off · earnings dashboard by day/week/all-time with per-hour and per-trip breakdowns · vehicle and document management.

**Shared**
Phone + OTP auth · profile and ratings · wallet with top-ups and transaction ledger · promo codes and referrals · saved places · notifications · safety centre with emergency contacts and trip sharing · settings with dark/light theme · installable PWA.

---

## Trying it out

### Solo — the simulated marketplace

On by default. A fleet of bot drivers circulates on the map, bids on your orders (some at your price, some countering), then actually drives to you and completes the trip. In driver mode, bot passengers post orders into your feed and weigh up your bids — a generous offer gets taken quickly, a greedy one often gets declined.

Bot trips are **time-compressed**: a pickup leg that would take minutes plays out in 15–45 seconds, and the main leg in 30–75 seconds, so the whole lifecycle is watchable in one sitting. Longer trips still take proportionally longer than short ones.

### Two-sided — real passenger, real driver

Turn off **Settings → Simulated marketplace**, then open a second tab at `?device=b`. That tab gets its own storage namespace, so it signs in as a genuinely separate account while sharing the same realtime channel. Put one tab in passenger mode and the other in driver mode: orders, bids, acceptances, driver location and chat all flow between them live.

This is verified end to end — order published in tab A appears in tab B's feed, tab B counter-offers, tab A accepts, tab B gets the job, and chat crosses both ways.

---

## Architecture

```
src/
  types/            One domain model shared by both roles
  lib/
    geo.ts          Haversine, bearings, route synthesis, path interpolation
    format.ts       Money (minor units everywhere), distance, time, phone
    bus.ts          BroadcastChannel realtime fan-out
    storage.ts      Namespaced localStorage (+ ?device= isolation)
  services/
    pricing.ts      Fare anchor, price verdicts, commission
    simulation.ts   Bot drivers and passengers; single-tab leader election
  store/
    session.ts      Auth, profile, prefs, wallet, driver profile
    rides.ts        Rides, offers, chat, notifications, ledger + realtime sync
    draft.ts        The passenger's in-progress order
  components/       Map, UI primitives, passenger sheets, driver sheets
  screens/          auth / passenger / driver / shared
```

**Money** is stored in minor units (sen) everywhere and formatted only at the edges.

**Realtime** runs over `BroadcastChannel`, with last-write-wins on each ride's `updatedAt` so tabs converge. Every mutation persists to `localStorage`, so a refresh mid-trip resumes exactly where you were.

**The simulation** elects a single leader tab via a heartbeat, so two open tabs never drive two fleets over the same map.

**Selectors that build a new array must be read through `useShallow`** — Zustand v5 compares snapshots by identity, and a freshly allocated array on every render loops forever. This is noted in `store/rides.ts`; it is the one footgun in the codebase.

### Swapping in a real backend

`lib/bus.ts` and `store/rides.ts` are the only places that know how state propagates. Replacing the `BroadcastChannel` transport with websockets, Supabase Realtime, or Firebase means reimplementing `bus.emit`/`bus.subscribe` against the same `BusEvent` union in `types/index.ts` — the screens don't change.

---

## Notes and limits

- **Maps** use OpenStreetMap raster tiles — no key, but also no tiles when the machine is offline; pins, routes and cars still render correctly over the empty canvas.
- **Routes** are synthesised geometry, not real road routing. Distances apply a 1.35× urban detour factor to straight-line distance. Wire in OSRM/Valhalla/Mapbox in `lib/geo.ts` for real turn-by-turn.
- **Auth** has no SMS gateway: the OTP screen shows the code it "sent" and accepts it. Anything real needs a server.
- **Fares** are loosely calibrated to Klang Valley street pricing (MYR). Tariffs live in `services/pricing.ts`.
- **All data is local** to the browser. There is no server, so nothing syncs between real devices.
- Commission is 9.9% of the fare, shown to drivers on every order before they bid.

## Scripts

```bash
npm run dev        # dev server
npm run build      # typecheck + production build
npm run preview    # serve the build
npm run typecheck  # types only
```
