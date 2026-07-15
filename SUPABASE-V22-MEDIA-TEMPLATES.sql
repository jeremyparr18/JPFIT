-- JP FIT VERSION 22 — CUSTOM WORKOUT TEMPLATES + EXERCISE MEDIA
-- Run after Version 20 SQL.

alter table public.exercise_library
  add column if not exists written_description text,
  add column if not exists coaching_cues text,
  add column if not exists tempo text,
  add column if not exists rest_guidance text,
  add column if not exists weight_guidance text,
  add column if not exists media_url text,
  add column if not exists media_type text,
  add column if not exists attachment_url text,
  add column if not exists updated_at timestamptz not null default now();

-- Keep existing coaching cue values where available.
update public.exercise_library
set coaching_cues = coalesce(coaching_cues, coaching_cue)
where coaching_cues is null;

-- Private-by-policy storage bucket for coach-uploaded exercise media.
insert into storage.buckets (id, name, public)
values ('exercise-media', 'exercise-media', true)
on conflict (id) do nothing;

drop policy if exists "exercise_media_public_read" on storage.objects;
create policy "exercise_media_public_read"
on storage.objects for select
to public
using (bucket_id = 'exercise-media');

drop policy if exists "exercise_media_coach_insert" on storage.objects;
create policy "exercise_media_coach_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'exercise-media'
  and public.is_coach()
);

drop policy if exists "exercise_media_coach_update" on storage.objects;
create policy "exercise_media_coach_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'exercise-media'
  and public.is_coach()
)
with check (
  bucket_id = 'exercise-media'
  and public.is_coach()
);

drop policy if exists "exercise_media_coach_delete" on storage.objects;
create policy "exercise_media_coach_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'exercise-media'
  and public.is_coach()
);

grant select, insert, update, delete on public.exercise_library to authenticated;
grant select, insert, update, delete on public.workout_templates to authenticated;
