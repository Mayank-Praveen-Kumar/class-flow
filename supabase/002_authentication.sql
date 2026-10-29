-- Run AFTER 001_academic_structure.sql. Student self-registration only.
-- A new auth user receives a student profile. No client can elevate role or verification.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,full_name,role,verified,college_id)
 values(new.id, left(coalesce(new.raw_user_meta_data->>'full_name',''),150), 'student', false,
        (select id from public.colleges where code='MIT_BLR' limit 1))
 on conflict (id) do nothing;
 return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();
-- Restrict profiles to the owner; no client write policies are granted.
drop policy if exists "profile owner read" on public.profiles;
create policy "profile owner read" on public.profiles for select to authenticated
using (id=(select auth.uid()));
-- Users can request their own enrollment, but cannot approve it.
-- Branch must be valid for section's display stream; semester/year fixed by selected section.
drop policy if exists "enrollment owner read" on public.enrollments;
create policy "enrollment owner read" on public.enrollments for select to authenticated
using (user_id=(select auth.uid()));
drop policy if exists "enrollment request" on public.enrollments;
create policy "enrollment request" on public.enrollments for insert to authenticated
with check (
 user_id=(select auth.uid()) and approved=false and
 exists(select 1 from public.sections s join public.branches b on b.code=branch_code
 where s.id=section_id and s.display_stream=b.display_stream)
);
-- No UPDATE or DELETE policies for enrollment: approvals require trusted administrator SQL.
-- No professor role changes or assignment write policies granted to clients.
