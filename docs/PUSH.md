# Push notifications: the decision, not the design

Nothing arrives while the app is closed. This file exists to turn that into a
choice you can make, rather than a recommendation you have to take on trust.

It deliberately stops short of a design. The transports differ in what they
cost you to *operate*, not mainly in what they cost to write, and that is not
mine to decide.

---

## What arrives today, and what does not

| | app in front | app behind another app | app closed or swiped away |
| --- | --- | --- | --- |
| Driver, on duty | yes | **yes** — the foreground service holds the process | no |
| Driver, off duty | yes | until Android reclaims the process | no |
| Passenger | yes | until Android reclaims the process | no |
| Web | yes | while the tab lives | no |

The middle column is the part that already works, and it is worth being clear
about why: `DutyService` is a `foregroundServiceType="location"` service, so
while a driver is on duty the process stays alive and
`android.app.NotificationManager` keeps firing. A driver with WhatsApp open
still hears a new order.

**The gap is the right-hand column, and it is worst for passengers.** A driver
on duty is, by definition, using the app. A passenger who has published a ride
and put their phone in their pocket has no foreground service, no reason to
keep the app open, and is the person most likely to miss "your driver has
arrived".

---

## Why Firebase Cloud Messaging is not on the table

FCM is how a ride-hailing app normally does this. Here it would fail the
build — not as a matter of taste, but mechanically. `ci.yml` unpacks the
release APK's `classes*.dex` and fails on `Lcom/google/firebase`, and the
`firebase_messaging` client SDK brings exactly that. The scan would catch it
before any device did.

That constraint is the whole reason this app installs and runs on a Huawei
phone. It is also why there is no single answer below: **every GMS-free push
route is platform-specific.** There is no one transport that covers iOS,
GMS Android, Huawei Android and the web. Anyone who tells you otherwise is
describing FCM.

---

## The four transports, and what each actually costs

### APNs — iOS, and the one with no real downside

Apple's push service is the *only* way to wake a closed iOS app, and it has no
Google dependency whatsoever. Talk to it directly over HTTP/2 with a `.p8`
token-based key.

- **Credentials:** one APNs auth key from the Apple Developer account you
  already hold. It is the same family of key as the App Store Connect key
  `release-ios.yml` already uses, and generated in the same place.
- **Operational cost:** none. No server to run beyond whatever sends the
  request.
- **Caveat:** none that matters here. This is the easy one.

### Web Push — the browser, also easy

A W3C standard, driven by a VAPID key pair. Works in Chrome, Edge, Firefox and
Safari 16.4+. The service worker the app already registers is the receiving
end.

- **Credentials:** a VAPID key pair you generate yourself. No vendor, no
  account, no cost.
- **Operational cost:** none.
- **Caveat worth knowing:** Chrome's push endpoint is operated by Google. That
  is a URL your *server* posts to, not an SDK in the app and not GMS on the
  device — the dex scan stays clean and a Huawei phone's browser is unaffected.
  If that distinction matters to you politically rather than technically, this
  is the place to say so.

### HMS Push — Huawei AppGallery builds only

Huawei's equivalent of FCM, and the native answer for the devices this app
exists to support.

- **Credentials:** a Huawei Developer account, an AppGallery Connect app, and
  its own credentials.
- **Operational cost:** another vendor, another console, another review
  process.
- **The catch, and it is a real one:** `ci.yml`'s dex scan bans
  `Lcom/huawei/hms` as firmly as it bans Google's. Adding HMS means a **build
  flavour** — an AppGallery variant that carries HMS and a Play/sideload
  variant that does not — and the scan must then assert per-flavour rather than
  globally. That is a change to the property the repository is currently proud
  of, and it should be made deliberately, not as a side effect.

### UnifiedPush / self-hosted — GMS Android without Google

The open-source answer: your server pushes to a distributor app (ntfy is the
common one) which holds a socket and relays to this app.

- **Credentials:** none external. You run the server.
- **Operational cost:** **you run the server.** A push server that is down is
  a passenger who never learns their driver arrived, so this is a service with
  an uptime obligation, not a side project.
- **The catch:** it only works if the user installs a distributor app. For a
  consumer ride-hailing app that is not a realistic ask. Without one, the
  fallback is your own persistent socket, which means a second foreground
  service running whenever the app is installed — battery cost, a permanent
  notification, and Play Store policy questions about why a passenger app needs
  one.

---

## Where the sender lives

Worth noting because it changes the cost of every option above: **you do not
need a new service.** The project already has Supabase, and an Edge Function
with secrets is a natural home for APNs and Web Push credentials. A database
trigger or `pg_cron` can call it on the row changes that already drive the
in-app notification centre — a bid arriving, an offer being accepted, a ride
changing state.

That matters because "a server that holds the credentials" was the main
objection in `docs/PLATFORMS.md`, and it is already paid for. There are
currently no Edge Functions deployed, so this would be the first.

---

## Four ways to go

**A. iOS and web now, Android deferred.**
APNs plus Web Push, sent from an Edge Function. Covers both platforms fully for
closed apps, needs one Apple key and one self-generated key pair, and adds no
infrastructure you do not already run. Android keeps what it has: the
foreground service for on-duty drivers, nothing for a closed app.

**B. A plus HMS, with build flavours.**
Adds genuine closed-app push on Huawei devices. Costs a Huawei developer
account, a second build variant, and a change to the GMS scan so it asserts
per-flavour. Leaves Play-distributed GMS Android still uncovered, which is the
irony of this route.

**C. A plus a self-hosted socket for all Android.**
One transport for every Android device regardless of GMS. Costs a server with
an uptime obligation and a persistent foreground service on passengers'
phones, which is the part most likely to be rejected — by the store, or by
users watching their battery.

**D. Nothing, deliberately.**
Keep the in-app centre and the foreground service, and say in the store
listing that alerts need the app open. Honest, zero cost, and leaves the
passenger gap exactly where it is.

---

## What I would pick, and why

**A, now, and defer the Android question until there is traffic to justify it.**

The reasoning is that A is the only option with no tail: two standard
transports, credentials you either already hold or generate yourself, no new
service, no store-policy exposure, and nothing that touches the GMS-free
property CI enforces. It closes the gap completely on iOS and the web.

Android is where the real trade is, and deferring it is close to free, because
the case that matters most on Android — a driver waiting for orders — is
already covered by the foreground service. The uncovered case is a passenger
with the app closed on a GMS device, and the honest answer is that solving it
properly means either FCM (which this app cannot have) or a socket you operate
(which costs more than it is worth before there are users).

What would change my mind: if the passenger base turns out to be mostly
Android with the app closed, C becomes worth its cost. That is a question
usage data answers and I cannot.

---

## What CI could keep honest

Whichever route is taken, two properties are worth asserting rather than
trusting, in the style of the existing checks:

- **The dex scan stays meaningful.** If B is chosen, the scan must assert
  per-flavour — HMS present in the AppGallery variant, absent from the other —
  rather than being relaxed globally. A scan that is simply weakened is worse
  than no scan, because it still looks like one.
- **Credentials never land in a build.** The same shape as the keystore check
  in `release-android.yml`: assert the shipped artifact does *not* contain the
  APNs key or the VAPID private key, rather than assuming the build config
  kept them out.
