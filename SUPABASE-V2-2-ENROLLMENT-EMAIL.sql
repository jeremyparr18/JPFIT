-- JP FIT VERSION 2.2 — REAL ENROLLMENT EMAIL DELIVERY
-- Run after SUPABASE-V2-1-ENROLLMENT-SYSTEM.sql. Safe to run more than once.
alter table public.coach_enrollments
  add column if not exists enrollment_email_sent_at timestamptz,
  add column if not exists last_email_sent_at timestamptz,
  add column if not exists last_email_message_id text,
  add column if not exists last_email_error text;
comment on column public.coach_enrollments.enrollment_email_sent_at is 'Time the initial branded enrollment email was successfully sent.';
comment on column public.coach_enrollments.last_email_sent_at is 'Time the most recent enrollment or reminder email was successfully sent.';
comment on column public.coach_enrollments.last_email_message_id is 'Email provider message ID for delivery troubleshooting.';
comment on column public.coach_enrollments.last_email_error is 'Most recent email-delivery error, cleared after a successful send.';
