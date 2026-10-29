# Classflow v12 — Administrator workspace

## What is implemented
- Verified-admin-only workspace: overview, pending student enrollment approvals/rejections, professor verification, subject creation, section-subject mapping, and professor teaching assignments.
- Supabase SECURITY DEFINER RPCs check the caller's verified admin role on every privileged write; browser UI alone never authorizes an operation.
- A student can submit a professor verification request using a guarded RPC. Admins can review it.
- All 26 existing sections are preserved. No changes to v11 local-only student dashboard.

## Install
1. Existing project: run `supabase/003_admin_console.sql` in Supabase SQL Editor **after** 001 and 002. It does not reset your database.
2. Verify an account's email and sign in at least once to create its `profiles` row.
3. **Bootstrap exactly one trusted administrator manually in SQL Editor**, substituting your actual auth user UUID from Authentication → Users:
   ```sql
   UPDATE public.profiles SET role='admin', verified=true WHERE id='YOUR-AUTH-USER-UUID';
   ```
   Check the result: `SELECT id,role,verified FROM public.profiles WHERE id='YOUR-AUTH-USER-UUID';`.
4. Set `.env.local` using your existing Supabase URL and **publishable** key. Never paste a service-role key into frontend code.
5. `npm.cmd install` then `npm.cmd run dev`; sign in with the admin account. Refresh after promoting the account if already signed in.

## Security and caveats
- No frontend route or localStorage flag can grant admin status. Only a trusted database operator can bootstrap the first admin.
- Enrollment rejection currently deletes the pending request (student can resubmit). A permanent audit trail and admin history are future work.
- Professor requests are supported, but institutional identity verification is a human administrator's responsibility.
- The initial SQL 002 permits enrollment requests from authenticated users. Enrollment approval does not yet unlock a live student dashboard; v11 demo remains local-only.
- Existing schema does not contain cloud timetable or assignment records. This version **does not claim** to implement them.
- Admin can manage the section/subject relationships; 26 sections exist but subjects must be populated using the new console.
- Supabase email sending limits still apply. This release does not depend on additional email requests for the migration.
