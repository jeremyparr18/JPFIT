-- JP FIT VERSION 20 — COACH DASHBOARD + EXERCISE LIBRARY
-- Run after Version 18 and Version 19 SQL files.

create or replace function public.is_coach()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and role in ('coach','admin')
  );
$$;

grant execute on function public.is_coach() to authenticated;

create table if not exists public.exercise_library (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null,
  primary_muscle text not null,
  equipment text not null,
  difficulty text not null default 'Beginner',
  default_sets integer default 3,
  default_reps text default '8-12',
  coaching_cue text,
  source_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  goal text,
  level text,
  duration_minutes integer,
  exercises jsonb not null default '[]'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.exercise_library enable row level security;
alter table public.workout_templates enable row level security;

drop policy if exists "exercise_library_read" on public.exercise_library;
create policy "exercise_library_read"
on public.exercise_library for select
to authenticated
using (is_active = true);

drop policy if exists "exercise_library_coach_manage" on public.exercise_library;
create policy "exercise_library_coach_manage"
on public.exercise_library for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

drop policy if exists "workout_templates_read" on public.workout_templates;
create policy "workout_templates_read"
on public.workout_templates for select
to authenticated
using (true);

drop policy if exists "workout_templates_coach_manage" on public.workout_templates;
create policy "workout_templates_coach_manage"
on public.workout_templates for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

-- Coach access to existing client tables.
drop policy if exists "profiles_coach_select" on public.profiles;
create policy "profiles_coach_select" on public.profiles
for select to authenticated
using (public.is_coach());

drop policy if exists "enrollments_coach_all" on public.enrollments;
create policy "enrollments_coach_all" on public.enrollments
for all to authenticated
using (public.is_coach())
with check (public.is_coach());

drop policy if exists "agreements_coach_select" on public.agreements;
create policy "agreements_coach_select" on public.agreements
for select to authenticated
using (public.is_coach());

drop policy if exists "intakes_coach_all" on public.intake_forms;
create policy "intakes_coach_all" on public.intake_forms
for all to authenticated
using (public.is_coach())
with check (public.is_coach());

drop policy if exists "progress_coach_select" on public.progress_entries;
create policy "progress_coach_select" on public.progress_entries
for select to authenticated
using (public.is_coach());

drop policy if exists "checkins_coach_all" on public.checkins;
create policy "checkins_coach_all" on public.checkins
for all to authenticated
using (public.is_coach())
with check (public.is_coach());

drop policy if exists "messages_coach_all" on public.messages;
create policy "messages_coach_all" on public.messages
for all to authenticated
using (public.is_coach())
with check (public.is_coach());

drop policy if exists "nutrition_coach_all" on public.nutrition_targets;
create policy "nutrition_coach_all" on public.nutrition_targets
for all to authenticated
using (public.is_coach())
with check (public.is_coach());

drop policy if exists "workouts_coach_all" on public.workout_assignments;
create policy "workouts_coach_all" on public.workout_assignments
for all to authenticated
using (public.is_coach())
with check (public.is_coach());

grant select, insert, update, delete on public.exercise_library to authenticated;
grant select, insert, update, delete on public.workout_templates to authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update on public.enrollments to authenticated;
grant select on public.agreements to authenticated;
grant select, insert, update on public.intake_forms to authenticated;
grant select on public.progress_entries to authenticated;
grant select, insert, update on public.checkins to authenticated;
grant select, insert, update on public.messages to authenticated;
grant select, insert, update on public.nutrition_targets to authenticated;
grant select, insert, update on public.workout_assignments to authenticated;

-- Make Jeremy's existing account a coach.
update public.profiles p
set role = 'coach', updated_at = now()
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('jeremyparr18@gmail.com');

-- Curated exercise names and coaching cues. Names/categories are common exercise terminology.
insert into public.exercise_library
(name,category,primary_muscle,equipment,difficulty,default_sets,default_reps,coaching_cue,source_url)
values
('Barbell Back Squat','Lower Body','Quadriceps','Barbell','Intermediate',4,'6-10','Brace before descending; keep the whole foot planted.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Goblet Squat','Lower Body','Quadriceps','Dumbbell','Beginner',3,'10-15','Keep the weight close and sit between the hips.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Leg Press','Lower Body','Quadriceps','Machine','Beginner',3,'10-15','Control depth and avoid locking the knees aggressively.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Romanian Deadlift','Lower Body','Hamstrings','Barbell','Intermediate',3,'8-12','Push the hips back while keeping the load close.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Hip Thrust','Lower Body','Glutes','Barbell','Intermediate',4,'8-12','Finish with the ribs down and squeeze the glutes.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Bulgarian Split Squat','Lower Body','Quadriceps','Dumbbell','Intermediate',3,'8-12/side','Use a stable stance and drive through the front foot.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Leg Curl','Lower Body','Hamstrings','Machine','Beginner',3,'10-15','Keep hips anchored and control the return.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Standing Calf Raise','Lower Body','Calves','Machine','Beginner',4,'10-15','Pause at the top and use a full controlled stretch.','https://www.acefitness.org/resources/everyone/exercise-library/'),

('Barbell Bench Press','Chest','Chest','Barbell','Intermediate',4,'6-10','Set the shoulder blades and keep feet planted.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Incline Dumbbell Press','Chest','Upper Chest','Dumbbell','Beginner',3,'8-12','Lower under control with wrists stacked.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Push-Up','Chest','Chest','Bodyweight','Beginner',3,'AMRAP','Maintain a straight line from head to heels.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Cable Fly','Chest','Chest','Cable','Beginner',3,'12-15','Bring the arms together without shrugging.','https://www.acefitness.org/resources/everyone/exercise-library/'),

('Lat Pulldown','Back','Lats','Cable','Beginner',3,'8-12','Drive elbows toward the ribs without leaning back excessively.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Seated Cable Row','Back','Mid Back','Cable','Beginner',3,'8-12','Keep the torso stable and finish with the elbows back.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Pull-Up','Back','Lats','Pull-up Bar','Intermediate',3,'AMRAP','Start from a controlled hang and lead with the chest.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Chest-Supported Dumbbell Row','Back','Mid Back','Dumbbell','Beginner',3,'8-12','Keep the chest supported and avoid shrugging.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Single-Arm Cable Row','Back','Lats','Cable','Beginner',3,'10-15/side','Reach smoothly, then pull the elbow toward the hip.','https://www.acefitness.org/resources/everyone/exercise-library/'),

('Dumbbell Shoulder Press','Shoulders','Deltoids','Dumbbell','Beginner',3,'8-12','Keep the ribs stacked and press without overextending.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Cable Lateral Raise','Shoulders','Side Delts','Cable','Beginner',3,'12-20','Lead with the elbow and stop near shoulder height.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Reverse Pec Deck','Shoulders','Rear Delts','Machine','Beginner',3,'12-20','Keep shoulders down and sweep the arms back.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Face Pull','Shoulders','Rear Delts','Cable','Beginner',3,'12-15','Pull toward eye level while rotating the hands apart.','https://www.acefitness.org/resources/everyone/exercise-library/'),

('EZ-Bar Curl','Arms','Biceps','EZ Bar','Beginner',3,'8-12','Keep the upper arms still and avoid swinging.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Hammer Curl','Arms','Biceps','Dumbbell','Beginner',3,'10-15','Keep a neutral wrist and control the lowering phase.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Cable Triceps Pressdown','Arms','Triceps','Cable','Beginner',3,'10-15','Keep elbows pinned and fully extend without leaning.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Overhead Cable Triceps Extension','Arms','Triceps','Cable','Beginner',3,'10-15','Keep elbows forward and reach into a controlled stretch.','https://www.acefitness.org/resources/everyone/exercise-library/'),

('Plank','Core','Core','Bodyweight','Beginner',3,'30-60 sec','Brace the abs and maintain a neutral spine.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Dead Bug','Core','Core','Bodyweight','Beginner',3,'8-12/side','Keep the lower back gently pressed down.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Pallof Press','Core','Core','Cable','Beginner',3,'10-12/side','Resist rotation and keep the ribs over the pelvis.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Hanging Knee Raise','Core','Abs','Pull-up Bar','Intermediate',3,'8-15','Curl the pelvis upward without swinging.','https://www.acefitness.org/resources/everyone/exercise-library/'),

('Walking','Cardio','Full Body','No Equipment','Beginner',1,'20-45 min','Use a sustainable pace and relaxed posture.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Incline Treadmill Walk','Cardio','Full Body','Treadmill','Beginner',1,'15-30 min','Use a pace that allows controlled breathing.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Stationary Bike Intervals','Cardio','Full Body','Bike','Intermediate',8,'30 sec hard / 60 sec easy','Keep hard intervals challenging but repeatable.','https://www.acefitness.org/resources/everyone/exercise-library/'),
('Stair Climber','Cardio','Lower Body','Stair Climber','Intermediate',1,'10-25 min','Stand tall and avoid leaning heavily on the handles.','https://www.acefitness.org/resources/everyone/exercise-library/')
on conflict (name) do update set
 category=excluded.category,primary_muscle=excluded.primary_muscle,equipment=excluded.equipment,
 difficulty=excluded.difficulty,default_sets=excluded.default_sets,default_reps=excluded.default_reps,
 coaching_cue=excluded.coaching_cue,source_url=excluded.source_url,is_active=true;

insert into public.workout_templates (name,goal,level,duration_minutes,exercises)
values
('JP Fit Beginner Full Body','General Fitness','Beginner',45,
 '[{"name":"Goblet Squat","sets":3,"reps":"10-12"},{"name":"Incline Dumbbell Press","sets":3,"reps":"8-12"},{"name":"Lat Pulldown","sets":3,"reps":"8-12"},{"name":"Romanian Deadlift","sets":3,"reps":"10"},{"name":"Cable Lateral Raise","sets":2,"reps":"15"},{"name":"Plank","sets":3,"reps":"30 sec"}]'::jsonb),
('JP Fit Upper Body Strength','Strength','Intermediate',60,
 '[{"name":"Barbell Bench Press","sets":4,"reps":"5-8"},{"name":"Pull-Up","sets":4,"reps":"AMRAP"},{"name":"Dumbbell Shoulder Press","sets":3,"reps":"6-10"},{"name":"Seated Cable Row","sets":3,"reps":"8-12"},{"name":"EZ-Bar Curl","sets":3,"reps":"8-12"},{"name":"Cable Triceps Pressdown","sets":3,"reps":"10-15"}]'::jsonb),
('JP Fit Lower Body Strength','Strength','Intermediate',60,
 '[{"name":"Barbell Back Squat","sets":4,"reps":"5-8"},{"name":"Romanian Deadlift","sets":4,"reps":"6-10"},{"name":"Bulgarian Split Squat","sets":3,"reps":"8-10/side"},{"name":"Leg Curl","sets":3,"reps":"10-15"},{"name":"Standing Calf Raise","sets":4,"reps":"10-15"},{"name":"Pallof Press","sets":3,"reps":"10/side"}]'::jsonb),
('JP Fit Fat Loss Circuit','Fat Loss','Beginner',35,
 '[{"name":"Goblet Squat","sets":3,"reps":"12"},{"name":"Push-Up","sets":3,"reps":"AMRAP"},{"name":"Seated Cable Row","sets":3,"reps":"12"},{"name":"Walking","sets":1,"reps":"20 min"},{"name":"Dead Bug","sets":3,"reps":"10/side"}]'::jsonb)
on conflict (name) do update set
 goal=excluded.goal,level=excluded.level,duration_minutes=excluded.duration_minutes,exercises=excluded.exercises;
