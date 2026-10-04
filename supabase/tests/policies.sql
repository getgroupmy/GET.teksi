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
  asking_price, recommended_price, distance_km, duration_minutes, payment_method
) values (
  '99999999-9999-4999-8999-999999999999', :aisyah, 'Aisyah', -16711936, 4.8,
  '{"id":"p1","name":"KLCC","address":"KLCC, KL","coord":{"lat":3.1578,"lng":101.7123},"category":"landmark"}'::jsonb,
  '{"id":"p2","name":"Mid Valley","address":"Mid Valley, KL","coord":{"lat":3.1177,"lng":101.6771},"category":"mall"}'::jsonb,
  3.1578, 101.7123, 3.1177, 101.6771,
  1850, 2000, 8.4, 22, 'wallet'
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

-- ---------------------------------------------------------------------------
\echo ''
\echo '== the wallet is the database''s to write, not the client''s =='
-- ---------------------------------------------------------------------------

set role authenticated;
select test.act_as(:aisyah);

do $$ begin
  -- The completed ride earlier in this script was a wallet ride, so settlement
  -- has already run. Nobody asked it to: it happened because the ride
  -- completed.
  perform test.eq(
    (select amount from public.wallet_transactions
      where ride_id = '99999999-9999-4999-8999-999999999999'
        and user_id = '11111111-1111-4111-8111-111111111111'),
    -1900, 'the passenger was debited the settled fare, not the asking price');

  perform test.eq(
    (select wallet_balance from public.profiles
      where id = '11111111-1111-4111-8111-111111111111'),
    -1900, 'and the cached balance followed the ledger');

  -- The driver's earning is the driver's to see.
  perform test.eq((select count(*)::int from public.wallet_transactions), 1,
                  'a user reads their own ledger and no one else''s');

  perform test.denied(
    format('insert into public.wallet_transactions (user_id, kind, amount, description)
             values (%L, ''topup'', 1000000, ''free money'')',
           '11111111-1111-4111-8111-111111111111'),
    'a client crediting its own wallet');
end $$;

select test.act_as(:ravi);
do $$ begin
  perform test.eq(
    (select amount from public.wallet_transactions
      where ride_id = '99999999-9999-4999-8999-999999999999'
        and user_id = '22222222-2222-4222-8222-222222222222'),
    1712, 'the driver was credited the fare net of commission');

  -- Two independent layers, so two assertions. To the client the rows are
  -- simply not there to update: no policy grants UPDATE, so the statement
  -- matches nothing and reports success having changed nothing.
  perform test.affects_nothing(
    'update public.wallet_transactions set amount = 999999',
    'a client rewriting a ledger entry');
end $$;

reset role;

-- And behind RLS, where rows *are* visible, the append-only trigger refuses.
-- Without this an owner-level mistake could edit history and leave the cached
-- balance describing something that never happened.
do $$ begin
  perform test.denied(
    'update public.wallet_transactions set amount = 999999',
    'rewriting a ledger entry as the owner');
  perform test.denied(
    'delete from public.wallet_transactions',
    'deleting ledger history');
end $$;

set role authenticated;

reset role;

-- A cash ride pays the driver in cash, at the kerb. Settling it through the
-- wallet as well would pay them twice.
do $$
declare
  cash_ride uuid;
  ledger_before integer := (select count(*)::int from public.wallet_transactions);
begin
  insert into public.rides (
    passenger_id, passenger_name, passenger_avatar_color, passenger_rating,
    pickup, dropoff, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
    asking_price, recommended_price, distance_km, duration_minutes,
    payment_method, status, driver_id, driver_name, final_price
  ) values (
    '33333333-3333-4333-8333-333333333333', 'Siti', 0, 4.9,
    '{}'::jsonb, '{}'::jsonb, 3.1, 101.7, 3.2, 101.8, 1000, 1000, 5, 15,
    'cash', 'inProgress', '22222222-2222-4222-8222-222222222222', 'Ravi', 1000
  ) returning id into cash_ride;

  update public.rides set status = 'completed', completed_at = now()
   where id = cash_ride;

  perform test.eq(
    (select count(*)::int from public.wallet_transactions
      where ride_id = cash_ride and kind = 'ridePayment'),
    0, 'a cash ride does not debit the passenger''s wallet');

  perform test.eq(
    (select amount from public.wallet_transactions
      where ride_id = cash_ride and kind = 'rideEarning'),
    901, 'but the driver''s earning is still recorded');

  -- Settlement must be idempotent: a second completion writes nothing.
  update public.rides set completed_at = now() where id = cash_ride;
  perform test.eq(
    (select count(*)::int from public.wallet_transactions),
    ledger_before + 1, 'settling the same ride twice posts one entry, not two');
end $$;

-- The fee has to mean the same thing in Dart and in SQL, or a driver is shown
-- one number and paid another. These are the values lib/services/pricing.dart
-- produces; test/pricing_test.dart pins the same list from the other side.
do $$ begin
  perform test.eq(private.driver_net(500),   451,   'driver_net(500) matches Dart');
  perform test.eq(private.driver_net(1005),  906,   'driver_net(1005) matches Dart');
  perform test.eq(private.driver_net(1234),  1112,  'driver_net(1234) matches Dart');
  perform test.eq(private.driver_net(1900),  1712,  'driver_net(1900) matches Dart');
  perform test.eq(private.driver_net(4700),  4235,  'driver_net(4700) matches Dart');
  perform test.eq(private.driver_net(99999), 90099, 'driver_net(99999) matches Dart');
end $$;

\echo ''
\echo '== the schema internals are not an API =='

-- PostgREST publishes every function in `public` as an RPC endpoint. The
-- helpers exist to be called by policies and triggers; if one reappears here,
-- it is reachable over HTTP again — and ride_bid_context in particular reads
-- with the owner's privileges, so exposing it hands out rides the caller's own
-- policies would refuse them.
do $$
declare
  leaked text;
begin
  select string_agg(p.proname, ', ')
    into leaked
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in ('ride_bid_context', 'is_driver', 'is_ride_participant');
  if leaked is not null then
    raise exception 'SECURITY FAILURE: internal helper(s) exposed in public: %', leaked;
  end if;
  raise notice '  ok: the helpers live outside the exposed schema';
end $$;

do $$ begin
  perform test.eq(
    has_function_privilege('authenticated', 'public.sweep_expired_offers()', 'EXECUTE'),
    false, 'a client cannot settle other people''s expired bids');
  perform test.eq(
    has_function_privilege('authenticated', 'public.accept_offer(uuid)', 'EXECUTE'),
    true, 'but a signed-in client can still accept a bid');
  perform test.eq(
    has_function_privilege('anon', 'public.accept_offer(uuid)', 'EXECUTE'),
    false, 'and a signed-out one cannot');
end $$;

-- ---------------------------------------------------------------------------
\echo ''
\echo '== a profile is not a form you fill in about yourself =='
-- ---------------------------------------------------------------------------
-- `own profile is writable` is a rule about the row: id = auth.uid(). It says
-- nothing about columns, because row-level security cannot. Every one of these
-- succeeded before the guard trigger existed, and the first is the one that
-- undoes the entire server-side wallet: the ledger is append-only and
-- unwritable, and the balance the wallet screen actually reads is a column on
-- this table.

-- Note the `set role`. The suite leaves the role as the table owner after the
-- settlement tests, and every guard in this schema steps aside for a
-- privileged writer — correctly, since that is how the database writes to
-- itself. A test appended here without this line runs as the owner, is waved
-- through, and reports that a client can do something no client could. This
-- block failed exactly that way when it was first written.
set role authenticated;

-- The intruder is the right persona for these: every column still holds its
-- default, so each attempt below is a real change rather than a write of the
-- value that was already there. Two of these passed vacuously at first for
-- exactly that reason — asserting a denial of something that was not a change.
select test.act_as(:intruder);

do $$
declare
  who constant text := '44444444-4444-4444-8444-444444444444';
begin
  perform test.denied(
    format('update public.profiles set wallet_balance = 99999999 where id = %L', who),
    'crediting your own wallet balance');

  perform test.denied(
    format('update public.profiles set driver_verified = true where id = %L', who),
    'marking yourself a verified driver');

  perform test.denied(
    format('update public.profiles set driver_rating = 5.00 where id = %L', who),
    'awarding yourself a driver rating you have never earned');

  perform test.denied(
    format('update public.profiles set rating = 4.00 where id = %L', who),
    'editing your own passenger rating');

  perform test.denied(
    format('update public.profiles set driver_rides_given = 9000 where id = %L', who),
    'inventing nine thousand completed trips');

  perform test.denied(
    format('update public.profiles set rides_taken = 9000 where id = %L', who),
    'inventing nine thousand trips taken');

  perform test.denied(
    format('update public.profiles set phone = %L where id = %L', '+60123999999', who),
    'moving your profile onto another phone number');
end $$;

-- The guard must not have made the profile read-only. What is left is what
-- genuinely belongs to the account holder.
do $$
declare
  who constant text := '44444444-4444-4444-8444-444444444444';
begin
  perform test.allowed(
    format('update public.profiles set name = %L, email = %L, avatar_color = %s where id = %L',
           'Nosy Parker', 'nosy@example.com', -12303292, who),
    'changing your own name, email and colour');

  -- Onboarding as a driver is a client write on purpose: this build verifies
  -- documents automatically. What it may not do is claim the verification.
  perform test.allowed(
    format($q$update public.profiles
              set is_driver = true,
                  vehicle = '{"make":"Proton","model":"Saga","year":2020,"color":"Blue","plate":"WAA 1122","vehicleClass":"economy","seats":4}'::jsonb
            where id = %L$q$, who),
    'declaring yourself a driver with a vehicle');
end $$;

-- And the settlement path still works, which is the point of the guard being
-- invoker-side: with no auth.uid() the database is writing to itself.
reset role;
do $$
declare
  before_balance integer;
  after_balance  integer;
begin
  select wallet_balance into before_balance
    from public.profiles where id = '44444444-4444-4444-8444-444444444444';
  insert into public.wallet_transactions (user_id, kind, amount, description)
  values ('44444444-4444-4444-8444-444444444444', 'topup', 500, 'guard check');
  select wallet_balance into after_balance
    from public.profiles where id = '44444444-4444-4444-8444-444444444444';
  perform test.eq(after_balance - before_balance, 500,
    'the ledger still moves the balance the client cannot touch');
end $$;
set role authenticated;

\echo ''
\echo 'ALL POLICY TESTS PASSED'
