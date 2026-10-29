-- Classflow academic structure: 26 sections, two display streams.
-- Run once in Supabase SQL Editor. Does not grant users access or create authentication.
create extension if not exists pgcrypto;
create table if not exists public.colleges (
 id uuid primary key default gen_random_uuid(), code text not null unique, name text not null
);
create table if not exists public.academic_years (
 id uuid primary key default gen_random_uuid(), college_id uuid not null references public.colleges(id), label text not null,
 unique(college_id,label)
);
create table if not exists public.branches (
 code text primary key, name text not null, display_stream text not null check(display_stream in ('CSE','Electronics'))
);
insert into public.branches(code,name,display_stream) values
 ('CSE','Computer Science and Engineering','CSE'),
 ('MNC','Mathematics and Computing','CSE'),
 ('ECE','Electronics and Communication Engineering','Electronics'),
 ('EE','Electrical Engineering','Electronics')
on conflict(code) do update set name=excluded.name,display_stream=excluded.display_stream;
create table if not exists public.sections (
 id uuid primary key default gen_random_uuid(),
 academic_year_id uuid not null references public.academic_years(id),
 code text not null,
 display_stream text not null check(display_stream in ('CSE','Electronics')),
 semester integer not null check(semester between 1 and 12),
 unique(academic_year_id,code,semester)
);
-- Section stream is a UI grouping, not a claim that every student has the same degree branch.
create table if not exists public.section_branches (
 section_id uuid not null references public.sections(id) on delete cascade,
 branch_code text not null references public.branches(code),
 primary key(section_id,branch_code)
);
create table if not exists public.subjects (
 id uuid primary key default gen_random_uuid(),
 college_id uuid not null references public.colleges(id),
 code text not null, name text not null,
 unique(college_id,code)
);
create table if not exists public.section_subjects (
 section_id uuid not null references public.sections(id) on delete cascade,
 subject_id uuid not null references public.subjects(id) on delete cascade,
 primary key(section_id,subject_id)
);
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text, role text not null default 'student' check(role in ('student','professor','admin')),
 verified boolean not null default false,
 college_id uuid references public.colleges(id)
);
create table if not exists public.enrollments (
 user_id uuid not null references public.profiles(id) on delete cascade,
 section_id uuid not null references public.sections(id) on delete cascade,
 branch_code text not null references public.branches(code),
 approved boolean not null default false,
 primary key(user_id,section_id)
);
create table if not exists public.professor_assignments (
 professor_id uuid not null references public.profiles(id) on delete cascade,
 section_id uuid not null references public.sections(id) on delete cascade,
 subject_id uuid not null references public.subjects(id) on delete cascade,
 primary key(professor_id,section_id,subject_id)
);
insert into public.colleges(code,name) values ('MIT_BLR','MIT Bengaluru') on conflict(code) do nothing;
insert into public.academic_years(college_id,label)
select id,'2026-27' from public.colleges where code='MIT_BLR'
on conflict(college_id,label) do nothing;
-- Provisional section IDs: C01..C22 and E01..E04. Rename when official roster is known.
insert into public.sections(academic_year_id,code,display_stream,semester)
select ay.id,'C'||lpad(n::text,2,'0'),'CSE',1
from public.academic_years ay join public.colleges c on c.id=ay.college_id
cross join generate_series(1,22) n where c.code='MIT_BLR' and ay.label='2026-27'
on conflict(academic_year_id,code,semester) do nothing;
insert into public.sections(academic_year_id,code,display_stream,semester)
select ay.id,'E'||lpad(n::text,2,'0'),'Electronics',1
from public.academic_years ay join public.colleges c on c.id=ay.college_id
cross join generate_series(1,4) n where c.code='MIT_BLR' and ay.label='2026-27'
on conflict(academic_year_id,code,semester) do nothing;
-- C19 is included as one of the 22 CSE-stream sections.
-- Branch mapping represents eligible branch categories, NOT a verified allocation by section.
insert into public.section_branches(section_id,branch_code)
select s.id,b.code from public.sections s cross join public.branches b
where (s.display_stream='CSE' and b.display_stream='CSE')
   or (s.display_stream='Electronics' and b.display_stream='Electronics')
on conflict do nothing;
-- Restrict access until specific, reviewed policies are added.
alter table public.colleges enable row level security;
alter table public.academic_years enable row level security;
alter table public.branches enable row level security;
alter table public.sections enable row level security;
alter table public.section_branches enable row level security;
alter table public.subjects enable row level security;
alter table public.section_subjects enable row level security;
alter table public.profiles enable row level security;
alter table public.enrollments enable row level security;
alter table public.professor_assignments enable row level security;
-- Public read of non-sensitive academic catalogue only.
create policy "read colleges" on public.colleges for select to authenticated using (true);
create policy "read years" on public.academic_years for select to authenticated using (true);
create policy "read branches" on public.branches for select to authenticated using (true);
create policy "read sections" on public.sections for select to authenticated using (true);
create policy "read section branch options" on public.section_branches for select to authenticated using (true);
create policy "read subjects" on public.subjects for select to authenticated using (true);
create policy "read section subjects" on public.section_subjects for select to authenticated using (true);
-- Profiles, enrollment and professor assignment policies deliberately not yet added.
-- Enrollment approval and role changes must happen via trusted admin backend.
