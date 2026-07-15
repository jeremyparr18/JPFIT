-- JP FIT VERSION 1.0.1 — EMAIL LAUNCH SYSTEM

create table if not exists public.email_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  agreement_id uuid references public.agreements(id) on delete set null,
  event_type text not null,
  recipient_email text not null,
  provider_message_id text,
  status text not null default 'pending'
    check (status in ('pending','sent','failed','skipped')),
  error_message text,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  unique (agreement_id, event_type)
);

alter table public.email_events enable row level security;

drop policy if exists "email_events_coach_select" on public.email_events;
create policy "email_events_coach_select"
on public.email_events for select
to authenticated
using (public.is_coach());

drop policy if exists "email_events_client_select_own" on public.email_events;
create policy "email_events_client_select_own"
on public.email_events for select
to authenticated
using ((select auth.uid()) = user_id);

grant select on public.email_events to authenticated;
