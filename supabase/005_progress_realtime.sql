-- Optional v14 enhancement: synchronize student progress across their open devices.
-- Run once after 004_cloud_deadlines.sql.
do $$ begin
 if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='deadline_progress') then
  alter publication supabase_realtime add table public.deadline_progress;
 end if;
end $$;
