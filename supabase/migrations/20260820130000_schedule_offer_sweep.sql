-- Give the expiry sweep a clock.
--
-- A bid carries `expires_at`, and the client already treats a passed one as
-- dead, so nothing breaks without this. What breaks is the *record*: bids that
-- nobody acted on sit at `pending` forever, so "how many of my bids went
-- unanswered" cannot be asked of the data, and the partial index that exists
-- to keep pending bids cheap to scan grows without bound.
--
-- `sweep_expired_offers()` is idempotent and takes no arguments, which is what
-- makes it safe to run on a timer. Every minute matches the 90-second bid
-- lifetime: a bid is never marked expired more than a minute after it was.
--
-- The job runs as the database owner, so `auth.uid()` is null inside it and
-- the write guards return early — the same path the function was designed for.
--
-- pg_cron only exists on a Supabase project (or a server that installed it).
-- The policy suite runs against a stock PostgreSQL, so this has to skip rather
-- than fail there, and it says so out loud instead of skipping silently.

do $$
begin
  if not exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    raise notice
      'pg_cron is not available here, so the sweep is left unscheduled. '
      'Expected outside Supabase; sweep_expired_offers() still works when called.';
    return;
  end if;

  -- `pg_available_extensions` says the package is on disk, not that the
  -- extension can be created: pg_cron also has to be in
  -- shared_preload_libraries, and without that this fails with
  -- "unrecognized configuration parameter cron.database_name" — an error that
  -- says nothing about the actual cause. A machine with the package installed
  -- but not preloaded is a normal developer machine, so it skips like any
  -- other environment without pg_cron rather than failing the whole suite.
  begin
    execute 'create extension if not exists pg_cron';
  exception when others then
    raise notice
      'pg_cron is installed but cannot be created here (%), so the sweep is '
      'left unscheduled. sweep_expired_offers() still works when called.',
      sqlerrm;
    return;
  end;

  -- Idempotent: re-applying the migration replaces the schedule rather than
  -- stacking a second job that does the same work.
  if exists (select 1 from cron.job where jobname = 'sweep-expired-offers') then
    perform cron.unschedule('sweep-expired-offers');
  end if;

  perform cron.schedule(
    'sweep-expired-offers',
    '* * * * *',
    'select public.sweep_expired_offers()'
  );

  raise notice 'scheduled sweep-expired-offers every minute';
end
$$;
