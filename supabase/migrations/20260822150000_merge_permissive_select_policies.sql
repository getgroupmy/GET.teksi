-- Collapse the pairs of permissive SELECT policies into one policy each.
--
-- Postgres evaluates every permissive policy that applies to a command and
-- ORs the results, so two SELECT policies on a table mean both expressions
-- run for every row considered. The database linter reports it as
-- multiple_permissive_policies on four tables.
--
-- Nothing about who can see what changes here. `a OR b` as one policy is the
-- same set of rows as `a` and `b` as two permissive policies — that is the
-- definition of permissive — and supabase/tests/policies.sql asserts the
-- access rules of all four tables from both the allowed and the denied side,
-- so a merge that moved the boundary would fail it.
--
-- Order matters, and it is the same in every block below: widen the surviving
-- policy to the union FIRST, then drop the redundant one. The other order
-- leaves a window in which the dropped policy's rows are unreachable, and on
-- a live database that window is a partial outage. Widening first is never
-- narrower than what was there, and never wider than the union the two
-- policies already granted together.

-- ---------------------------------------------------------------------------
-- rides: participants, plus drivers looking at the open feed.
-- ---------------------------------------------------------------------------

alter policy "participants read their rides" on public.rides
  using (
    ((select auth.uid()) = passenger_id)
    or ((select auth.uid()) = driver_id)
    or (status = 'searching' and (select private.is_driver()))
  );

drop policy "drivers read the open order feed" on public.rides;

alter policy "participants read their rides" on public.rides
  rename to "rides are readable by participants and by drivers on the feed";

-- ---------------------------------------------------------------------------
-- offers: the driver who bid, plus the passenger whose ride it is.
-- ---------------------------------------------------------------------------

alter policy "passengers read bids on their rides" on public.offers
  using (
    (driver_id = (select auth.uid()))
    or exists (
      select 1 from public.rides r
      where r.id = offers.ride_id
        and r.passenger_id = (select auth.uid())
    )
  );

drop policy "drivers read their own bids" on public.offers;

alter policy "passengers read bids on their rides" on public.offers
  rename to "bids are readable by their driver and by the ride's passenger";

-- ---------------------------------------------------------------------------
-- profiles: your own, plus whoever you are sharing a ride with.
-- ---------------------------------------------------------------------------

alter policy "own profile is readable" on public.profiles
  using (
    (id = (select auth.uid()))
    or exists (
      select 1 from public.rides r
      where (
        ((select auth.uid()) = r.passenger_id)
        or ((select auth.uid()) = r.driver_id)
      )
      and (profiles.id = r.passenger_id or profiles.id = r.driver_id)
    )
  );

drop policy "counterparty profile is readable during a shared ride"
  on public.profiles;

alter policy "own profile is readable" on public.profiles
  rename to "profiles are readable by their owner and by a ride counterparty";

-- ---------------------------------------------------------------------------
-- driver_locations: the one that is not a pair of SELECT policies.
--
-- "drivers write their own position" is FOR ALL, so it governs reads as well
-- as writes, and it is its SELECT arm that collides with the online-drivers
-- policy. It cannot simply be merged away: dropping it would take the write
-- rules with it.
--
-- So the SELECT arm folds into the read policy and the write arms become
-- explicit per-command policies. That is four policies where there were two,
-- which looks like the wrong direction until you count per command, which is
-- what Postgres actually evaluates: SELECT goes from two policies to one, and
-- INSERT, UPDATE and DELETE stay at one each.
--
-- The write expressions are copied exactly from the FOR ALL policy, with its
-- `qual` becoming USING on UPDATE and DELETE and its `with_check` becoming
-- WITH CHECK on INSERT and UPDATE, which is how Postgres was applying them.
-- ---------------------------------------------------------------------------

alter policy "signed-in users see online drivers" on public.driver_locations
  using (online or (driver_id = (select auth.uid())));

create policy "drivers insert their own position" on public.driver_locations
  for insert to authenticated
  with check (driver_id = (select auth.uid()));

create policy "drivers update their own position" on public.driver_locations
  for update to authenticated
  using (driver_id = (select auth.uid()))
  with check (driver_id = (select auth.uid()));

create policy "drivers delete their own position" on public.driver_locations
  for delete to authenticated
  using (driver_id = (select auth.uid()));

drop policy "drivers write their own position" on public.driver_locations;

alter policy "signed-in users see online drivers" on public.driver_locations
  rename to "driver positions are readable when online or your own";

-- ---------------------------------------------------------------------------
-- Assertions, because this migration's whole purpose is a property that is
-- invisible in behaviour. If it silently did nothing, every test downstream
-- would still pass and the lint would still be there.
-- ---------------------------------------------------------------------------

do $$
declare
  offenders text;
begin
  -- 1. No table may evaluate more than one permissive policy on a read.
  --    SELECT and ALL both count: an ALL policy governs reads too, which is
  --    exactly what driver_locations was doing.
  select string_agg(format('%s (%s)', tablename, n), ', ')
    into offenders
  from (
    select tablename, count(*) as n
    from pg_policies
    where schemaname = 'public'
      and permissive = 'PERMISSIVE'
      and roles::text like '%authenticated%'
      and cmd in ('SELECT', 'ALL')
    group by tablename
    having count(*) > 1
  ) t;

  if offenders is not null then
    raise exception
      'these tables still run more than one permissive policy per row read: %',
      offenders;
  end if;

  -- 2. And that the merge did not reintroduce a per-row auth.uid(), which is
  --    what 20260822090000 went to the trouble of removing. Rewriting a
  --    policy is exactly when it would come back.
  select string_agg(format('%s.%s', tablename, policyname), ', ')
    into offenders
  from pg_policies
  where schemaname = 'public'
    and (
      (qual is not null
        and qual ~ 'auth\.uid\(\)' and qual !~ 'SELECT auth\.uid\(\)')
      or (with_check is not null
        and with_check ~ 'auth\.uid\(\)'
        and with_check !~ 'SELECT auth\.uid\(\)')
    );

  if offenders is not null then
    raise exception
      'these policies evaluate auth.uid() per row again: %', offenders;
  end if;
end
$$;
