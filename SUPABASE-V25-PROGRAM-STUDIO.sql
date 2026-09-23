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

-- JP Fit TUT / Eccentric-Focused Program
-- Seeds four reusable workouts into Program Studio.

insert into public.workout_templates (name,goal,level,duration_minutes,exercises,folder_name,workout_type,summary,estimated_minutes,updated_at)
values
('Legs — Eccentric Focused (TUT)','Hypertrophy','Intermediate',55,
'[{
  "name":"Single-Leg Bulgarian Split Squat — Smith Machine","sets":2,"reps":"8-10","description":"3-second eccentric. Pause at the bottom, then explode up.","rest":"90 sec"
},{
  "name":"Leg Press","sets":3,"reps":"8-10","description":"3 seconds on the way down. Pause, then explode up.","rest":"90 sec"
},{
  "name":"Leg Extension","sets":3,"reps":"15","description":"5-second hold at the top, 5 partial reps, then 5 full reps.","rest":"60 sec"
},{
  "name":"Lying Hamstring Curl","sets":2,"reps":"10-12","description":"Slow eccentric with a 3-second pause; maintain good control.","rest":"60 sec"
},{
  "name":"Adductor / Abductor","sets":2,"reps":"10-12 each","description":"Controlled reps through the full range of motion.","rest":"45-60 sec"
}]'::jsonb,
'JP Fit TUT','TUT','Leg-focused session emphasizing eccentric control, pauses and time under tension.',55,now())
on conflict (name) do update set goal=excluded.goal,level=excluded.level,duration_minutes=excluded.duration_minutes,exercises=excluded.exercises,folder_name=excluded.folder_name,workout_type=excluded.workout_type,summary=excluded.summary,estimated_minutes=excluded.estimated_minutes,updated_at=now();

insert into public.workout_templates (name,goal,level,duration_minutes,exercises,folder_name,workout_type,summary,estimated_minutes,updated_at)
values
('Pull — Eccentric Focused (TUT)','Hypertrophy','Intermediate',55,
'[{
  "name":"Assisted Pull-Up","sets":3,"reps":"8-10","description":"Slow eccentric with good control; come all the way down.","rest":"75 sec"
},{
  "name":"Close-Grip Pulldown","sets":3,"reps":"8-10","description":"Pause at the chest and use a slow, full-length extension.","rest":"75 sec"
},{
  "name":"Seated Row — PRIME","sets":3,"reps":"10-12","description":"Full extension; shoulders retracted through the pull; squeeze at the top.","rest":"75 sec"
},{
  "name":"Seated Cable Pullover","sets":2,"reps":"15","description":"Reach all the way up and use a light weight. Do not ego lift.","rest":"60 sec"
},{
  "name":"Preacher Curl Machine","sets":3,"reps":"8-12","description":"Each set includes a drop set. Use full extension.","rest":"60 sec"
},{
  "name":"Hammer Curl — Rope Cable","sets":2,"reps":"10-12","description":"Come all the way down and maintain good control.","rest":"60 sec"
},{
  "name":"Seated Rear Delt Fly Machine","sets":3,"reps":"10-12","description":"Good control; pull all the way back using the pinkies. Think of the arm path like swimming.","rest":"60 sec"
}]'::jsonb,
'JP Fit TUT','TUT','Pull session emphasizing slow eccentrics, full length, pauses and controlled contractions.',55,now())
on conflict (name) do update set goal=excluded.goal,level=excluded.level,duration_minutes=excluded.duration_minutes,exercises=excluded.exercises,folder_name=excluded.folder_name,workout_type=excluded.workout_type,summary=excluded.summary,estimated_minutes=excluded.estimated_minutes,updated_at=now();

insert into public.workout_templates (name,goal,level,duration_minutes,exercises,folder_name,workout_type,summary,estimated_minutes,updated_at)
values
('Push — Eccentric Focused (TUT)','Hypertrophy','Intermediate',55,
'[{
  "name":"Machine Chest Fly","sets":1,"reps":"12-15","description":"3-second eccentric, 3-second hold at the bottom and 3-second hold at the top.","rest":"60 sec"
},{
  "name":"Machine Chest Fly","sets":2,"reps":"10-12","description":"Same 3-second eccentric and 3-second holds at the bottom and top; use a slightly heavier load for the lower rep range.","rest":"60 sec"
},{
  "name":"Machine Chest Press","sets":3,"reps":"8-10","description":"Slow controlled reps. Pause at the bottom for 2 seconds and control the concentric as well.","rest":"90 sec"
},{
  "name":"JM Press","sets":3,"reps":"10-12","description":"Keep elbows in and rotated, focusing on the triceps squeeze.","rest":"75 sec"
},{
  "name":"Cable Front Delt Press — V-Bar","sets":3,"reps":"8-10","description":"Keep elbows in, reach full extension and perform the movement nice and slow.","rest":"60 sec"
},{
  "name":"Side-to-Front Raises","sets":2,"reps":"15","description":"Raise to the side, bring to the front, lower, then return up and to the side. Do not ego lift.","rest":"45 sec"
},{
  "name":"Overhead Cable Extension — Rope","sets":2,"reps":"10-12","description":"Each set includes a drop set. Keep elbows in.","rest":"60 sec"
},{
  "name":"Assisted Dips","sets":2,"reps":"Failure","description":"Controlled reps to technical failure.","rest":"75 sec"
}]'::jsonb,
'JP Fit TUT','TUT','Push session emphasizing long eccentrics, pauses, controlled concentrics and drop sets.',55,now())
on conflict (name) do update set goal=excluded.goal,level=excluded.level,duration_minutes=excluded.duration_minutes,exercises=excluded.exercises,folder_name=excluded.folder_name,workout_type=excluded.workout_type,summary=excluded.summary,estimated_minutes=excluded.estimated_minutes,updated_at=now();

insert into public.workout_templates (name,goal,level,duration_minutes,exercises,folder_name,workout_type,summary,estimated_minutes,updated_at)
values
('Shoulders — TUT','Hypertrophy','Intermediate',40,
'[{
  "name":"Seated Shoulder Machine Press","sets":3,"reps":"8-10","description":"Good control, nice and slow, with full extension.","rest":"75 sec"
},{
  "name":"Cable Lateral Raise — Side Delt","sets":1,"reps":"12-15","description":"Cable set at the bottom. Controlled reps.","rest":"45 sec"
},{
  "name":"Cable Lateral Raise — Side Delt","sets":2,"reps":"8-10","description":"Cable set at the bottom. Superset with dumbbell side-delt partial raises.","rest":"45 sec"
},{
  "name":"Dumbbell Side-Delt Partial Raise","sets":3,"reps":"Partial reps","description":"Superset with the cable lateral raise; keep tension on the side delts.","rest":"45 sec"
},{
  "name":"PRIME Extreme Row Machine — Rear Delt","sets":3,"reps":"10-12","description":"Good control; pull all the way back using the pinkies. Think of the arm path like swimming.","rest":"60 sec"
}]'::jsonb,
'JP Fit TUT','TUT','Shoulder session emphasizing controlled reps, constant tension and side/rear-delt work.',40,now())
on conflict (name) do update set goal=excluded.goal,level=excluded.level,duration_minutes=excluded.duration_minutes,exercises=excluded.exercises,folder_name=excluded.folder_name,workout_type=excluded.workout_type,summary=excluded.summary,estimated_minutes=excluded.estimated_minutes,updated_at=now();
