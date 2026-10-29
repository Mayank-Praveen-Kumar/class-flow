# Classflow v11 — authentication foundation

1. Supabase SQL Editor: run `supabase/002_authentication.sql` AFTER v10 migration.
2. Authentication > Providers > Email: enable email/password and email confirmation.
3. Authentication > URL Configuration: set Site URL to your local Vite origin (usually http://localhost:5173) and add it to Redirect URLs. For production, use your deployed origin.
4. Copy `.env.example` to `.env.local` and paste your **project URL** and **publishable** key. NEVER paste service_role/secret keys.
5. In PowerShell: `npm.cmd install` then `npm.cmd run dev`.
6. Create a student account, confirm email, sign in, select branch/section, and request enrollment.
7. Supabase Table Editor: see `profiles` and `enrollments`. The enrollment remains `approved=false` until a trusted administrator approves it.

## Scope and safeguards
- Real Supabase Auth sign-up, email verification, sign-in, sign-out, and student enrollment requests are implemented.
- All existing Classflow pages are **explicitly offline demo only**; tasks, timetable, heatmap, professor role switch, and documents still use localStorage. They do not read/write Supabase and MUST NOT be treated as official data.
- Professor accounts cannot self-assign. The profile trigger always sets `role=student` and `verified=false` regardless of signup metadata.
- Profiles are read-only to their owners. Enrollment can be inserted only for self, pending approval, with compatible branch and section. No client UPDATE/DELETE or approval policies.
- The migration does not retroactively create profiles for preexisting Auth users. Ask for a separate backfill if necessary.
- Never turn off RLS to fix an error. Do not enable auto-confirm email in production.
- Approval workflow, shared assignments, professor access, cloud storage, and actual dashboard synchronization are NOT implemented yet.
