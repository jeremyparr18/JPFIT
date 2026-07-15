-- JP FIT VERSION 25 — PROGRAM STUDIO
-- Run after Version 22 SQL.

alter table public.exercise_library
  add column if not exists is_favorite boolean not null default false,
  add column if not exists secondary_muscle text,
  add column if not exists movement_pattern text,
  add column if not exists tags text[] not null default '{}',
  add column if not exists default_rpe text,
  add column if not exists common_mistakes text,
  add column if not exists progression text,
  add column if not exists regression text,
  add column if not exists alternative_exercise text;

alter table public.workout_templates
  add column if not exists folder_name text not null default 'Unfiled',
  add column if not exists workout_type text not null default 'Regular',
  add column if not exists summary text,
  add column if not exists estimated_minutes integer,
  add column if not exists cover_url text,
  add column if not exists updated_at timestamptz not null default now();

create index if not exists workout_templates_folder_idx
on public.workout_templates(folder_name);

create index if not exists exercise_library_favorite_idx
on public.exercise_library(is_favorite);

grant select, insert, update, delete on public.exercise_library to authenticated;
grant select, insert, update, delete on public.workout_templates to authenticated;
