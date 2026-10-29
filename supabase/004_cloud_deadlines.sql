-- Classflow v13: execute after migrations 001–003.
-- Shared deadlines are scoped to a section and its assigned subject.
create table if not exists public.deadlines (
 id uuid primary key default gen_random_uuid(),
 section_id uuid not null,
 subject_id uuid not null,
 title text not null check (length(trim(title)) between 3 and 180),
 description text not null default '',
 due_at timestamptz not null,
 size text not null default 'medium' check(size in ('small','medium','large')),
 estimated_hours numeric(6,2) not null default 6 check(estimated_hours > 0 and estimated_hours <= 500),
 created_by uuid not null references public.profiles(id),
 updated_by uuid references public.profiles(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 foreign key(section_id,subject_id) references public.section_subjects(section_id,subject_id)
);
create index if not exists deadlines_section_due_idx on public.deadlines(section_id,due_at);
create table if not exists public.deadline_progress (
 deadline_id uuid not null references public.deadlines(id) on delete cascade,
 student_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'not_started' check(status in ('not_started','in_progress','completed')),
 updated_at timestamptz not null default now(),
 primary key(deadline_id,student_id)
);
create table if not exists public.deadline_audit (
 id bigint generated always as identity primary key,
 deadline_id uuid not null references public.deadlines(id) on delete cascade,
 changed_by uuid not null references public.profiles(id),
 changed_at timestamptz not null default now(),
 action text not null check(action in ('created','updated','deleted')),
 old_record jsonb,
 new_record jsonb
);
alter table public.deadlines enable row level security;
alter table public.deadline_progress enable row level security;
alter table public.deadline_audit enable row level security;
-- A student needs an approved enrollment to read a deadline; a professor must be assigned to its section and subject.
create or replace function public.cf_can_read_deadline(p_section uuid,p_subject uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select (select public.cf_is_admin())
 or exists(select 1 from public.enrollments e where e.user_id=(select auth.uid()) and e.section_id=p_section and e.approved=true)
 or exists(select 1 from public.professor_assignments pa join public.profiles p on p.id=pa.professor_id
           where pa.professor_id=(select auth.uid()) and pa.section_id=p_section and pa.subject_id=p_subject and p.role='professor' and p.verified=true);
$$;
revoke all on function public.cf_can_read_deadline(uuid,uuid) from public;
grant execute on function public.cf_can_read_deadline(uuid,uuid) to authenticated;
create policy "deadline authorized read" on public.deadlines for select to authenticated
 using (public.cf_can_read_deadline(section_id,subject_id));
create policy "own progress read" on public.deadline_progress for select to authenticated
 using (student_id=(select auth.uid()) and exists(select 1 from public.deadlines d where d.id=deadline_id));
create policy "own progress insert" on public.deadline_progress for insert to authenticated
 with check (student_id=(select auth.uid()) and exists(select 1 from public.deadlines d where d.id=deadline_id and exists
  (select 1 from public.enrollments e where e.user_id=(select auth.uid()) and e.section_id=d.section_id and e.approved=true)));
create policy "own progress update" on public.deadline_progress for update to authenticated
 using (student_id=(select auth.uid())) with check (student_id=(select auth.uid()));
create policy "admin audit read" on public.deadline_audit for select to authenticated using (public.cf_is_admin());
-- Privileged publishing is performed by a checked RPC, not a direct browser INSERT.
create or replace function public.cf_publish_deadline(p_section_id uuid,p_subject_id uuid,p_title text,p_description text,p_due_at timestamptz,p_size text,p_estimated_hours numeric,p_deadline_id uuid default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_old jsonb; v_new jsonb;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if not (public.cf_is_admin() or exists (
   select 1 from public.professor_assignments pa join public.profiles p on p.id=pa.professor_id
   where pa.professor_id=auth.uid() and pa.section_id=p_section_id and pa.subject_id=p_subject_id
     and p.role='professor' and p.verified=true)) then
   raise exception 'You are not assigned to publish for this section and subject';
 end if;
 if not exists(select 1 from public.section_subjects where section_id=p_section_id and subject_id=p_subject_id) then
   raise exception 'Subject is not assigned to section'; end if;
 if length(trim(coalesce(p_title,''))) not between 3 and 180 then raise exception 'Title must be 3–180 characters'; end if;
 if p_size not in ('small','medium','large') or p_estimated_hours <= 0 or p_estimated_hours > 500 then
   raise exception 'Invalid workload estimate'; end if;
 if p_due_at is null then raise exception 'Due date is required'; end if;
 if p_deadline_id is null then
   insert into public.deadlines(section_id,subject_id,title,description,due_at,size,estimated_hours,created_by,updated_by)
   values(p_section_id,p_subject_id,trim(p_title),coalesce(p_description,''),p_due_at,p_size,p_estimated_hours,auth.uid(),auth.uid()) returning id into v_id;
   select to_jsonb(d) into v_new from public.deadlines d where d.id=v_id;
   insert into public.deadline_audit(deadline_id,changed_by,action,new_record) values(v_id,auth.uid(),'created',v_new);
 else
   select to_jsonb(d) into v_old from public.deadlines d where d.id=p_deadline_id for update;
   if v_old is null then raise exception 'Deadline not found'; end if;
   -- A professor cannot edit a deadline belonging to a section/subject they do not teach.
   if not public.cf_is_admin() and not exists (
      select 1 from public.professor_assignments pa join public.profiles p on p.id=pa.professor_id
      where pa.professor_id=auth.uid() and pa.section_id=(v_old->>'section_id')::uuid
        and pa.subject_id=(v_old->>'subject_id')::uuid and p.role='professor' and p.verified=true) then
      raise exception 'Not authorized to edit this deadline'; end if;
   update public.deadlines set section_id=p_section_id,subject_id=p_subject_id,title=trim(p_title),description=coalesce(p_description,''),
     due_at=p_due_at,size=p_size,estimated_hours=p_estimated_hours,updated_by=auth.uid(),updated_at=now()
     where id=p_deadline_id returning id into v_id;
   select to_jsonb(d) into v_new from public.deadlines d where d.id=v_id;
   insert into public.deadline_audit(deadline_id,changed_by,action,old_record,new_record)
   values(v_id,auth.uid(),'updated',v_old,v_new);
 end if;
 return v_id;
end;
$$;
revoke all on function public.cf_publish_deadline(uuid,uuid,text,text,timestamptz,text,numeric,uuid) from public;
grant execute on function public.cf_publish_deadline(uuid,uuid,text,text,timestamptz,text,numeric,uuid) to authenticated;
-- Enable Realtime for deadline updates (run once).
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='deadlines') then
  alter publication supabase_realtime add table public.deadlines;
 end if;
end $$;
