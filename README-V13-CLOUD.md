# Classflow v13 — cloud deadlines

## Database
Apply migrations `001`, `002`, `003` (if not already applied), then **only** `supabase/004_cloud_deadlines.sql` in Supabase SQL Editor. Do not rerun earlier non-idempotent policies.

## Setup
Copy `.env.example` to `.env.local`, enter the Supabase project URL and publishable key. Run `npm.cmd install` then `npm.cmd run dev` from the `campus-deadline` directory.

## Access model
- Verified admin: admin console now includes a **Cloud deadlines** navigation button. Admin can publish for section-subject pairs.
- Verified professor: can publish/edit only for assigned section-subject pairs.
- Student: can see shared deadlines only after enrollment is approved; progress is private.
- No direct client writes to deadlines; publishing uses a security-definer function with role checks and an audit trail.
- C01–C22 and E01–E04 are preserved. Subjects must be assigned to sections via the admin console before publishing.

## Known limitations
- The legacy calendar/heatmap/timetable and its sample assignments are **still offline demo features**, not synchronized with this cloud workspace.
- Real-time events require the publication configuration in migration 004 and network access; Refresh is provided as a fallback.
- Email delivery is governed by Supabase SMTP configuration and rate limits.
- The authenticated admin must have `role='admin'` and `verified=true` in `public.profiles`; otherwise the admin console will not render. In v12 the admin console already had this guard; if the screenshot still showed onboarding, verify the running folder and any database fetch errors.
- Supabase SQL has not been executed against your project from this package. Review before applying.
