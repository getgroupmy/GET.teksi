-- Stop a client writing the parts of its own profile it has not earned.
--
-- `own profile is writable` says `id = auth.uid()`, which is a rule about the
-- row. Row-level security cannot express a rule about a column, and that is
-- exactly the distinction this schema was built around for rides and offers —
-- both of which have a BEFORE UPDATE guard for precisely this reason. The
-- profiles table was left without one.
--
-- So an account could update its own row and set anything on it:
--
--   PATCH /rest/v1/profiles?id=eq.<me>   {"wallet_balance": 99999999}
--
-- The wallet was moved server-side on the argument that a client which writes
-- its own balance is not a wallet. The ledger got that treatment — append-only,
-- a select policy and no other — while the cached balance sat on this table
-- with nothing in front of it. The ledger was never the whole story: the
-- balance the wallet screen reads is this column.
--
-- The same hole covered reputation and verification. A driver could mark
-- themselves verified, set their own rating to 5.00, and award themselves any
-- number of completed trips — the three things a passenger looks at when
-- deciding whether to get into a stranger's car.

create or replace function private.guard_profile_update()
returns trigger
language plpgsql
-- Invoker, not definer. A definer function sees itself as current_user no
-- matter who called it, so it cannot tell a client from the server — the
-- mistake this schema already made once and fixed in accept_offer.
set search_path = public, pg_temp
as $$
declare
  actor uuid := auth.uid();
begin
  -- No actor means the database is doing this to itself: the settlement
  -- trigger crediting a balance, the sign-up trigger creating the row. Those
  -- are the writes this guard exists to protect, not to obstruct.
  if actor is null or public.is_privileged_writer() then
    return new;
  end if;

  if new.id <> old.id then
    raise exception 'profile identity is immutable';
  end if;

  -- The phone number is the account. Changing it here would silently detach
  -- the profile from the credential that authenticates it.
  if new.phone is distinct from old.phone then
    raise exception 'the phone number is set by auth, not by the client';
  end if;

  -- Derived from the ledger by private.apply_wallet_delta(). A client may read
  -- it and may never write it.
  if new.wallet_balance is distinct from old.wallet_balance then
    raise exception 'the wallet balance is derived from the ledger';
  end if;

  -- Reputation is a thing other people give you.
  if new.rating is distinct from old.rating
     or new.rides_taken is distinct from old.rides_taken
     or new.driver_rating is distinct from old.driver_rating
     or new.driver_rides_given is distinct from old.driver_rides_given then
    raise exception 'ratings and trip counts are not self-assigned';
  end if;

  -- Document verification is the platform's judgement about a driver. This
  -- build verifies automatically, which is a decision about *how* the platform
  -- decides — not about who decides.
  if new.driver_verified is distinct from old.driver_verified then
    raise exception 'verification is granted, not claimed';
  end if;

  -- Everything left is genuinely the account holder's: their name, their
  -- email, their avatar colour, whether they drive, and what they drive.
  return new;
end;
$$;

create trigger profiles_guard_update
  before update on public.profiles
  for each row execute function private.guard_profile_update();

-- Not reachable over HTTP: PostgREST publishes `public`, and a guard is not an
-- API. Triggers run it regardless of who may execute it by name.
revoke execute on function private.guard_profile_update()
  from public, anon, authenticated;
