-- Stop pg_cron's own run log growing without bound.
--
-- `sweep-expired-offers` runs every minute, and pg_cron writes a row to
-- `cron.job_run_details` for each run and never removes one. That is 1,440
-- rows a day — about half a million a year — in a table nobody reads except
-- when something has gone wrong. It had passed 64,000 rows before anyone
-- looked, which is the shape of problem that is never urgent and never fixed.
--
-- Seven days is the window because of what the table is actually for: finding
-- out whether a job has been failing, and a failure that has been happening
-- for a week without anyone noticing is not one more history will help with.
-- The alternative is `cron.log_run = off`, which trades the growth for having
-- no way at all to answer "is the sweep running" — and that question had real
-- value today.
--
-- The purge keeps its own rows under the same rule, at one a day.
--
-- pg_cron only exists on a Supabase project (or a server that installed it).
-- The policy suite runs against a stock PostgreSQL, so this skips rather than
-- fails there, and says so out loud instead of skipping silently — the same
-- shape as 20260820130000_schedule_offer_sweep.sql.

do $$
declare
  purge_job_id bigint;
begin
  if not exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    raise notice
      'pg_cron is not available here, so the run-history purge is left '
      'unscheduled. Expected outside Supabase.';
    return;
  end if;

  -- Available is not the same as creatable: pg_cron must also be in
  -- shared_preload_libraries. See the same guard in
  -- 20260820130000_schedule_offer_sweep.sql.
  begin
    execute 'create extension if not exists pg_cron';
  exception when others then
    raise notice
      'pg_cron is installed but cannot be created here (%), so the '
      'run-history purge is left unscheduled.', sqlerrm;
    return;
  end;

  -- Idempotent: re-applying replaces the schedule rather than stacking a
  -- second job doing the same deletes.
  if exists (select 1 from cron.job where jobname = 'purge-cron-run-history') then
    perform cron.unschedule('purge-cron-run-history');
  end if;

  -- 03:23 rather than midnight or on the hour: cron schedules cluster there,
  -- and this job has no reason to compete for the same minute as everything
  -- else on the instance.
  --
  -- start_time, not end_time: a run that died without finishing leaves
  -- end_time null, and filtering on end_time would keep those rows for ever —
  -- which are precisely the rows a stuck job produces.
  purge_job_id := cron.schedule(
    'purge-cron-run-history',
    '23 3 * * *',
    $job$
      delete from cron.job_run_details
      where start_time < now() - interval '7 days'
    $job$
  );

  -- Assert it landed. cron.schedule returning without raising is not the same
  -- as a job being in the table, and a retention job that silently was not
  -- scheduled looks exactly like one that was.
  if not exists (
    select 1 from cron.job
    where jobid = purge_job_id and jobname = 'purge-cron-run-history'
  ) then
    raise exception
      'cron.schedule returned % but no such job is in cron.job', purge_job_id;
  end if;

  raise notice
    'scheduled purge-cron-run-history daily at 03:23, keeping 7 days';
end
$$;
