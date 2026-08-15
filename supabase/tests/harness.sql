-- A minimal stand-in for the parts of a Supabase project that the migration
-- builds on, so the schema can be executed and its policies exercised against
-- a plain PostgreSQL instance — in CI, or on a laptop, with nothing to
-- provision and no project to point at.
--
-- This file is never applied to a real project: Supabase already provides
-- everything in it.

create schema if not exists auth;

-- Supabase's user table, reduced to the columns the migration reads.
create table auth.users (
  id                  uuid primary key default gen_random_uuid(),
  phone               text,
  email               text,
  raw_user_meta_data  jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now()
);

-- In a real project this reads the `sub` claim of the request's JWT. Here it
-- reads a session variable, which is what lets a test say "now act as this
-- user" and have every policy respond exactly as it would in production.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('test.uid', true), '')::uuid;
$$;

-- The roles PostgREST connects as.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
end
$$;

grant usage on schema public to anon, authenticated;
-- A real project grants these; policies and invoker-side triggers call
-- auth.uid() as the signed-in role, so without them nothing works.
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant execute on functions to anon, authenticated;

-- Realtime's publication, which the migration adds its tables to.
create publication supabase_realtime;
