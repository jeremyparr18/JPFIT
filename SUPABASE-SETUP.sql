-- JP FIT VERSION 18 FOUNDATION
-- Run this entire file once in Supabase Dashboard -> SQL Editor.
-- It creates the first production tables and Row Level Security policies.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'client' check (role in ('client','coach','admin')),
  full_name text,
  phone text,
  address text,
  emergency_contact_name text,
  emergency_contact_phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal text,
  service text not null,
  frequency text not null,
  agreement_term text not null,
  biweekly_price numeric(10,2) not null,
  start_date date,
  status text not null default 'submitted'
    check (status in ('draft','submitted','pending_payment','active','paused','cancelled')),
  stripe_checkout_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.agreements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrollment_id uuid references public.enrollments(id) on delete set null,
  agreement_code text not null unique,
  signed_name text not null,
  signed_at timestamptz not null,
  photo_consent boolean not null default false,
  agreement_version text not null default 'JP-FIT-v1',
  agreement_snapshot jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.intake_forms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrollment_id uuid references public.enrollments(id) on delete set null,
  age integer,
  height text,
  current_weight text,
  occupation text,
  primary_goal text,
  goal_reason text,
  experience_level text,
  equipment_access text,
  current_activity text,
  preferred_schedule text,
  health_history text,
  medical_clearance_notes text,
  nutrition_summary text,
  average_sleep text,
  average_steps text,
  additional_notes text,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create a client profile when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (new.id, 'client', coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.enrollments enable row level security;
alter table public.agreements enable row level security;
alter table public.intake_forms enable row level security;

-- Clients can view/update their own profile.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- Clients can create and read their own enrollment records.
drop policy if exists "enrollments_insert_own" on public.enrollments;
create policy "enrollments_insert_own"
on public.enrollments for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "enrollments_select_own" on public.enrollments;
create policy "enrollments_select_own"
on public.enrollments for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "enrollments_update_own" on public.enrollments;
create policy "enrollments_update_own"
on public.enrollments for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Signed agreements are immutable from the browser after insertion.
drop policy if exists "agreements_insert_own" on public.agreements;
create policy "agreements_insert_own"
on public.agreements for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "agreements_select_own" on public.agreements;
create policy "agreements_select_own"
on public.agreements for select
to authenticated
using ((select auth.uid()) = user_id);

-- Intake forms belong only to their authenticated client.
drop policy if exists "intakes_insert_own" on public.intake_forms;
create policy "intakes_insert_own"
on public.intake_forms for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "intakes_select_own" on public.intake_forms;
create policy "intakes_select_own"
on public.intake_forms for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "intakes_update_own" on public.intake_forms;
create policy "intakes_update_own"
on public.intake_forms for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Grant authenticated users access through the Data API.
grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.enrollments to authenticated;
grant select, insert on public.agreements to authenticated;
grant select, insert, update on public.intake_forms to authenticated;
