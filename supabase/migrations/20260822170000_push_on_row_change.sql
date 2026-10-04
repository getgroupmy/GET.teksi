-- Call the push function when something happens that someone should hear
-- about while the app is closed.
--
-- The app already knows what it is doing. The notifications worth sending
-- are the ones that happen to you while you are not looking, and those are
-- row changes — which is why this lives in the database rather than in a
-- screen that has to be open to run.
--
-- English only, deliberately and for now. The server does not know the
-- recipient's language, and a closed app cannot render text itself: whatever
-- is sent is what appears on the lock screen. The app ships Malay as a
-- first-class language, so this is an interim and not a conclusion. The ways
-- out, none of them free: a locale column on profiles, which duplicates the
-- ARB strings into SQL; APNs loc-key against Localizable.strings, which
-- needs no server strings but has no Web Push equivalent; or this, said out
-- loud. docs/PUSH.md carries the same note.

-- ---------------------------------------------------------------------------
-- pg_net, if this database has it.
--
-- Guarded the same way the offer sweep guards pg_cron, and for the same
-- reason: supabase/tests/run.sh applies these migrations to a stock
-- PostgreSQL that has neither. A migration that cannot run outside Supabase
-- is a migration the policy suite stops testing.
-- ---------------------------------------------------------------------------

do $$
begin
  begin
    execute 'create extension if not exists pg_net with schema extensions';
  exception when others then
    raise notice
      'pg_net cannot be created here (%), so row changes will not call the '
      'push function. Everything else in this migration still applies.',
      sqlerrm;
  end;
end
$$;

-- ---------------------------------------------------------------------------
-- The dispatcher.
--
-- Reads its two secrets from the vault rather than carrying them: a function
-- body is readable by anything that can read pg_proc, so a service role key
-- in here would be a service role key published to every role that can look
-- at the catalogue.
--
-- Returns quietly when anything it needs is missing — no pg_net, no vault,
-- no secrets configured, no recipient. A ride does not stop because a
-- notification could not be arranged, and this runs inside the transaction
-- that is changing the ride.
-- ---------------------------------------------------------------------------

create or replace function private.send_push(
  p_user_id    uuid,
  p_title      text,
  p_body       text,
  p_path       text default '/',
  p_collapse   text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_url text;
  v_key text;
begin
  if p_user_id is null then return; end if;

  -- to_regproc rather than a try/catch: asking whether the function exists is
  -- cheaper than raising and swallowing an exception on every row change.
  if to_regproc('net.http_post') is null then return; end if;
  if to_regclass('vault.decrypted_secrets') is null then return; end if;

  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1'
    into v_url using 'push_function_url';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1'
    into v_key using 'push_service_role_key';

  if v_url is null or v_key is null then return; end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'content-type', 'application/json',
      'authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'user_id', p_user_id,
      'title', p_title,
      'body', p_body,
      'path', p_path,
      'collapse_id', p_collapse
    )
  );
end
$$;

revoke all on function private.send_push(uuid, text, text, text, text)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- A bid arriving, for the passenger who is not watching the screen.
-- ---------------------------------------------------------------------------

create or replace function private.push_on_offer()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_passenger uuid;
begin
  select passenger_id into v_passenger from public.rides where id = new.ride_id;

  perform private.send_push(
    v_passenger,
    'A driver bid on your ride',
    coalesce(new.driver_name, 'A driver') || ' offered RM'
      || trim(to_char(new.price / 100.0, 'FM999990.00')) || '.',
    '/ride/' || new.ride_id,
    -- One notification per ride, replaced as bids arrive, rather than a
    -- column of them on the lock screen.
    'offers:' || new.ride_id
  );
  return null;
end
$$;

create trigger offers_push_passenger
  after insert on public.offers
  for each row execute function private.push_on_offer();

-- ---------------------------------------------------------------------------
-- The ride moving on, for whichever side is not the one that moved it.
-- ---------------------------------------------------------------------------

create or replace function private.push_on_ride_status()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.status is not distinct from old.status then return null; end if;

  case new.status
    when 'accepted' then
      perform private.send_push(
        new.driver_id,
        'Your offer was accepted',
        'Head to ' || coalesce(new.pickup ->> 'name', 'the pickup point') || '.',
        '/ride/' || new.id,
        'ride:' || new.id);
    when 'arriving' then
      perform private.send_push(
        new.passenger_id,
        'Your driver is on the way',
        coalesce(new.driver_name, 'Your driver') || ' is heading to you.',
        '/ride/' || new.id,
        'ride:' || new.id);
    when 'waiting' then
      perform private.send_push(
        new.passenger_id,
        'Your driver has arrived',
        coalesce(new.driver_name, 'Your driver') || ' is waiting at the pickup point.',
        '/ride/' || new.id,
        'ride:' || new.id);
    when 'completed' then
      perform private.send_push(
        new.passenger_id,
        'Trip completed',
        'Thanks for riding. Tap to rate your trip.',
        '/rate/' || new.id,
        'ride:' || new.id);
    when 'cancelled' then
      -- To whoever did not cancel it.
      perform private.send_push(
        case when new.cancelled_by = 'passenger' then new.driver_id
             else new.passenger_id end,
        'Trip cancelled',
        coalesce(new.cancel_reason, 'The trip was cancelled.'),
        '/',
        'ride:' || new.id);
    else
      null;
  end case;
  return null;
end
$$;

create trigger rides_push_status
  after update on public.rides
  for each row execute function private.push_on_ride_status();
