-- JP Fit v3.2.3: client workout logging and durable session history
-- Run this migration in the Supabase SQL Editor before deploying the updated client portal.
create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  assignment_id uuid not null references public.workout_assignments(id) on delete cascade,
  workout_title text not null,
  status text not null default 'in_progress' check (status in ('in_progress','completed')),
  logs jsonb not null default '[]'::jsonb,
  notes text not null default '',
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists workout_sessions_user_started_idx on public.workout_sessions(user_id, started_at desc);
create index if not exists workout_sessions_assignment_idx on public.workout_sessions(assignment_id, started_at desc);
alter table public.workout_sessions enable row level security;
drop policy if exists "workout_sessions_client_select_own" on public.workout_sessions;
create policy "workout_sessions_client_select_own" on public.workout_sessions for select to authenticated using (auth.uid() = user_id);
drop policy if exists "workout_sessions_client_insert_own" on public.workout_sessions;
create policy "workout_sessions_client_insert_own" on public.workout_sessions for insert to authenticated with check (auth.uid() = user_id and exists (select 1 from public.workout_assignments a where a.id = assignment_id and a.user_id = auth.uid()));
drop policy if exists "workout_sessions_client_update_own" on public.workout_sessions;
create policy "workout_sessions_client_update_own" on public.workout_sessions for update to authenticated using (auth.uid() = user_id and exists (select 1 from public.workout_assignments a where a.id = assignment_id and a.user_id = auth.uid())) with check (auth.uid() = user_id and exists (select 1 from public.workout_assignments a where a.id = assignment_id and a.user_id = auth.uid()));
drop policy if exists "workout_sessions_coach_select" on public.workout_sessions;
create policy "workout_sessions_coach_select" on public.workout_sessions for select to authenticated using (public.is_coach());
grant select, insert, update on public.workout_sessions to authenticated;
