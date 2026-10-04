-- Where a device says "send push here".
--
-- Nothing arrives while the app is closed (docs/PUSH.md). Closing that gap
-- needs somewhere to keep the address of each device, and this is it. One row
-- per device per platform, owned by the person signed in on it.
--
-- Two shapes share this table because they are the same thing at different
-- lengths. APNs gives a device token and nothing else. Web Push gives an
-- endpoint URL plus two keys the sender needs in order to encrypt the
-- payload, because Web Push is encrypted end to end and the push service
-- never sees the contents. Hence `p256dh` and `auth`, null on iOS.

create table public.push_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,

  -- 'ios'  — an APNs device token.
  -- 'web'  — the subscription endpoint URL.
  --
  -- A check constraint rather than an enum, which is the ordinary choice and
  -- the readable one. Worth knowing the trade: widening an enum is `alter
  -- type ... add value`, while widening this is a drop and re-add of the
  -- constraint. That matters more than usual right now, because DROP
  -- statements hang on the live project (see the open Supabase ticket), so
  -- adding 'android' here later is blocked until that is fixed.
  platform   text not null check (platform in ('ios', 'web')),

  token      text not null,

  -- Web Push only. The sender encrypts to these; APNs rows leave them null.
  p256dh     text,
  auth       text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- One row per device. Re-registering the same device upserts rather than
  -- accumulating, and a device handed to a different account moves with it.
  unique (platform, token),

  -- Web Push without its keys is undeliverable, and an iOS row carrying them
  -- is a sign something filled in the wrong shape. Say so at write time
  -- rather than discovering it in a send that silently does nothing.
  constraint push_tokens_web_has_keys check (
    (platform = 'web' and p256dh is not null and auth is not null)
    or (platform <> 'web' and p256dh is null and auth is null)
  )
);

-- The sender's only query is "every device for this person".
create index push_tokens_user_idx on public.push_tokens (user_id);

create trigger push_tokens_touch
  before update on public.push_tokens
  for each row execute function public.touch_updated_at();

alter table public.push_tokens enable row level security;

-- One policy per command, not one FOR ALL.
--
-- A FOR ALL policy governs reads as well as writes, so it collides with any
-- later read policy and has to be taken apart again — which is exactly what
-- 20260822150000 had to do to driver_locations. Starting per-command costs
-- three extra lines and avoids that entirely.
--
-- auth.uid() is wrapped in a scalar subquery throughout, so it is evaluated
-- once per statement rather than once per row, matching what
-- 20260822090000 established.

create policy "people read their own push tokens"
  on public.push_tokens for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "people register their own push tokens"
  on public.push_tokens for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "people update their own push tokens"
  on public.push_tokens for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "people delete their own push tokens"
  on public.push_tokens for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- Nothing is granted to anon. A signed-out client has no device to register.
revoke all on public.push_tokens from anon;
