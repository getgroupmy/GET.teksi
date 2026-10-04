-- Move the money to the server.
--
-- Until now each device kept its own wallet: on completion the passenger's app
-- debited the passenger and the driver's app credited the driver, each
-- computing its own half. Two consequences, and the second is the serious one.
--
-- A balance that lives in SharedPreferences does not survive a reinstall and
-- does not follow the user to a second device.
--
-- And a client that writes its own balance is not a wallet. The driver's app
-- decided what the driver earned. Nothing stopped a modified build from
-- crediting itself any number it liked, because the number never left the
-- device that invented it.
--
-- So: an append-only ledger the client may read and may never write, a balance
-- derived from it, and settlement performed by the database at the moment a
-- ride completes — not requested by either participant.

create type public.txn_kind as enum (
  'ridePayment', 'rideEarning', 'topup', 'payout', 'tip', 'promo'
);

create table public.wallet_transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  kind        public.txn_kind not null,
  -- Signed, in sen: positive is money in, negative is money out. Zero would be
  -- a row that means nothing.
  amount      integer not null check (amount <> 0),
  description text not null,
  ride_id     uuid references public.rides (id) on delete set null,
  created_at  timestamptz not null default now()
);

create index wallet_transactions_user_idx
  on public.wallet_transactions (user_id, created_at desc);

-- Idempotence by construction rather than by careful coding: a given user can
-- have at most one row of a given kind for a given ride, so a settlement that
-- runs twice inserts nothing the second time.
create unique index wallet_transactions_one_per_ride_role_idx
  on public.wallet_transactions (ride_id, user_id, kind)
  where ride_id is not null;

-- The balance is derived state, cached here so reading it is not a sum over
-- the user's whole history. The ledger remains the source of truth: this
-- column can be rebuilt from it at any time, and never the other way round.
alter table public.profiles
  add column wallet_balance integer not null default 0;

create or replace function private.apply_wallet_delta()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.profiles
     set wallet_balance = wallet_balance + new.amount
   where id = new.user_id;
  return new;
end;
$$;

create trigger wallet_transactions_apply_delta
  after insert on public.wallet_transactions
  for each row execute function private.apply_wallet_delta();

-- The ledger is append-only. Without this an owner-level mistake could edit
-- history and leave the cached balance describing something that never
-- happened; with it, a correction has to be a new row, which is what a
-- correction is.
create or replace function private.forbid_ledger_rewrite()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  raise exception 'the wallet ledger is append-only; post a correcting entry instead';
end;
$$;

create trigger wallet_transactions_append_only
  before update or delete on public.wallet_transactions
  for each row execute function private.forbid_ledger_rewrite();

-- The platform's cut, mirroring lib/services/pricing.dart exactly. Both sides
-- are pinned to the same worked examples by tests, because a fee that differs
-- between the app's arithmetic and the database's is a fee nobody can explain
-- to a driver.
create or replace function private.driver_net(p_fare integer)
returns integer
language sql
immutable
set search_path = pg_catalog, pg_temp
as $$
  select round(p_fare * 0.901::numeric)::integer;
$$;

-- Settlement runs as a consequence of the ride completing, not as something
-- either side asks for. Neither participant can invoke it, skip it, or choose
-- the amounts: by the time this fires, final_price was already set by
-- accept_offer from the winning bid.
create or replace function private.settle_completed_ride()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.status = 'completed'
     and old.status is distinct from 'completed'
     and new.final_price is not null
     and new.driver_id is not null
  then
    -- Cash and card settle outside the wallet; only a wallet ride moves a
    -- balance here.
    if new.payment_method = 'wallet' then
      insert into public.wallet_transactions (user_id, kind, amount, description, ride_id)
      values (
        new.passenger_id, 'ridePayment', -new.final_price,
        'Ride to ' || coalesce(new.dropoff ->> 'name', 'destination'), new.id
      )
      on conflict do nothing;
    end if;

    insert into public.wallet_transactions (user_id, kind, amount, description, ride_id)
    values (
      new.driver_id, 'rideEarning', private.driver_net(new.final_price),
      'Trip from ' || coalesce(new.pickup ->> 'name', 'pickup'), new.id
    )
    on conflict do nothing;
  end if;

  -- A tip is added after the fact, when the passenger rates the trip. It moves
  -- whole: the platform takes no cut of it.
  if new.tip is not null and new.tip > 0 and old.tip is distinct from new.tip
     and new.driver_id is not null
  then
    insert into public.wallet_transactions (user_id, kind, amount, description, ride_id)
    values (new.passenger_id, 'tip', -new.tip, 'Tip for your driver', new.id)
    on conflict do nothing;

    insert into public.wallet_transactions (user_id, kind, amount, description, ride_id)
    values (new.driver_id, 'tip', new.tip, 'Tip from your passenger', new.id)
    on conflict do nothing;
  end if;

  return new;
end;
$$;

create trigger rides_settle_on_completion
  after update on public.rides
  for each row execute function private.settle_completed_ride();

-- ---------------------------------------------------------------------------
-- Row-level security
--
-- A user reads their own ledger and writes none of it. There is deliberately
-- no insert, update or delete policy: with RLS enabled and no policy, those
-- are denied outright. Every row in this table is written by the database as a
-- consequence of something that actually happened.
-- ---------------------------------------------------------------------------

alter table public.wallet_transactions enable row level security;

create policy "own ledger is readable"
  on public.wallet_transactions for select
  to authenticated
  using (user_id = auth.uid());

-- Topping up needs a payment provider to have taken real money first. Until
-- one is wired in there is no honest way for a balance to grow, and an RPC
-- that let a client credit itself would undo the entire point of this file.
