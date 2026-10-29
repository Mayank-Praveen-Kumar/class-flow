-- Classflow v12: execute after 001 and 002. Run in Supabase SQL Editor as project owner.
-- All privileged writes are SECURITY DEFINER RPCs, guarded by auth.uid() admin role.
create or replace function public.cf_is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and role='admin' and verified=true);
$$;
revoke all on function public.cf_is_admin() from public;
grant execute on function public.cf_is_admin() to authenticated;

-- Admins can read pending enrollment and professor records. Non-admins retain their own reads.
create policy "admin enrollment read" on public.enrollments for select to authenticated using (public.cf_is_admin());
create policy "admin profile read" on public.profiles for select to authenticated using (public.cf_is_admin());
create policy "admin professor assignment read" on public.professor_assignments for select to authenticated using (public.cf_is_admin());

create table if not exists public.professor_requests (
 user_id uuid primary key references public.profiles(id) on delete cascade,
 requested_at timestamptz not null default now(),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 reviewed_at timestamptz,
 reviewed_by uuid references public.profiles(id)
);
alter table public.professor_requests enable row level security;
create policy "professor request own read" on public.professor_requests for select to authenticated using (user_id=(select auth.uid()));
create policy "professor request admin read" on public.professor_requests for select to authenticated using (public.cf_is_admin());
-- No direct client INSERT/UPDATE/DELETE policies; requests and reviews use checked RPCs.
create or replace function public.cf_request_professor() returns void
language plpgsql security definer set search_path = '' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.profiles where id=auth.uid() and role='student') then
  raise exception 'Only student-role accounts can request professor verification';
 end if;
 insert into public.professor_requests(user_id) values(auth.uid())
 on conflict(user_id) do update set status='pending', requested_at=now(), reviewed_at=null, reviewed_by=null;
end;
$$;
revoke all on function public.cf_request_professor() from public;
grant execute on function public.cf_request_professor() to authenticated;

create or replace function public.cf_review_enrollment(p_user_id uuid,p_section_id uuid,p_approve boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.cf_is_admin() then raise exception 'Administrator permission required'; end if;
 if not exists(select 1 from public.enrollments where user_id=p_user_id and section_id=p_section_id) then
  raise exception 'Enrollment request not found';
 end if;
 if p_approve then
  update public.enrollments set approved=true where user_id=p_user_id and section_id=p_section_id;
 else
  delete from public.enrollments where user_id=p_user_id and section_id=p_section_id;
 end if;
end;
$$;
revoke all on function public.cf_review_enrollment(uuid,uuid,boolean) from public;
grant execute on function public.cf_review_enrollment(uuid,uuid,boolean) to authenticated;

create or replace function public.cf_review_professor(p_user_id uuid,p_approve boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.cf_is_admin() then raise exception 'Administrator permission required'; end if;
 if p_user_id=auth.uid() then raise exception 'Cannot review your own account'; end if;
 if not exists(select 1 from public.professor_requests where user_id=p_user_id and status='pending') then
  raise exception 'Pending professor request not found';
 end if;
 update public.professor_requests set status=case when p_approve then 'approved' else 'rejected' end,
 reviewed_at=now(), reviewed_by=auth.uid() where user_id=p_user_id;
 if p_approve then update public.profiles set role='professor',verified=true where id=p_user_id; end if;
end;
$$;
revoke all on function public.cf_review_professor(uuid,boolean) from public;
grant execute on function public.cf_review_professor(uuid,boolean) to authenticated;

create or replace function public.cf_set_section_subject(p_section_id uuid,p_subject_id uuid,p_add boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.cf_is_admin() then raise exception 'Administrator permission required'; end if;
 if p_add then insert into public.section_subjects(section_id,subject_id) values(p_section_id,p_subject_id) on conflict do nothing;
 else delete from public.section_subjects where section_id=p_section_id and subject_id=p_subject_id; end if;
end;
$$;
revoke all on function public.cf_set_section_subject(uuid,uuid,boolean) from public;
grant execute on function public.cf_set_section_subject(uuid,uuid,boolean) to authenticated;

create or replace function public.cf_create_subject(p_code text,p_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if not public.cf_is_admin() then raise exception 'Administrator permission required'; end if;
 if length(trim(p_code))<2 or length(trim(p_name))<2 then raise exception 'Provide subject code and name'; end if;
 insert into public.subjects(college_id,code,name)
 select id,upper(trim(p_code)),trim(p_name) from public.colleges where code='MIT_BLR'
 on conflict(college_id,code) do update set name=excluded.name returning id into v_id;
 return v_id;
end;
$$;
revoke all on function public.cf_create_subject(text,text) from public;
grant execute on function public.cf_create_subject(text,text) to authenticated;

create or replace function public.cf_set_professor_assignment(p_professor_id uuid,p_section_id uuid,p_subject_id uuid,p_add boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if not public.cf_is_admin() then raise exception 'Administrator permission required'; end if;
 if p_add then
  if not exists(select 1 from public.profiles where id=p_professor_id and role='professor' and verified=true) then
   raise exception 'Professor must be verified'; end if;
  if not exists(select 1 from public.section_subjects where section_id=p_section_id and subject_id=p_subject_id) then
   raise exception 'Assign the subject to the section first'; end if;
  insert into public.professor_assignments(professor_id,section_id,subject_id)
  values(p_professor_id,p_section_id,p_subject_id) on conflict do nothing;
 else
  delete from public.professor_assignments where professor_id=p_professor_id and section_id=p_section_id and subject_id=p_subject_id;
 end if;
end;
$$;
revoke all on function public.cf_set_professor_assignment(uuid,uuid,uuid,boolean) from public;
grant execute on function public.cf_set_professor_assignment(uuid,uuid,uuid,boolean) to authenticated;

-- BOOTSTRAP YOUR FIRST ADMIN MANUALLY AFTER EMAIL CONFIRMATION AND SIGN-IN:
-- Find your user ID under Authentication > Users, then replace the UUID below and run separately:
-- UPDATE public.profiles SET role='admin',verified=true WHERE id='YOUR-AUTH-USER-UUID';
-- Never run this for an untrusted account. Never expose service-role credentials in React.
