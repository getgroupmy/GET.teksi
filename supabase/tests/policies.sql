-- What the marketplace rules are worth is what the database refuses to do.
--
-- Every case below acts as a real signed-in user — `set role authenticated`
-- plus an `auth.uid()` — so the policies, the guard triggers and accept_offer()
-- are exercised exactly as a client would hit them. The script raises on the
-- first surprise, so psql's exit code is the verdict.

\set ON_ERROR_STOP on
-- The assertions report through NOTICE; result grids would only be noise.
\pset tuples_only on
\pset footer off

create schema test;

-- Asserts that a statement is rejected. A statement that succeeds when it
-- should not is the failure mode that matters here, so that is what raises.
create function test.denied(stmt text, what text) returns void
language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    raise notice '  denied as expected: % (%)', what, sqlerrm;
    return;
  end;
  raise exception 'SECURITY FAILURE: % was allowed', what;
end $$;

create function test.allowed(stmt text, what text) returns void
language plpgsql as $$
begin
  execute stmt;
  raise notice '  allowed as expected: %', what;
end $$;

-- A row the caller cannot see is not an error, it is invisible: their UPDATE
-- matches nothing and reports success having changed nothing. That is the
-- correct shape for a read-restricted row, and it is what must be asserted —
-- expecting an exception here would pass for the wrong reason the day the
-- policy is loosened.
create function test.affects_nothing(stmt text, what text) returns void
language plpgsql as $$
declare
  touched integer;
begin
  execute stmt;
  get diagnostics touched = row_count;
  if touched <> 0 then
    raise exception 'SECURITY FAILURE: % changed % row(s)', what, touched;
  end if;
  raise notice '  affected no rows, as expected: %', what;
end $$;

create function test.eq(got anyelement, want anyelement, what text) returns void
language plpgsql as $$
begin
  if got is distinct from want then
    raise exception 'ASSERTION FAILED: % — got %, want %', what, got, want;
  end if;
  raise notice '  ok: %', what;
end $$;

create function test.act_as(who uuid) returns void
language plpgsql as $$
begin
  perform set_config('test.uid', who::text, false);
end $$;

-- The assertions run while acting as `authenticated`, so that role needs to
-- reach them. They are SECURITY INVOKER, so the statements they execute are
-- still subject to every policy under test.
grant usage on schema test to authenticated;
grant execute on all functions in schema test to authenticated;

-- ---------------------------------------------------------------------------
-- Cast
-- ---------------------------------------------------------------------------

\set aisyah '''11111111-1111-4111-8111-111111111111'''
\set ravi   '''22222222-2222-4222-8222-222222222222'''
\set siti   '''33333333-3333-4333-8333-333333333333'''
\set intruder '''44444444-4444-4444-8444-444444444444'''

insert into auth.users (id, phone, raw_user_meta_data) values
  (:aisyah,   '+60123000001', '{"name":"Aisyah","avatar_color":-16711936}'),
  (:ravi,     '+60123000002', '{"name":"Ravi","avatar_color":-16776961}'),
  (:siti,     '+60123000003', '{"name":"Siti","avatar_color":-65536}'),
  (:intruder, '+60123000004', '{"name":"Nosy","avatar_color":-1}');

-- The auth trigger should have created a profile for each.
do $$ begin
  perform test.eq((select count(*)::int from public.profiles), 4,
                  'a profile is created for every new auth user');
end $$;

-- Ravi and Siti drive.
update public.profiles set
  is_driver = true,
  driver_rating = 4.9,
  driver_rides_given = 1200,
  driver_verified = true,
  vehicle = '{"make":"Perodua","model":"Bezza","year":2021,"color":"Silver","plate":"WXY 1234","vehicleClass":"economy","seats":4}'::jsonb
where id in (:ravi, :siti);

\echo ''
\echo '== a driver profile requires a vehicle =='
do $$ begin
  perform test.denied(
    format('update public.profiles set is_driver = true where id = %L', '44444444-4444-4444-8444-444444444444'),
    'promoting a user to driver with no vehicle');
end $$;

set role authenticated;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== publishing =='
-- ---------------------------------------------------------------------------

select test.act_as(:aisyah);

insert into public.rides (
  id, passenger_id, passenger_name, passenger_avatar_color, passenger_rating,
  pickup, dropoff, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
  asking_price, recommended_price, distance_km, duration_minutes
) values (
  '99999999-9999-4999-8999-999999999999', :aisyah, 'Aisyah', -16711936, 4.8,
  '{"id":"p1","name":"KLCC","address":"KLCC, KL","coord":{"lat":3.1578,"lng":101.7123},"category":"landmark"}'::jsonb,
  '{"id":"p2","name":"Mid Valley","address":"Mid Valley, KL","coord":{"lat":3.1177,"lng":101.6771},"category":"mall"}'::jsonb,
  3.1578, 101.7123, 3.1177, 101.6771,
  1850, 2000, 8.4, 22
);

do $$ begin
  perform test.denied(
    format('insert into public.rides (passenger_id, passenger_name, passenger_avatar_color,
            passenger_rating, pickup, dropoff, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
            asking_price, recommended_price, distance_km, duration_minutes)
            values (%L, ''Forged'', 0, 5, ''{}''::jsonb, ''{}''::jsonb, 0,0,0,0, 100, 100, 1, 1)',
           '22222222-2222-4222-8222-222222222222'),
    'publishing a ride in somebody else''s name');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== who can see an open order =='
-- ---------------------------------------------------------------------------

select test.act_as(:ravi);
do $$ begin
  perform test.eq((select count(*)::int from public.rides), 1,
                  'a driver sees the open order feed');
end $$;

select test.act_as(:intruder);
do $$ begin
  perform test.eq((select count(*)::int from public.rides), 0,
                  'a non-driver passenger sees nothing but their own rides');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== the passenger owns the fare, and may only raise it =='
-- ---------------------------------------------------------------------------

select test.act_as(:aisyah);

do $$ begin
  perform test.allowed(
    'update public.rides set asking_price = 2100, price_raises = 1
       where id = ''99999999-9999-4999-8999-999999999999''',
    'raising the asking price');

  perform test.denied(
    'update public.rides set asking_price = 900
       where id = ''99999999-9999-4999-8999-999999999999''',
    'lowering the asking price after drivers have bid');

  perform test.denied(
    format('update public.rides set driver_id = %L, status = ''accepted''
             where id = ''99999999-9999-4999-8999-999999999999''',
           '22222222-2222-4222-8222-222222222222'),
    'a passenger assigning themselves a driver');

  perform test.denied(
    'update public.rides set final_price = 100
       where id = ''99999999-9999-4999-8999-999999999999''',
    'a passenger writing the settled fare');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== bidding =='
-- ---------------------------------------------------------------------------

select test.act_as(:ravi);
insert into public.offers (
  id, ride_id, driver_id, driver_name, driver_avatar_color, driver_rating,
  driver_rides_given, vehicle, price, eta_minutes, distance_km, expires_at
) values (
  'aaaaaaaa-0000-4000-8000-000000000001',
  '99999999-9999-4999-8999-999999999999', :ravi, 'Ravi', -16776961, 4.9, 1200,
  (select vehicle from public.profiles where id = :ravi),
  1900, 6, 2.3, now() + interval '90 seconds'
);

select test.act_as(:siti);
insert into public.offers (
  id, ride_id, driver_id, driver_name, driver_avatar_color, driver_rating,
  driver_rides_given, vehicle, price, eta_minutes, distance_km, expires_at
) values (
  'aaaaaaaa-0000-4000-8000-000000000002',
  '99999999-9999-4999-8999-999999999999', :siti, 'Siti', -65536, 4.9, 1200,
  (select vehicle from public.profiles where id = :siti),
  2100, 4, 1.1, now() + interval '90 seconds'
);

do $$ begin
  perform test.denied(
    format('insert into public.offers (ride_id, driver_id, driver_name, driver_avatar_color,
             driver_rating, vehicle, price, eta_minutes, distance_km, expires_at)
             values (''99999999-9999-4999-8999-999999999999'', %L, ''Forged'', 0, 5,
                     ''{}''::jsonb, 1, 1, 1, now() + interval ''1 minute'')',
           '22222222-2222-4222-8222-222222222222'),
    'bidding in another driver''s name');

  perform test.denied(
    'update public.offers set price = 500
       where id = ''aaaaaaaa-0000-4000-8000-000000000002''',
    'editing a live bid instead of withdrawing it');
end $$;

select test.act_as(:aisyah);
do $$ begin
  perform test.denied(
    format('insert into public.offers (ride_id, driver_id, driver_name, driver_avatar_color,
             driver_rating, vehicle, price, eta_minutes, distance_km, expires_at)
             values (''99999999-9999-4999-8999-999999999999'', %L, ''Aisyah'', 0, 5,
                     ''{}''::jsonb, 1, 1, 1, now() + interval ''1 minute'')',
           '11111111-1111-4111-8111-111111111111'),
    'a passenger bidding on their own ride');

  perform test.eq((select count(*)::int from public.offers
                    where ride_id = '99999999-9999-4999-8999-999999999999'), 2,
                  'the passenger sees both bids on their ride');
end $$;

select test.act_as(:ravi);
do $$ begin
  perform test.eq((select count(*)::int from public.offers), 1,
                  'a driver sees only their own bid, not their rivals'''' prices');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== accepting =='
-- ---------------------------------------------------------------------------

select test.act_as(:ravi);
do $$ begin
  perform test.denied(
    'select public.accept_offer(''aaaaaaaa-0000-4000-8000-000000000001'')',
    'a driver accepting their own bid');
end $$;

select test.act_as(:intruder);
do $$ begin
  perform test.denied(
    'select public.accept_offer(''aaaaaaaa-0000-4000-8000-000000000001'')',
    'a stranger accepting a bid on someone else''s ride');
end $$;

select test.act_as(:aisyah);
\o /dev/null
select public.accept_offer('aaaaaaaa-0000-4000-8000-000000000001');
\o

do $$ begin
  perform test.eq((select status::text from public.rides
                    where id = '99999999-9999-4999-8999-999999999999'),
                  'accepted', 'the ride moves to accepted');
  perform test.eq((select final_price from public.rides
                    where id = '99999999-9999-4999-8999-999999999999'),
                  1900, 'the fare settles at the winning bid, not the ask');
  perform test.eq((select driver_id from public.rides
                    where id = '99999999-9999-4999-8999-999999999999'),
                  '22222222-2222-4222-8222-222222222222'::uuid,
                  'the winning driver is assigned');
  perform test.eq((select status::text from public.offers
                    where id = 'aaaaaaaa-0000-4000-8000-000000000002'),
                  'declined', 'the losing bid is declined, not left hanging');

  perform test.denied(
    'select public.accept_offer(''aaaaaaaa-0000-4000-8000-000000000002'')',
    'accepting a second bid on an already-assigned ride');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== bidding closes once a ride is assigned =='
-- ---------------------------------------------------------------------------

select test.act_as(:siti);
do $$ begin
  perform test.denied(
    format('insert into public.offers (ride_id, driver_id, driver_name, driver_avatar_color,
             driver_rating, vehicle, price, eta_minutes, distance_km, expires_at)
             values (''99999999-9999-4999-8999-999999999999'', %L, ''Siti'', 0, 5,
                     ''{}''::jsonb, 1, 1, 1, now() + interval ''1 minute'')',
           '33333333-3333-4333-8333-333333333333'),
    'bidding on a ride that already has a driver');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== the driver drives the trip, but not the fare =='
-- ---------------------------------------------------------------------------

select test.act_as(:ravi);
do $$ begin
  perform test.allowed(
    'update public.rides set status = ''arriving'', driver_lat = 3.15, driver_lng = 101.71
       where id = ''99999999-9999-4999-8999-999999999999''',
    'the driver reporting position and progress');

  perform test.denied(
    'update public.rides set final_price = 9900
       where id = ''99999999-9999-4999-8999-999999999999''',
    'the driver raising the fare after winning the bid');

  perform test.denied(
    'update public.rides set status = ''completed''
       where id = ''99999999-9999-4999-8999-999999999999''',
    'skipping straight from arriving to completed');

  perform test.allowed(
    'update public.rides set status = ''inProgress'', started_at = now()
       where id = ''99999999-9999-4999-8999-999999999999''',
    'starting the trip');

  perform test.allowed(
    'update public.rides set status = ''completed'', completed_at = now()
       where id = ''99999999-9999-4999-8999-999999999999''',
    'completing the trip');
end $$;

select test.act_as(:intruder);
do $$ begin
  perform test.affects_nothing(
    'update public.rides set status = ''cancelled''
       where id = ''99999999-9999-4999-8999-999999999999''',
    'a stranger cancelling a ride they are not part of');
end $$;

select test.act_as(:aisyah);
do $$ begin
  perform test.eq((select status::text from public.rides
                    where id = '99999999-9999-4999-8999-999999999999'),
                  'completed', 'and the ride is left exactly as it was');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== chat is between the two participants and nobody else =='
-- ---------------------------------------------------------------------------

select test.act_as(:ravi);
insert into public.chat_messages (ride_id, sender_id, sender_role, text)
values ('99999999-9999-4999-8999-999999999999', :ravi, 'driver', 'At the north entrance');

select test.act_as(:aisyah);
do $$ begin
  perform test.eq((select count(*)::int from public.chat_messages), 1,
                  'the passenger reads the driver''s message');
end $$;

select test.act_as(:intruder);
do $$ begin
  perform test.eq((select count(*)::int from public.chat_messages), 0,
                  'a stranger cannot read the ride chat');

  perform test.denied(
    format('insert into public.chat_messages (ride_id, sender_id, sender_role, text)
             values (''99999999-9999-4999-8999-999999999999'', %L, ''driver'', ''hello'')',
           '44444444-4444-4444-8444-444444444444'),
    'a stranger posting into the ride chat');

  perform test.denied(
    format('insert into public.chat_messages (ride_id, sender_id, sender_role, text)
             values (''99999999-9999-4999-8999-999999999999'', %L, ''driver'', ''spoofed'')',
           '22222222-2222-4222-8222-222222222222'),
    'posting a message attributed to someone else');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== profiles are not a directory =='
-- ---------------------------------------------------------------------------

select test.act_as(:intruder);
do $$ begin
  perform test.eq((select count(*)::int from public.profiles), 1,
                  'a user with no shared ride sees only their own profile');
end $$;

select test.act_as(:aisyah);
do $$ begin
  -- Aisyah and Ravi shared a ride, so each can see the other. Siti bid and
  -- lost, and is not visible.
  perform test.eq((select count(*)::int from public.profiles), 2,
                  'a ride participant sees their counterparty, and no one else');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== expired bids are swept =='
-- ---------------------------------------------------------------------------

reset role;
select test.act_as(:siti);
set role authenticated;

insert into public.rides (
  id, passenger_id, passenger_name, passenger_avatar_color, passenger_rating,
  pickup, dropoff, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
  asking_price, recommended_price, distance_km, duration_minutes
) values (
  '88888888-8888-4888-8888-888888888888', :siti, 'Siti', -65536, 4.9,
  '{}'::jsonb, '{}'::jsonb, 3.1, 101.7, 3.2, 101.8, 1000, 1000, 5, 15
);

select test.act_as(:ravi);
insert into public.offers (
  id, ride_id, driver_id, driver_name, driver_avatar_color, driver_rating,
  vehicle, price, eta_minutes, distance_km, expires_at
) values (
  'bbbbbbbb-0000-4000-8000-000000000001',
  '88888888-8888-4888-8888-888888888888', :ravi, 'Ravi', -16776961, 4.9,
  '{}'::jsonb, 1000, 5, 1, now() - interval '1 second'
);

reset role;
do $$ begin
  perform test.eq(public.sweep_expired_offers(), 1, 'the sweep expires a stale bid');
  perform test.eq((select status::text from public.offers
                    where id = 'bbbbbbbb-0000-4000-8000-000000000001'),
                  'expired', 'and marks it expired');
end $$;

set role authenticated;
select test.act_as(:siti);
do $$ begin
  perform test.denied(
    'select public.accept_offer(''bbbbbbbb-0000-4000-8000-000000000001'')',
    'accepting a bid that has already expired');
end $$;

reset role;
\echo ''
\echo 'ALL POLICY TESTS PASSED'
