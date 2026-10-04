-- ---------------------------------------------------------------------------
-- Evaluate auth.uid() once per statement instead of once per row.
--
-- Every policy written before this one called `auth.uid()` directly. Postgres
-- has no way to know that answer is the same for every row of a statement, so
-- it asks again for each one — and `auth.uid()` is not free: it parses the
-- request's JWT claims out of a GUC on each call. On a single-row lookup that
-- is invisible. On the open order feed, which is the hottest query in the app
-- and the one every driver polls, it is paid once per candidate ride.
--
-- Wrapping the call in a scalar subquery turns it into an InitPlan: evaluated
-- once, before the scan, and referenced as a constant thereafter. The
-- condition it expresses is identical, which is the point — this migration is
-- meant to change the plan and nothing else, and supabase/tests/policies.sql
-- asserts every one of these rules from both directions, so a rewrite that
-- quietly changed who can see what would fail the suite rather than pass.
--
-- ALTER POLICY rather than drop and recreate: there is no moment in the middle
-- where the table is readable by someone it should not be.
--
-- Found by Supabase's own database linter (auth_rls_initplan), which flagged
-- fourteen policies. Two more are changed here that it did not flag, for the
-- same reason — see the note on private.is_driver() below.
-- ---------------------------------------------------------------------------

-- Profiles ------------------------------------------------------------------

alter policy "own profile is readable" on public.profiles
  using (id = (select auth.uid()));

alter policy "counterparty profile is readable during a shared ride"
  on public.profiles
  using (
    exists (
      select 1 from public.rides r
      where (select auth.uid()) in (r.passenger_id, r.driver_id)
        and profiles.id in (r.passenger_id, r.driver_id)
    )
  );

alter policy "own profile is writable" on public.profiles
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Rides ---------------------------------------------------------------------

alter policy "participants read their rides" on public.rides
  using ((select auth.uid()) in (passenger_id, driver_id));

-- Not flagged by the linter, which only looks for auth.* calls, but the same
-- shape and a heavier one: private.is_driver() reads the caller's profile.
-- It takes no arguments and is STABLE, so its answer cannot vary between rows
-- of one statement — exactly the condition a subquery hoist needs. This is
-- the open order feed's policy, so it is the one that matters most.
alter policy "drivers read the open order feed" on public.rides
  using (status = 'searching' and (select private.is_driver()));

alter policy "passengers publish their own rides" on public.rides
  with check (
    passenger_id = (select auth.uid())
    and status = 'searching'
    and driver_id is null
  );

alter policy "participants update their rides" on public.rides
  using ((select auth.uid()) in (passenger_id, driver_id))
  with check ((select auth.uid()) in (passenger_id, driver_id));

-- Offers --------------------------------------------------------------------

alter policy "drivers read their own bids" on public.offers
  using (driver_id = (select auth.uid()));

alter policy "passengers read bids on their rides" on public.offers
  using (
    exists (
      select 1 from public.rides r
      where r.id = offers.ride_id
        and r.passenger_id = (select auth.uid())
    )
  );

alter policy "drivers bid as themselves" on public.offers
  with check (
    driver_id = (select auth.uid())
    and (select private.is_driver())
  );

alter policy "drivers withdraw their own bids" on public.offers
  using (driver_id = (select auth.uid()))
  with check (driver_id = (select auth.uid()));

alter policy "drivers delete their own bids" on public.offers
  using (driver_id = (select auth.uid()));

-- Chat ----------------------------------------------------------------------

-- Only the sender check is hoisted. private.is_ride_participant(ride_id)
-- takes a column as its argument, so its answer genuinely does vary from row
-- to row and there is nothing to hoist — a subquery around it would be a
-- correlated subquery, which is the same work in a more confusing shape.
alter policy "participants send to the ride chat" on public.chat_messages
  with check (
    sender_id = (select auth.uid())
    and private.is_ride_participant(ride_id)
  );

-- Driver positions ----------------------------------------------------------

alter policy "drivers write their own position" on public.driver_locations
  using (driver_id = (select auth.uid()))
  with check (driver_id = (select auth.uid()));

-- Wallet --------------------------------------------------------------------

alter policy "own ledger is readable" on public.wallet_transactions
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- A foreign key with no covering index.
--
-- chat_messages.sender_id references profiles(id). Without an index, deleting
-- or updating a profile makes Postgres scan every message to check the
-- constraint, and the "participants send to the ride chat" policy filters on
-- this column too.
-- ---------------------------------------------------------------------------

create index if not exists chat_messages_sender_idx
  on public.chat_messages (sender_id);

-- ---------------------------------------------------------------------------
-- And an assertion, because the whole point of the migration is a property
-- that is invisible in behaviour: every policy above still means what it
-- meant, and none of them calls auth.uid() per row any more. A migration that
-- silently did nothing would otherwise look exactly like one that worked.
-- ---------------------------------------------------------------------------

do $$
declare
  stragglers text;
begin
  select string_agg(format('%s.%s', tablename, policyname), ', ')
    into stragglers
  from pg_policies
  where schemaname = 'public'
    and (
      -- An auth.uid() that is not already inside a scalar subquery. The
      -- hoisted form renders as "( SELECT auth.uid() AS uid)", so anything
      -- matching auth.uid() without a SELECT in front of it is a straggler.
      (qual is not null and qual ~ 'auth\.uid\(\)' and qual !~ 'SELECT auth\.uid\(\)')
      or (with_check is not null and with_check ~ 'auth\.uid\(\)' and with_check !~ 'SELECT auth\.uid\(\)')
    );

  if stragglers is not null then
    raise exception
      'these policies still evaluate auth.uid() per row: %', stragglers;
  end if;
end
$$;
