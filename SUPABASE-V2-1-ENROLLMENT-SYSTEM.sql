-- JP FIT VERSION 2.1 — COACH ENROLLMENT SYSTEM
-- Run after the existing Version 2.0 Supabase migrations.
-- This creates a separate coach-managed sales/enrollment tracking table and does not modify existing enrollment data.

create table if not exists public.coach_enrollments (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete restrict,
  client_name text not null,
  client_email text not null,
  client_phone text,
  notes text,
  package text not null check (package in ('inperson','mobile','online')),
  session_length text not null check (session_length in ('30','60','na')),
  frequency text not null,
  payment_selection text not null check (payment_selection in ('existing_stripe','manual')),
  stripe_payment_link text,
  status text not null default 'Draft' check (status in ('Draft','Enrollment Sent','Payment Pending','Paid','Reminder Due')),
  reminder_count integer not null default 0 check (reminder_count >= 0),
  last_reminder_at timestamptz,
  next_follow_up_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists coach_enrollments_status_idx on public.coach_enrollments(status);
create index if not exists coach_enrollments_follow_up_idx on public.coach_enrollments(next_follow_up_at);
create index if not exists coach_enrollments_email_idx on public.coach_enrollments(lower(client_email));

alter table public.coach_enrollments enable row level security;

drop policy if exists "coach_enrollments_coach_all" on public.coach_enrollments;
create policy "coach_enrollments_coach_all"
on public.coach_enrollments for all
to authenticated
using (public.is_coach())
with check (public.is_coach() and created_by = (select auth.uid()));

grant select, insert, update, delete on public.coach_enrollments to authenticated;

comment on table public.coach_enrollments is 'Version 2.1 coach-created enrollment and payment follow-up tracking records.';
