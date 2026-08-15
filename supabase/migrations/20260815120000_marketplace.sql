-- GET.teksi marketplace schema.
--
-- Scope: this migration covers the parts of the app that must be shared
-- between devices — identity, ride orders, driver bids, in-ride chat and live
-- driver positions. The wallet ledger, promo codes, saved places and the
-- notification feed remain on-device for now; they are single-user state and
-- nothing in the marketplace depends on them.
--
-- The design principle throughout: the client is not trusted. Row-level
-- security decides who may see a row, and BEFORE UPDATE triggers decide which
-- columns each side may change. Accepting a bid — the one genuinely racy
-- operation in the whole model — is a single locked server-side function, not
-- a client-issued UPDATE.

-- ---------------------------------------------------------------------------
-- Enums. These mirror the Dart enums exactly; `.name` on the client is the
-- wire format, so adding a value means adding it in both places.
-- ---------------------------------------------------------------------------

create type public.service_type as enum ('city', 'intercity', 'delivery', 'freight', 'moto');
create type public.vehicle_class as enum ('economy', 'comfort', 'xl');
create type public.payment_method as enum ('cash', 'card', 'wallet');
create type public.party_role as enum ('passenger', 'driver');
create type public.cancelled_by as enum ('passenger', 'driver', 'system');
create type public.offer_status as enum ('pending', 'accepted', 'declined', 'expired', 'withdrawn');
create type public.ride_status as enum (
  'searching', 'accepted', 'arriving', 'waiting', 'inProgress', 'completed', 'cancelled'
);
-- `draft` is deliberately absent: a draft is a composing UI state that lives
-- only on the passenger's device, and publishing it is what creates the row.

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  phone          text        not null,
  name           text        not null,
  email          text,
  avatar_color   integer     not null,
  rating         numeric(3, 2) not null default 5.00 check (rating between 0 and 5),
  rides_taken    integer     not null default 0 check (rides_taken >= 0),
  is_driver      boolean     not null default false,
  -- Denormalised driver facts. Kept here rather than in a separate table
  -- because every offer and every ride card needs them, and a join per bid on
  -- a live-updating list is the kind of cost that shows up as jank.
  driver_rating       numeric(3, 2) check (driver_rating between 0 and 5),
  driver_rides_given  integer default 0 check (driver_rides_given >= 0),
  driver_verified     boolean not null default false,
  vehicle             jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  -- A driver is only a driver with a vehicle to drive.
  constraint driver_needs_vehicle check (not is_driver or vehicle is not null)
);

comment on column public.profiles.vehicle is
  'Vehicle object as the Dart model serialises it: make, model, year, color, plate, vehicleClass, seats.';

-- ---------------------------------------------------------------------------
-- Rides
-- ---------------------------------------------------------------------------

create table public.rides (
  id            uuid primary key default gen_random_uuid(),
  passenger_id  uuid not null references public.profiles (id) on delete cascade,

  -- Denormalised passenger identity, frozen at publish time. A driver browsing
  -- open orders can read these without being granted read access to every
  -- passenger's profile row.
  passenger_name         text not null,
  passenger_avatar_color integer not null,
  passenger_rating       numeric(3, 2) not null,

  service        public.service_type  not null default 'city',
  vehicle_class  public.vehicle_class not null default 'economy',

  -- Places carry a name and address alongside the coordinate, so they are
  -- stored whole. The coordinates are lifted into their own columns because
  -- the "open orders near me" query has to filter on them.
  pickup    jsonb not null,
  dropoff   jsonb not null,
  stop      jsonb,
  pickup_lat   double precision not null,
  pickup_lng   double precision not null,
  dropoff_lat  double precision not null,
  dropoff_lng  double precision not null,

  -- All money is in sen (1/100 MYR), integer, never floating point.
  asking_price       integer not null check (asking_price > 0),
  recommended_price  integer not null check (recommended_price > 0),
  final_price        integer check (final_price > 0),
  price_raises       integer not null default 0 check (price_raises >= 0),

  distance_km       double precision not null check (distance_km >= 0),
  duration_minutes  integer not null check (duration_minutes >= 0),
  payment_method    public.payment_method not null default 'cash',
  passenger_count   integer not null default 1 check (passenger_count between 1 and 8),
  comment           text,
  options           text[] not null default '{}',

  status      public.ride_status not null default 'searching',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  driver_id            uuid references public.profiles (id) on delete set null,
  driver_name          text,
  driver_avatar_color  integer,
  driver_rating        numeric(3, 2),
  driver_vehicle       jsonb,
  driver_lat           double precision,
  driver_lng           double precision,
  driver_bearing       double precision,

  accepted_at   timestamptz,
  arrived_at    timestamptz,
  started_at    timestamptz,
  completed_at  timestamptz,
  cancelled_at  timestamptz,
  cancelled_by  public.cancelled_by,
  cancel_reason text,

  route_geometry jsonb,
  rating_by_passenger jsonb,
  rating_by_driver    jsonb,
  tip integer check (tip >= 0),

  -- A driver may not also be the passenger. Without this, the simulation or a
  -- malicious client could self-deal a ride to farm ratings.
  constraint driver_is_not_passenger check (driver_id is null or driver_id <> passenger_id),
  -- Every state past `searching` has a driver attached.
  constraint assigned_states_have_a_driver check (
    status in ('searching', 'cancelled') or driver_id is not null
  ),
  constraint completed_has_a_price check (status <> 'completed' or final_price is not null)
);

-- The driver's order feed: open rides, newest first. Partial, because a
-- driver never browses anything that is not still searching, and this keeps
-- the index small no matter how much ride history accumulates.
create index rides_open_feed_idx
  on public.rides (created_at desc)
  where status = 'searching';

create index rides_passenger_idx on public.rides (passenger_id, created_at desc);
create index rides_driver_idx    on public.rides (driver_id, created_at desc)
  where driver_id is not null;

-- ---------------------------------------------------------------------------
-- Offers — a driver's bid on a ride. The heart of the model.
-- ---------------------------------------------------------------------------

create table public.offers (
  id         uuid primary key default gen_random_uuid(),
  ride_id    uuid not null references public.rides (id) on delete cascade,
  driver_id  uuid not null references public.profiles (id) on delete cascade,

  driver_name         text not null,
  driver_avatar_color integer not null,
  driver_rating       numeric(3, 2) not null,
  driver_rides_given  integer not null default 0,
  vehicle             jsonb not null,

  price          integer not null check (price > 0),
  eta_minutes    integer not null check (eta_minutes >= 0),
  distance_km    double precision not null check (distance_km >= 0),
  status         public.offer_status not null default 'pending',
  -- True when the driver took the passenger's asking price unchanged, which
  -- the UI surfaces differently from a counter-bid.
  matched_asking_price boolean not null default false,

  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null,

  -- One live bid per driver per ride. A driver who wants a different price
  -- withdraws and re-bids, which keeps the passenger's list unambiguous.
  constraint one_bid_per_driver_per_ride unique (ride_id, driver_id)
);

create index offers_ride_idx   on public.offers (ride_id, created_at desc);
create index offers_driver_idx on public.offers (driver_id, created_at desc);
-- Drives the expiry sweep without scanning settled bids.
create index offers_pending_expiry_idx on public.offers (expires_at)
  where status = 'pending';

-- ---------------------------------------------------------------------------
-- Chat
-- ---------------------------------------------------------------------------

create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  ride_id     uuid not null references public.rides (id) on delete cascade,
  sender_id   uuid not null references public.profiles (id) on delete cascade,
  sender_role public.party_role not null,
  text        text not null check (length(btrim(text)) between 1 and 1000),
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);

create index chat_messages_ride_idx on public.chat_messages (ride_id, created_at);

-- ---------------------------------------------------------------------------
-- Live driver positions
--
-- One row per driver, updated in place rather than appended. Position is the
-- highest-frequency write in the system and none of its history is ever read,
-- so an append-only table would be pure garbage generation.
-- ---------------------------------------------------------------------------

create table public.driver_locations (
  driver_id  uuid primary key references public.profiles (id) on delete cascade,
  lat        double precision not null,
  lng        double precision not null,
  bearing    double precision not null default 0,
  online     boolean not null default true,
  updated_at timestamptz not null default now()
);

create index driver_locations_online_idx on public.driver_locations (updated_at desc)
  where online;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger rides_touch before update on public.rides
  for each row execute function public.touch_updated_at();

-- Is the caller a participant in this ride? Used by the chat policies.
-- SECURITY DEFINER so the check itself does not recurse through the rides
-- policies, and search_path is pinned so it cannot be hijacked.
create or replace function public.is_ride_participant(p_ride_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.rides r
    where r.id = p_ride_id
      and auth.uid() in (r.passenger_id, r.driver_id)
  );
$$;

create or replace function public.is_driver()
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select coalesce((select p.is_driver from public.profiles p where p.id = auth.uid()), false);
$$;

-- New auth user -> profile row. Phone-first: Supabase phone auth puts the
-- number on auth.users, and the rest arrives from the profile setup screen.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, phone, name, avatar_color)
  values (
    new.id,
    coalesce(new.phone, new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'name', 'Rider'),
    coalesce((new.raw_user_meta_data ->> 'avatar_color')::integer, -12303292)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Column-level guards
--
-- RLS answers "may this user touch this row". It cannot answer "may this user
-- change *this column* of this row", which is exactly the question the
-- marketplace turns on: a passenger must not be able to write their own
-- final_price, and a driver must not be able to move the fare after winning
-- the bid. These triggers close that gap.
-- ---------------------------------------------------------------------------

-- Is this write coming from trusted server-side code rather than from a
-- client? `accept_offer` and the expiry sweep are SECURITY DEFINER and so run
-- as the table owner, and they make exactly the changes the guards exist to
-- forbid a client from making. Membership of the owning role is the test,
-- rather than a session flag, because PostgREST gives a client no way to
-- grant itself a role.
--
-- This only works because the guards below are SECURITY INVOKER: inside a
-- DEFINER function `current_user` is the definer no matter who called it, so
-- a DEFINER guard could not tell a client from the server.
create or replace function public.is_privileged_writer()
returns boolean
language sql
stable
set search_path = public, pg_temp
as $$
  select pg_has_role(
    current_user,
    (select relowner from pg_class where oid = 'public.rides'::regclass),
    'MEMBER'
  );
$$;

-- Reads the bidding-relevant facts about a ride with the owner's privileges,
-- so the offer guard can check them without granting the bidding driver
-- broader read access than the policies allow.
create or replace function public.ride_bid_context(p_ride_id uuid)
returns table (ride_status public.ride_status, passenger uuid)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select r.status, r.passenger_id from public.rides r where r.id = p_ride_id;
$$;

create or replace function public.guard_ride_update()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  actor uuid := auth.uid();
begin
  if actor is null or public.is_privileged_writer() then
    return new;
  end if;

  if new.id <> old.id or new.passenger_id <> old.passenger_id then
    raise exception 'ride identity is immutable';
  end if;

  if actor = old.passenger_id then
    -- The passenger owns the fare and may only ever raise it. Lowering the
    -- ask after drivers have bid against it would be a bait-and-switch.
    if new.asking_price < old.asking_price then
      raise exception 'the asking price may only be raised';
    end if;
    if new.driver_id is distinct from old.driver_id
       or new.final_price is distinct from old.final_price then
      raise exception 'a driver is assigned by accept_offer(), not by update';
    end if;
    -- Everything else the passenger may do to a live ride is cancel it.
    if new.status <> old.status and new.status <> 'cancelled' then
      raise exception 'a passenger may only cancel; the driver drives the trip state';
    end if;
    return new;
  end if;

  if actor = old.driver_id then
    if new.asking_price <> old.asking_price
       or new.final_price is distinct from old.final_price
       or new.tip is distinct from old.tip then
      raise exception 'the fare is settled at acceptance and is not driver-writable';
    end if;
    if new.driver_id is distinct from old.driver_id then
      raise exception 'a driver may not reassign a ride';
    end if;
    -- The driver advances the trip forwards, or cancels out of it.
    if new.status <> old.status and not (
      (old.status = 'accepted'   and new.status in ('arriving', 'cancelled')) or
      (old.status = 'arriving'   and new.status in ('waiting', 'inProgress', 'cancelled')) or
      (old.status = 'waiting'    and new.status in ('inProgress', 'cancelled')) or
      (old.status = 'inProgress' and new.status = 'completed')
    ) then
      raise exception 'illegal ride transition % -> %', old.status, new.status;
    end if;
    return new;
  end if;

  raise exception 'only the passenger or the assigned driver may update a ride';
end;
$$;

create trigger rides_guard_update
  before update on public.rides
  for each row execute function public.guard_ride_update();

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
    select * into ctx from public.ride_bid_context(new.ride_id);
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

  -- The only update a driver may make to their own live bid is withdrawing
  -- it. Acceptance and rejection are the passenger's, via accept_offer().
  if new.price <> old.price or new.ride_id <> old.ride_id or new.driver_id <> old.driver_id then
    raise exception 'a bid is immutable; withdraw and re-bid instead';
  end if;
  if new.status <> old.status and not (old.status = 'pending' and new.status = 'withdrawn') then
    raise exception 'a driver may only withdraw a pending bid';
  end if;
  return new;
end;
$$;

create trigger offers_guard_write
  before insert or update on public.offers
  for each row execute function public.guard_offer_write();

-- ---------------------------------------------------------------------------
-- accept_offer — the one operation that must be atomic
--
-- Two drivers' bids can be accepted in the same instant only if the check and
-- the write are separable. They are not: the ride row is locked first, so the
-- second caller finds a ride that is no longer searching and is rejected.
-- ---------------------------------------------------------------------------

create or replace function public.accept_offer(p_offer_id uuid)
returns public.rides
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  the_offer public.offers;
  the_ride  public.rides;
begin
  select * into the_offer from public.offers where id = p_offer_id;
  if the_offer.id is null then
    raise exception 'no such offer';
  end if;

  -- Lock the ride before reading its status, so a concurrent accept blocks
  -- here rather than racing past the check below.
  select * into the_ride from public.rides where id = the_offer.ride_id for update;

  if the_ride.passenger_id <> auth.uid() then
    raise exception 'only the passenger may accept a bid on their ride';
  end if;
  if the_ride.status <> 'searching' then
    raise exception 'this ride already has a driver';
  end if;
  if the_offer.status <> 'pending' then
    raise exception 'that bid is no longer pending';
  end if;
  if the_offer.expires_at <= now() then
    raise exception 'that bid has expired';
  end if;

  update public.rides set
    driver_id           = the_offer.driver_id,
    driver_name         = the_offer.driver_name,
    driver_avatar_color = the_offer.driver_avatar_color,
    driver_rating       = the_offer.driver_rating,
    driver_vehicle      = the_offer.vehicle,
    final_price         = the_offer.price,
    status              = 'accepted',
    accepted_at         = now()
  where id = the_ride.id
  returning * into the_ride;

  update public.offers set status = 'accepted' where id = the_offer.id;

  -- Every other bid on this ride loses. Declining them explicitly is what
  -- lets the other drivers' feeds update instantly instead of timing out.
  update public.offers
     set status = 'declined'
   where ride_id = the_ride.id
     and id <> the_offer.id
     and status = 'pending';

  return the_ride;
end;
$$;

-- Bids that nobody acted on. Called from a scheduled job, or opportunistically
-- by a client; it is idempotent either way.
create or replace function public.sweep_expired_offers()
returns integer
language sql
security definer
set search_path = public, pg_temp
as $$
  with swept as (
    update public.offers
       set status = 'expired'
     where status = 'pending'
       and expires_at <= now()
    returning 1
  )
  select count(*)::integer from swept;
$$;

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

alter table public.profiles         enable row level security;
alter table public.rides            enable row level security;
alter table public.offers           enable row level security;
alter table public.chat_messages    enable row level security;
alter table public.driver_locations enable row level security;

-- Profiles ------------------------------------------------------------------

create policy "own profile is readable"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

-- A counterparty's profile is readable only while you share a live ride with
-- them. This is why names and ratings are denormalised onto rides and offers:
-- browsing the order feed must not require reading strangers' profiles.
create policy "counterparty profile is readable during a shared ride"
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1 from public.rides r
      where auth.uid() in (r.passenger_id, r.driver_id)
        and profiles.id in (r.passenger_id, r.driver_id)
    )
  );

create policy "own profile is writable"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Rides ---------------------------------------------------------------------

create policy "participants read their rides"
  on public.rides for select
  to authenticated
  using (auth.uid() in (passenger_id, driver_id));

create policy "drivers read the open order feed"
  on public.rides for select
  to authenticated
  using (status = 'searching' and public.is_driver());

create policy "passengers publish their own rides"
  on public.rides for insert
  to authenticated
  with check (passenger_id = auth.uid() and status = 'searching' and driver_id is null);

-- What each side may actually change is settled by guard_ride_update().
create policy "participants update their rides"
  on public.rides for update
  to authenticated
  using (auth.uid() in (passenger_id, driver_id))
  with check (auth.uid() in (passenger_id, driver_id));

-- Offers --------------------------------------------------------------------

create policy "drivers read their own bids"
  on public.offers for select
  to authenticated
  using (driver_id = auth.uid());

create policy "passengers read bids on their rides"
  on public.offers for select
  to authenticated
  using (exists (
    select 1 from public.rides r where r.id = offers.ride_id and r.passenger_id = auth.uid()
  ));

create policy "drivers bid as themselves"
  on public.offers for insert
  to authenticated
  with check (driver_id = auth.uid() and public.is_driver());

create policy "drivers withdraw their own bids"
  on public.offers for update
  to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());

create policy "drivers delete their own bids"
  on public.offers for delete
  to authenticated
  using (driver_id = auth.uid());

-- Chat ----------------------------------------------------------------------

create policy "participants read the ride chat"
  on public.chat_messages for select
  to authenticated
  using (public.is_ride_participant(ride_id));

create policy "participants send to the ride chat"
  on public.chat_messages for insert
  to authenticated
  with check (sender_id = auth.uid() and public.is_ride_participant(ride_id));

-- Marking a message read is the only mutation; the text itself is immutable.
create policy "participants mark the ride chat read"
  on public.chat_messages for update
  to authenticated
  using (public.is_ride_participant(ride_id))
  with check (public.is_ride_participant(ride_id));

-- Driver positions ----------------------------------------------------------

create policy "drivers write their own position"
  on public.driver_locations for all
  to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());

-- Live positions of online drivers are readable by any signed-in user: that
-- is what puts cars on the passenger's map, and it is the same information a
-- passenger would get by standing on the street. The row carries no identity
-- beyond the driver id, which on its own resolves to nothing without a shared
-- ride (see the profiles policies above).
create policy "signed-in users see online drivers"
  on public.driver_locations for select
  to authenticated
  using (online);

-- ---------------------------------------------------------------------------
-- Realtime
--
-- Only the tables the client subscribes to. Realtime respects RLS, so a
-- driver's socket receives an open ride's INSERT but not a stranger's chat.
-- ---------------------------------------------------------------------------

alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.offers;
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.driver_locations;

-- REPLICA IDENTITY FULL makes the old row available on UPDATE and DELETE,
-- which is what lets a client tell "this ride left my feed" from "this ride
-- changed" without refetching.
alter table public.rides            replica identity full;
alter table public.offers           replica identity full;
alter table public.driver_locations replica identity full;
