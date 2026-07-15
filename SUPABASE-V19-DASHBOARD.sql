-- JP FIT VERSION 19 CLIENT DASHBOARD
-- Run this AFTER SUPABASE-SETUP.sql.

create table if not exists public.progress_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null default current_date,
  weight numeric(6,2),
  waist numeric(6,2),
  body_fat numeric(5,2),
  steps integer,
  sleep_hours numeric(4,1),
  energy integer check (energy between 1 and 10),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  checkin_date date not null default current_date,
  adherence integer check (adherence between 0 and 100),
  mood integer check (mood between 1 and 10),
  stress integer check (stress between 1 and 10),
  wins text,
  challenges text,
  questions text,
  coach_response text,
  status text not null default 'submitted'
    check (status in ('draft','submitted','reviewed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid references auth.users(id) on delete cascade,
  client_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table if not exists public.nutrition_targets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  calories integer,
  protein integer,
  carbs integer,
  fats integer,
  water_ounces integer,
  coach_notes text,
  updated_at timestamptz not null default now()
);

create table if not exists public.workout_assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  scheduled_date date,
  status text not null default 'assigned'
    check (status in ('assigned','in_progress','completed','missed')),
  exercises jsonb not null default '[]'::jsonb,
  coach_notes text,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.progress_entries enable row level security;
alter table public.checkins enable row level security;
alter table public.messages enable row level security;
alter table public.nutrition_targets enable row level security;
alter table public.workout_assignments enable row level security;

drop policy if exists "progress_own_all" on public.progress_entries;
create policy "progress_own_all" on public.progress_entries
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "checkins_own_all" on public.checkins;
create policy "checkins_own_all" on public.checkins
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "messages_own_select" on public.messages;
create policy "messages_own_select" on public.messages
for select to authenticated
using ((select auth.uid()) = client_id or (select auth.uid()) = sender_id or (select auth.uid()) = recipient_id);

drop policy if exists "messages_own_insert" on public.messages;
create policy "messages_own_insert" on public.messages
for insert to authenticated
with check ((select auth.uid()) = sender_id and (select auth.uid()) = client_id);

drop policy if exists "nutrition_own_select" on public.nutrition_targets;
create policy "nutrition_own_select" on public.nutrition_targets
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "workouts_own_select" on public.workout_assignments;
create policy "workouts_own_select" on public.workout_assignments
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "workouts_own_update" on public.workout_assignments;
create policy "workouts_own_update" on public.workout_assignments
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.progress_entries to authenticated;
grant select, insert, update on public.checkins to authenticated;
grant select, insert on public.messages to authenticated;
grant select on public.nutrition_targets to authenticated;
grant select, update on public.workout_assignments to authenticated;
