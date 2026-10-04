#!/usr/bin/env bash
# Two drivers bid; the passenger's device accepts one while a second request
# for the other lands in the same instant. Exactly one may win.
#
# The sequential test in policies.sql cannot prove this: it shows that a second
# accept is refused *after* the first has committed, which any status check
# would pass. What makes the guarantee hold under a real race is the
# `for update` lock in accept_offer(), and the only way to demonstrate that is
# to actually race it — so this launches both calls as separate backends at the
# same moment, many times over.
#
# Removing the lock makes this fail: both callers read `searching`, both
# proceed, and the ride ends up assigned to whoever committed last while both
# drivers believe they won.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
db="${TEKSI_TEST_DB:-teksi_race_test}"
rounds="${TEKSI_RACE_ROUNDS:-25}"
psql_opts=(-v ON_ERROR_STOP=1 -q --no-psqlrc)

psql "${psql_opts[@]}" -d postgres -tAc "drop database if exists ${db}"
psql "${psql_opts[@]}" -d postgres -tAc "create database ${db}"
psql "${psql_opts[@]}" -d "${db}" -f "${here}/harness.sql" 2>&1 | grep -v 'wal_level\|HINT:' || true
for migration in "${here}"/../migrations/*.sql; do
  psql "${psql_opts[@]}" -d "${db}" -f "${migration}"
done

passenger='11111111-1111-4111-8111-111111111111'
driver_a='22222222-2222-4222-8222-222222222222'
driver_b='33333333-3333-4333-8333-333333333333'

psql "${psql_opts[@]}" -d "${db}" <<SQL
insert into auth.users (id, phone, raw_user_meta_data) values
  ('${passenger}', '+60123000001', '{"name":"Aisyah"}'),
  ('${driver_a}',  '+60123000002', '{"name":"Ravi"}'),
  ('${driver_b}',  '+60123000003', '{"name":"Siti"}');
update public.profiles set is_driver = true,
  vehicle = '{"make":"Perodua","model":"Bezza","year":2021,"color":"Silver","plate":"W 1","vehicleClass":"economy","seats":4}'::jsonb
where id in ('${driver_a}', '${driver_b}');
SQL

wins_a=0
wins_b=0

for ((round = 1; round <= rounds; round++)); do
  ride="$(psql -tAq --no-psqlrc -d "${db}" -c "
    insert into public.rides (
      passenger_id, passenger_name, passenger_avatar_color, passenger_rating,
      pickup, dropoff, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
      asking_price, recommended_price, distance_km, duration_minutes)
    values ('${passenger}', 'Aisyah', 0, 5, '{}'::jsonb, '{}'::jsonb,
            3.1, 101.7, 3.2, 101.8, 1000, 1000, 5, 15)
    returning id;")"

  offer_a="$(psql -tAq --no-psqlrc -d "${db}" -c "
    insert into public.offers (ride_id, driver_id, driver_name, driver_avatar_color,
      driver_rating, vehicle, price, eta_minutes, distance_km, expires_at)
    values ('${ride}', '${driver_a}', 'Ravi', 0, 4.9, '{}'::jsonb, 1100, 5, 1,
            now() + interval '5 minutes') returning id;")"
  offer_b="$(psql -tAq --no-psqlrc -d "${db}" -c "
    insert into public.offers (ride_id, driver_id, driver_name, driver_avatar_color,
      driver_rating, vehicle, price, eta_minutes, distance_km, expires_at)
    values ('${ride}', '${driver_b}', 'Siti', 0, 4.8, '{}'::jsonb, 1200, 4, 1,
            now() + interval '5 minutes') returning id;")"

  # Two separate backends, started together, each accepting a different bid.
  # Which one wins is not the assertion — that exactly one does, is.
  accept() {
    psql -tAq --no-psqlrc -d "${db}" \
      -c "select set_config('test.uid', '${passenger}', false)" \
      -c "select public.accept_offer('$1')" >/dev/null 2>&1 || true
  }
  accept "${offer_a}" &
  accept "${offer_b}" &
  wait

  winner="$(psql -tAq --no-psqlrc -d "${db}" -c "
    select coalesce((select driver_id::text from public.rides where id = '${ride}'), 'none');")"
  accepted="$(psql -tAq --no-psqlrc -d "${db}" -c "
    select count(*) from public.offers where ride_id = '${ride}' and status = 'accepted';")"

  if [[ "${accepted}" != "1" ]]; then
    echo "RACE FAILURE round ${round}: ${accepted} bids accepted on one ride" >&2
    exit 1
  fi
  if [[ "${winner}" == "none" ]]; then
    echo "RACE FAILURE round ${round}: a bid was accepted but no driver assigned" >&2
    exit 1
  fi

  # The assigned driver and the settled fare must come from the same bid.
  consistent="$(psql -tAq --no-psqlrc -d "${db}" -c "
    select count(*) from public.rides r
      join public.offers o on o.ride_id = r.id and o.status = 'accepted'
     where r.id = '${ride}'
       and r.driver_id = o.driver_id
       and r.final_price = o.price
       and r.status = 'accepted';")"
  if [[ "${consistent}" != "1" ]]; then
    echo "RACE FAILURE round ${round}: the ride and the winning bid disagree" >&2
    exit 1
  fi

  if [[ "${winner}" == "${driver_a}" ]]; then
    wins_a=$((wins_a + 1))
  else
    wins_b=$((wins_b + 1))
  fi
done

echo "${rounds} concurrent double-accepts: exactly one winner every time (${wins_a} / ${wins_b} split)"
