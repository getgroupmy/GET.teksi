#!/usr/bin/env bash
#
# Drive one real ride, end to end, against the live Supabase project.
#
# Everything else in supabase/tests/ runs against a throwaway PostgreSQL with a
# harness standing in for Supabase. That proves the policies are right. It does
# not prove the project is configured right — that phone auth actually sends,
# that the profile trigger actually fires on a real sign-in, that PostgREST
# actually exposes accept_offer and actually refuses what the policies refuse.
# Those are properties of a deployment, and the only way to check a deployment
# is to use it.
#
# So this signs two real accounts in with real SMS codes and makes them trade:
# the passenger publishes an order, the driver bids, the passenger accepts, the
# driver drives it to completion, and the wallet is checked for the two rows the
# settlement trigger should have written. Along the way it tries four things the
# marketplace rules forbid and fails if any of them is allowed.
#
# You need two phone numbers you control. They can be the same person's — the
# accounts are what have to differ, not the owner.
#
# Usage:
#   supabase/tests/live-ride.sh +60123456789 +60129876543
#
# Requires curl, jq and python3. Reads the project from config/get-teksi.json.

set -euo pipefail

CONFIG="${CONFIG:-config/get-teksi.json}"
[ -f "$CONFIG" ] || { echo "no $CONFIG — run from the repo root"; exit 1; }
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

URL=$(jq -r .SUPABASE_URL "$CONFIG")
KEY=$(jq -r .SUPABASE_PUBLISHABLE_KEY "$CONFIG")

PASSENGER_PHONE="${1:-}"
DRIVER_PHONE="${2:-}"
if [ -z "$PASSENGER_PHONE" ] || [ -z "$DRIVER_PHONE" ]; then
  echo "usage: $0 <passenger-phone-e164> <driver-phone-e164>"
  echo "example: $0 +60123456789 +60129876543"
  exit 1
fi

# The fare, in sen, and what the driver should be left with after the 9.9% cut.
# Computed here rather than copied, so changing the fare cannot silently make
# the assertion check the wrong number.
#
# 2500 is chosen because 2500 * 0.901 is 2252.5 — exactly a half-sen, which is
# where rounding rules disagree. Postgres round() and Dart's .round() both go
# half away from zero and give 2253; Python's round() is half-to-even and gives
# 2252. Getting this wrong here would fail the assertion against a database
# that is behaving correctly, so the expected value is computed half-up to
# match the two implementations that actually decide what a driver is paid.
FARE=2500
DRIVER_NET=$(python3 -c "
from decimal import Decimal, ROUND_HALF_UP
print(int((Decimal($FARE) * Decimal('0.901')).quantize(Decimal('1'), rounding=ROUND_HALF_UP)))")

pass=0
fail=0
ok()   { printf '  \033[32mok\033[0m   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail + 1)); }
step() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# --- authentication ----------------------------------------------------------
#
# Exactly what lib/core/backend.dart does: ask for a code, then trade the code
# for a session. If the first call fails with phone_provider_disabled, the
# provider is off in the dashboard and nothing below can run.

sign_in() {
  local phone="$1" who="$2" code send verify
  send=$(curl -sS -X POST "$URL/auth/v1/otp" \
    -H "apikey: $KEY" -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg p "$phone" '{phone: $p}')")

  if echo "$send" | jq -e '.error_code // .msg // .error' >/dev/null 2>&1; then
    echo "sending the code to $who failed:" >&2
    echo "$send" | jq . >&2
    exit 1
  fi

  # The prompt goes to the terminal, not to stdout: this function's stdout is
  # captured by the caller, and a prompt mixed into it would end up parsed as
  # the token.
  printf '  code sent to %s (%s) — enter it: ' "$who" "$phone" >/dev/tty
  read -r code </dev/tty

  verify=$(curl -sS -X POST "$URL/auth/v1/verify" \
    -H "apikey: $KEY" -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg p "$phone" --arg t "$code" '{phone: $p, token: $t, type: "sms"}')")

  if [ "$(echo "$verify" | jq -r '.access_token // "null"')" = null ]; then
    echo "verifying $who failed:" >&2
    echo "$verify" | jq . >&2
    exit 1
  fi
  echo "$verify" | jq -r '.access_token + " " + .user.id'
}

# PostgREST as a signed-in user. Every call below goes through the same policies
# a phone would, which is the whole point of using tokens rather than SQL.
api() {
  local token="$1" method="$2" path="$3" body="${4:-}"
  if [ -n "$body" ]; then
    curl -sS -X "$method" "$URL/rest/v1/$path" \
      -H "apikey: $KEY" -H "Authorization: Bearer $token" \
      -H 'Content-Type: application/json' -H 'Prefer: return=representation' \
      -d "$body"
  else
    curl -sS -X "$method" "$URL/rest/v1/$path" \
      -H "apikey: $KEY" -H "Authorization: Bearer $token"
  fi
}

step "Signing in"
read -r P_TOKEN P_ID <<<"$(sign_in "$PASSENGER_PHONE" passenger)"
ok "passenger signed in as $P_ID"
read -r D_TOKEN D_ID <<<"$(sign_in "$DRIVER_PHONE" driver)"
ok "driver signed in as $D_ID"

[ "$P_ID" != "$D_ID" ] || { echo "both sign-ins returned the same account"; exit 1; }

step "Profiles"
# Created by the on_auth_user_created trigger, not by the client — there is no
# insert policy on profiles, deliberately. If the trigger did not fire, this is
# where it shows.
P_PROFILE=$(api "$P_TOKEN" GET "profiles?id=eq.$P_ID&select=id,name,wallet_balance")
if [ "$(echo "$P_PROFILE" | jq -r '.[0].id // "null"')" = "$P_ID" ]; then
  ok "the sign-in trigger created the passenger's profile"
else
  bad "no profile row for the passenger — on_auth_user_created did not fire"
  echo "$P_PROFILE" | jq . ; exit 1
fi

api "$P_TOKEN" PATCH "profiles?id=eq.$P_ID" \
  '{"name":"Live Test Passenger"}' >/dev/null
api "$D_TOKEN" PATCH "profiles?id=eq.$D_ID" \
  '{"name":"Live Test Driver","is_driver":true,"driver_rating":4.90,
    "vehicle":{"make":"Perodua","model":"Myvi","year":2022,"color":"White",
               "plate":"WLR 4821","vehicleClass":"economy","seats":4}}' >/dev/null
ok "driver profile carries a vehicle"

step "Publishing the order"
RIDE=$(api "$P_TOKEN" POST rides "$(jq -nc \
  --arg pid "$P_ID" --argjson fare "$FARE" '{
  passenger_id: $pid,
  passenger_name: "Live Test Passenger",
  passenger_avatar_color: -12303292,
  passenger_rating: 5.00,
  pickup:  {name: "KL Sentral", address: "Brickfields", coord: {lat: 3.1339, lng: 101.6869}},
  dropoff: {name: "Suria KLCC", address: "Jalan Ampang", coord: {lat: 3.1577, lng: 101.7120}},
  pickup_lat: 3.1339, pickup_lng: 101.6869,
  dropoff_lat: 3.1577, dropoff_lng: 101.7120,
  asking_price: $fare, recommended_price: $fare,
  distance_km: 4.2, duration_minutes: 14,
  payment_method: "wallet"
}')")
RIDE_ID=$(echo "$RIDE" | jq -r '.[0].id // "null"')
if [ "$RIDE_ID" != null ]; then
  ok "order published as $RIDE_ID"
else
  bad "the passenger could not publish an order"; echo "$RIDE" | jq .; exit 1
fi

step "The driver's feed"
FEED=$(api "$D_TOKEN" GET "rides?status=eq.searching&select=id,asking_price,dropoff")
if echo "$FEED" | jq -e --arg r "$RIDE_ID" 'map(.id) | index($r)' >/dev/null; then
  ok "the open order reaches the driver"
else
  bad "the driver cannot see the open order"; echo "$FEED" | jq .
fi

step "Bidding"
OFFER=$(api "$D_TOKEN" POST offers "$(jq -nc \
  --arg rid "$RIDE_ID" --arg did "$D_ID" --argjson fare "$FARE" '{
  ride_id: $rid, driver_id: $did,
  driver_name: "Live Test Driver", driver_avatar_color: -16711936,
  driver_rating: 4.90, driver_rides_given: 320,
  vehicle: {make: "Perodua", model: "Myvi", plate: "WLR 4821"},
  price: $fare, eta_minutes: 4, distance_km: 1.1,
  matched_asking_price: true,
  expires_at: (now + 90) | todate
}')")
OFFER_ID=$(echo "$OFFER" | jq -r '.[0].id // "null"')
if [ "$OFFER_ID" != null ]; then
  ok "the driver took the asking price"
else
  bad "the driver could not bid"; echo "$OFFER" | jq .; exit 1
fi

step "What the rules forbid"
# Each of these is a marketplace rule that RLS or a guard trigger enforces. A
# refusal here is the pass. Note that RLS hides rows rather than raising, so a
# forbidden update on a row the caller cannot see comes back as zero rows
# changed — which is why these check the effect, not the error.

LOWER=$(api "$P_TOKEN" PATCH "rides?id=eq.$RIDE_ID" \
  "{\"asking_price\": $((FARE - 500))}")
if echo "$LOWER" | jq -e 'if type == "array" then length == 0 else has("message") end' >/dev/null; then
  ok "the passenger cannot lower the ask once bids are in"
else
  bad "the passenger lowered the asking price"; echo "$LOWER" | jq .
fi

SELF=$(api "$P_TOKEN" PATCH "rides?id=eq.$RIDE_ID" "{\"driver_id\":\"$P_ID\"}")
if echo "$SELF" | jq -e 'if type == "array" then length == 0 else has("message") end' >/dev/null; then
  ok "the passenger cannot assign themselves a driver"
else
  bad "the passenger assigned themselves as the driver"; echo "$SELF" | jq .
fi

WRITE_LEDGER=$(api "$P_TOKEN" POST wallet_transactions "$(jq -nc --arg u "$P_ID" '{
  user_id: $u, kind: "topup", amount: 100000, description: "free money"
}')")
if echo "$WRITE_LEDGER" | jq -e 'has("message") or (type == "array" and length == 0)' >/dev/null; then
  ok "a client cannot write its own wallet"
else
  bad "a client credited its own wallet"; echo "$WRITE_LEDGER" | jq .
fi

step "Accepting"
ACCEPTED=$(api "$P_TOKEN" POST rpc/accept_offer "{\"p_offer_id\":\"$OFFER_ID\"}")
if [ "$(echo "$ACCEPTED" | jq -r '.driver_id // "null"')" = "$D_ID" ]; then
  ok "accept_offer assigned the winning driver"
else
  bad "accept_offer did not assign the driver"; echo "$ACCEPTED" | jq .; exit 1
fi
if [ "$(echo "$ACCEPTED" | jq -r '.final_price // "null"')" = "$FARE" ]; then
  ok "the fare settled at the winning bid"
else
  bad "final_price is not the bid"; echo "$ACCEPTED" | jq .
fi

MOVE_FARE=$(api "$D_TOKEN" PATCH "rides?id=eq.$RIDE_ID" \
  "{\"final_price\": $((FARE * 2))}")
if echo "$MOVE_FARE" | jq -e 'if type == "array" then length == 0 else has("message") end' >/dev/null; then
  ok "the driver cannot move the fare after winning it"
else
  bad "the driver changed the settled fare"; echo "$MOVE_FARE" | jq .
fi

step "Driving it"
# The guard allows accepted -> arriving -> waiting -> inProgress -> completed
# and nothing else forwards. Skipping a stage is refused, which is checked
# first so a permissive guard cannot pass by the happy path alone.
SKIP=$(api "$D_TOKEN" PATCH "rides?id=eq.$RIDE_ID" '{"status":"completed"}')
if echo "$SKIP" | jq -e 'if type == "array" then length == 0 else has("message") end' >/dev/null; then
  ok "the driver cannot jump straight to completed"
else
  bad "an illegal transition was allowed"; echo "$SKIP" | jq .
fi

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for stage in \
  '{"status":"arriving"}' \
  "{\"status\":\"waiting\",\"arrived_at\":\"$NOW\"}" \
  "{\"status\":\"inProgress\",\"started_at\":\"$NOW\"}" \
  "{\"status\":\"completed\",\"completed_at\":\"$NOW\"}"
do
  RES=$(api "$D_TOKEN" PATCH "rides?id=eq.$RIDE_ID" "$stage")
  label=$(echo "$stage" | jq -r .status)
  if [ "$(echo "$RES" | jq -r 'if type == "array" then (.[0].status // "null") else "null" end')" = "$label" ]; then
    ok "driver advanced the trip to $label"
  else
    bad "could not advance the trip to $label"; echo "$RES" | jq .
  fi
done

step "Settlement"
# Nobody asked for this. The trigger fired because the ride completed.
P_LEDGER=$(api "$P_TOKEN" GET "wallet_transactions?ride_id=eq.$RIDE_ID&select=kind,amount")
D_LEDGER=$(api "$D_TOKEN" GET "wallet_transactions?ride_id=eq.$RIDE_ID&select=kind,amount")

P_DEBIT=$(echo "$P_LEDGER" | jq -r 'map(select(.kind == "ridePayment")) | .[0].amount // "none"')
D_CREDIT=$(echo "$D_LEDGER" | jq -r 'map(select(.kind == "rideEarning")) | .[0].amount // "none"')

if [ "$P_DEBIT" = "-$FARE" ]; then
  ok "the passenger was debited $FARE sen"
else
  bad "expected a -$FARE debit, got $P_DEBIT"; echo "$P_LEDGER" | jq .
fi
if [ "$D_CREDIT" = "$DRIVER_NET" ]; then
  ok "the driver was credited $DRIVER_NET sen, net of the 9.9% fee"
else
  bad "expected $DRIVER_NET credited, got $D_CREDIT"; echo "$D_LEDGER" | jq .
fi

# The ledger is one-directional: each side sees its own row and not the other's.
if [ "$(echo "$P_LEDGER" | jq 'length')" = 1 ] && [ "$(echo "$D_LEDGER" | jq 'length')" = 1 ]; then
  ok "each side reads its own ledger entry and not the other's"
else
  bad "the ledger is not scoped to its owner"
  echo "passenger:"; echo "$P_LEDGER" | jq .
  echo "driver:";    echo "$D_LEDGER" | jq .
fi

BALANCE=$(api "$D_TOKEN" GET "profiles?id=eq.$D_ID&select=wallet_balance" | jq -r '.[0].wallet_balance')
if [ "$BALANCE" = "$DRIVER_NET" ]; then
  ok "the cached balance matches the ledger"
else
  bad "cached balance is $BALANCE, ledger says $DRIVER_NET"
fi

step "What is left behind"
# Nothing is deleted, and nothing should be. There is no delete policy on
# rides: a completed trip is the receipt for money that moved, and a client
# that could erase one could erase the evidence. Confirm that rather than
# quietly trying a delete that was always going to do nothing.
GONE=$(api "$P_TOKEN" DELETE "rides?id=eq.$RIDE_ID")
STILL=$(api "$P_TOKEN" GET "rides?id=eq.$RIDE_ID&select=id,status" | jq 'length')
if [ "$STILL" = 1 ]; then
  ok "the completed ride survives a delete attempt, as history should"
else
  bad "a client deleted a settled ride"; echo "$GONE" | jq .
fi
printf '  \033[33mnote\033[0m ride %s and two accounts remain on the project.\n' "$RIDE_ID"
printf '       Re-running signs the same two accounts back in rather than adding more.\n'

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
