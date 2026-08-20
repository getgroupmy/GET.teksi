-- Take the schema's internals off the public API.
--
-- Every function in `public` is published by PostgREST as an RPC endpoint.
-- That is right for `accept_offer`, which the client is meant to call, and
-- wrong for everything else here: the helpers exist to be called *by* policies
-- and triggers, not by whoever holds a publishable key.
--
-- One of them was a real leak. `ride_bid_context` is SECURITY DEFINER, so it
-- reads with the owner's privileges — which is the point, since the offer
-- guard has to see a ride the bidding driver may not be allowed to read. But
-- published as `/rest/v1/rpc/ride_bid_context`, it would hand any signed-in
-- caller the passenger id and status of *any* ride id they cared to try. The
-- table policies would have refused that same read.
--
-- Moving the helpers into a schema PostgREST does not expose keeps them
-- callable from policies and triggers while removing the endpoint. Policy
-- expressions are stored as parsed trees referencing the function's OID, so
-- they follow it across the move; `guard_offer_write` resolves its call by
-- name at runtime and is recreated below to match.

create schema if not exists private;

-- Policies and invoker-side triggers run as the caller, so the signed-in role
-- still needs to reach these — it just cannot address them over HTTP.
grant usage on schema private to authenticated;

-- Two separate grants have to come off, and missing either leaves the function
-- callable while looking revoked:
--
--   * Postgres grants EXECUTE to PUBLIC on every function it creates, and
--     `anon`/`authenticated` inherit through that.
--   * A Supabase project also carries default privileges granting EXECUTE on
--     new functions in `public` to those roles *directly*.
--
-- So each revoke names PUBLIC and both roles, and anything that should stay
-- callable is granted back explicitly afterwards.

alter function public.is_driver() set schema private;
alter function public.is_ride_participant(uuid) set schema private;
alter function public.ride_bid_context(uuid) set schema private;

revoke execute on function private.is_driver() from public, anon, authenticated;
revoke execute on function private.is_ride_participant(uuid) from public, anon, authenticated;
revoke execute on function private.ride_bid_context(uuid) from public, anon, authenticated;

grant execute on function private.is_driver() to authenticated;
grant execute on function private.is_ride_participant(uuid) to authenticated;
grant execute on function private.ride_bid_context(uuid) to authenticated;

-- plpgsql resolves `private.ride_bid_context` when the trigger fires rather
-- than when it is defined, so this body has to name the new schema.
create or replace function public.guard_offer_write()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  ctx record;
begin
  if auth.uid() is null or public.is_privileged_writer() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    select * into ctx from private.ride_bid_context(new.ride_id);
    if ctx.passenger is null then
      raise exception 'no such ride';
    end if;
    if ctx.ride_status <> 'searching' then
      raise exception 'bidding has closed on this ride';
    end if;
    if ctx.passenger = new.driver_id then
      raise exception 'a passenger may not bid on their own ride';
    end if;
    if new.status <> 'pending' then
      raise exception 'a new bid starts pending';
    end if;
    return new;
  end if;

  if new.price <> old.price or new.ride_id <> old.ride_id or new.driver_id <> old.driver_id then
    raise exception 'a bid is immutable; withdraw and re-bid instead';
  end if;
  if new.status <> old.status and not (old.status = 'pending' and new.status = 'withdrawn') then
    raise exception 'a driver may only withdraw a pending bid';
  end if;
  return new;
end;
$$;

-- A trigger function cannot be invoked over the API anyway — Postgres refuses
-- to call one outside a trigger — but there is no reason for the grant to
-- exist, and an endpoint that only ever returns an error is still noise.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.touch_updated_at() from public, anon, authenticated;

-- The sweep is for a scheduled job running as the service role. Letting any
-- caller settle other people's expired bids on demand is not a capability the
-- client needs.
revoke execute on function public.sweep_expired_offers() from public, anon, authenticated;

-- Accepting a bid is the one RPC the client is meant to call, and only ever
-- while signed in: the function's first act is to compare auth.uid() against
-- the ride's passenger, which is null for anon. Drop PUBLIC's blanket grant,
-- then hand it back to the signed-in role alone.
revoke execute on function public.accept_offer(uuid) from public, anon, authenticated;
grant execute on function public.accept_offer(uuid) to authenticated;

-- Unpinned search_path on a function that runs inside every update: a role
-- with a mutable path could otherwise shadow what `now()` resolves to.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.touch_updated_at() from public, anon, authenticated;
