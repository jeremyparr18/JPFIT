-- JP FIT VERSION 25.1A — COACH STUDIO + EXERCISE LIBRARY PRO
-- Run after SUPABASE-V25-PROGRAM-STUDIO.sql

alter table public.exercise_library
  add column if not exists collection_name text not null default 'Unfiled',
  add column if not exists created_by uuid references auth.users(id) on delete set null,
  add column if not exists duplicated_from uuid references public.exercise_library(id) on delete set null;

create index if not exists exercise_library_collection_idx
on public.exercise_library(collection_name);

grant select, insert, update, delete on public.exercise_library to authenticated;
