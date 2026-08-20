# Backend

The app runs with no backend at all. Unconfigured, it keeps its on-device
transport, the simulated marketplace and local persistence — which is what
lets the entire UI be built and tested with nothing to provision. Point it at
a Supabase project and the same build becomes a real multi-device marketplace.

```
supabase/
  migrations/20260815120000_marketplace.sql   the schema, policies and RPCs
  migrations/20260820120000_hide_internal_functions.sql
  migrations/20260820130000_schedule_offer_sweep.sql
  migrations/20260820140000_wallet_ledger.sql
  tests/harness.sql                           stands in for Supabase's own objects
  tests/policies.sql                          what the database must refuse
  tests/concurrency.sh                        races two accepts of the same ride
  tests/run.sh                                applies the migration, runs the suite
```

## What is on the server, and what is not

Shared state goes to Postgres: profiles, rides, offers, chat, live driver
positions and the wallet ledger. Promo codes, saved places and the notification
feed stay on the device — they are single-user state, and nothing in the
marketplace reads them.

## The one rule

**The client is not trusted.** Row-level security decides who may see a row,
`BEFORE UPDATE` triggers decide which columns each side may change, and the
single racy operation — accepting a bid — is a locked server-side function
rather than a client-issued `UPDATE`.

That split matters because RLS on its own cannot express the marketplace's
actual rules. It answers "may this user touch this row"; it cannot answer "may
this user change *this column* of this row", which is precisely the question a
fare negotiation turns on. Hence `guard_ride_update()` and
`guard_offer_write()`.

What the database enforces, all of it verified in `tests/policies.sql`:

| Rule | Enforced by |
|---|---|
| A driver sees open orders, never a rival's bid or price | `offers` select policies |
| A passenger may raise the ask, never lower it | `guard_ride_update` |
| A passenger cannot assign themselves a driver or write the fare | `guard_ride_update` |
| A driver cannot move the fare after winning the bid | `guard_ride_update` |
| A driver advances the trip only along legal transitions | `guard_ride_update` |
| Nobody bids on their own ride, or in another driver's name | `guard_offer_write`, insert policy |
| Bidding closes the moment a ride is assigned | `guard_offer_write` |
| A bid is immutable — withdraw and re-bid | `guard_offer_write` |
| Exactly one bid can ever win a ride | `accept_offer` + `for update` |
| Chat is readable and writable only by the two participants | `is_ride_participant` |
| Profiles are not a directory: you see a counterparty only while sharing a ride | `profiles` select policies |
| The schema's internals are not reachable over HTTP | `private` schema + explicit grants |
| Nobody writes their own wallet, including the driver being paid | ledger has `select` and no other policy |
| A settled ride pays exactly once, however many times it completes | unique index on (ride, user, kind) |

The last point is why names, ratings and vehicles are denormalised onto
`rides` and `offers`. A driver browsing the order feed needs to see who is
asking and what they are asking — but granting read access to every
passenger's profile row to make that work would turn the order feed into a
user directory.

### Why the helpers live in `private`

PostgREST publishes every function in `public` as an RPC endpoint. That is
correct for `accept_offer` and wrong for the helpers, one of which was a real
leak: `ride_bid_context` is SECURITY DEFINER, so it reads with the owner's
privileges — necessary, because the offer guard must see a ride the bidding
driver may not be allowed to read. Exposed at `/rest/v1/rpc/ride_bid_context`
it would have returned the passenger id and status of *any* ride id a caller
tried, which the table policies would have refused.

They now live in a `private` schema that PostgREST does not expose, still
reachable from policies and triggers because those run as the caller and the
signed-in role is granted `EXECUTE` explicitly.

Revoking that execute takes two statements, not one, and missing either leaves
a function callable while looking revoked: Postgres grants `EXECUTE` to
`PUBLIC` on every function, and a Supabase project *additionally* carries
default privileges granting it to `anon` and `authenticated` directly. The
policy suite asserts the end state rather than the statements — it was written
first, and caught exactly this mistake twice.

`accept_offer` remains callable by signed-in users, which is the one Supabase
security-lint warning this schema keeps on purpose: it is the RPC the client is
meant to call, and its first act is to check `auth.uid()` against the ride's
passenger.

### Why the wallet is append-only

Each device used to keep its own wallet: on completion the passenger's app
debited the passenger and the driver's app credited the driver, each computing
its own half. A balance in `SharedPreferences` does not survive a reinstall —
but the real problem is that **the driver's app decided what the driver
earned**. Nothing stopped a modified build from crediting itself any number,
because the number never left the device that invented it.

Now the ledger is append-only, the client has `select` on it and no other
policy, and settlement is an `AFTER UPDATE` trigger on `rides`: it happens
because a ride completed, not because either side asked. `final_price` was
already fixed by `accept_offer` from the winning bid, so there is no amount for
a client to choose. A unique index on `(ride_id, user_id, kind)` makes running
it twice a no-op rather than a double payment.

The balance on `profiles` is a cache of the ledger's sum, maintained by
trigger. The ledger can rebuild it; it can never rebuild the ledger.

The platform's cut is 9.9%, and `private.driver_net()` and Dart's `driverNet()`
are pinned to the same six worked examples from both sides — a fee that differs
between the app's arithmetic and the database's is a fee nobody can explain to
a driver.

**Top-ups are not implemented and cannot honestly be.** A balance may only grow
once a payment provider has taken real money; an RPC letting a client credit
itself would undo this entire section. With a backend configured, the top-up
sheet says so instead of pretending.

### Why `accept_offer` is a function

Two drivers bid. The passenger taps one. If the check ("is this ride still
searching?") and the write ("assign this driver") are separable, two accepts
landing together can both pass the check. `accept_offer` takes `for update` on
the ride row *before* reading its status, so the second caller blocks until the
first commits and then finds a ride that is no longer searching.

`tests/concurrency.sh` races the two accepts as separate backends, repeatedly,
and asserts exactly one wins. Deleting the `for update` makes it fail on the
first round with two accepted bids on one ride — so the test is measuring the
lock, not passing by luck.

## Running the tests

They need nothing but a local PostgreSQL 14+. No Supabase project is involved:
`harness.sql` creates the `auth` schema, an `auth.uid()` backed by a session
variable, the `anon`/`authenticated` roles and the realtime publication, so the
migration applies unmodified and each case can act as a real signed-in user.

```sh
supabase/tests/run.sh          # migration + policy suite
supabase/tests/concurrency.sh  # the double-accept race
```

Both run on every push; see the `database` job in `.github/workflows/ci.yml`.

## Applying it to a project

```sh
supabase link --project-ref <ref>
supabase db push
```

Then enable **Phone** auth and attach an SMS provider, since sign-in is phone
plus OTP.

## Pointing the app at it

The live project's URL and publishable key are in
[`config/get-teksi.json`](../config/get-teksi.json):

```sh
flutter run --dart-define-from-file=config/get-teksi.json
```

Omit the flag and the app runs on its on-device transport instead — every
screen still works, nothing is provisioned. Both values are needed together;
either alone leaves the app local.

The publishable key is a public identifier and belongs in the shipped binary.
It is safe there because row-level security, not key secrecy, is what protects
the data — which is the reason the policies above are tested as carefully as
the app itself. Never ship the **service role** key: it bypasses RLS entirely.

### The live project

| | |
|---|---|
| Ref | `usrbfyruvqblpufejmxh` |
| Region | `ap-southeast-1` (Singapore, ~10 ms from Kuala Lumpur) |
| Postgres | 17 |

All three migrations are applied. Supabase's security linter reports one
warning against it, kept deliberately: `accept_offer` is callable by signed-in
users, which is what it is for.

`sweep_expired_offers()` runs every minute under `pg_cron`, verified by
`cron.job_run_details` rather than by the schedule merely existing. The
migration that sets it up skips with a notice where `pg_cron` is unavailable,
which is why the policy suite still applies cleanly to a stock PostgreSQL.

## How it connects to the app

`RealtimeTransport` in `lib/core/bus.dart` is the seam. `LocalTransport` keeps
events in-process; `SupabaseTransport` carries the same events through
Postgres. Nothing above that file knows which one is in use.

- `lib/core/config.dart` — build-time configuration
- `lib/core/backend.dart` — connection and phone OTP auth
- `lib/core/rows.dart` — model ↔ row mapping, tested in `test/rows_test.dart`
- `lib/core/supabase_transport.dart` — the live transport

## Sign-in

With a backend configured, the phone screen asks Supabase to send a real OTP
and the code screen verifies it; the demo code panel is hidden, because showing
a guessable stand-in next to a real SMS would be worse than useless. Without a
backend the flow is unchanged and still fully walkable.

The load-bearing detail is identity. Every policy in the schema compares
`auth.uid()` against the ids an account writes, so the verified id travels from
the code screen to profile setup and the local user is created **under it**. A
profile that kept a locally minted id would have all of its writes refused —
silently, since RLS rejects rather than errors. `test/marketplace_test.dart`
pins that: the local user adopts the backend's id, and a local-only profile is
replaced rather than reused when the backend supplies a different one.

### Known gaps

- **The simulation stays local.** Bot rides and bids are dropped before they
  reach the network, because they belong to no real account and row-level
  security would reject them. Turn it off in Settings when testing against a
  real backend, or the map shows local bots alongside real drivers.
- **Only part of the app is translated.** The Language setting is real and
  Bahasa Melayu is in place for onboarding, sign-in and Settings. Screens that
  have not been converted yet fall back to English automatically, which is what
  makes translating them one at a time safe. See `lib/l10n/`.
