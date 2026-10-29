# Classflow v15 — merged student dashboard

## Installation

Use the same Supabase database as v14. No new SQL migration is needed.
Copy the **working** `.env.local` from v14 into this `campus-deadline` directory (beside `package.json`). Run `npm.cmd install` and `npm.cmd run dev`.

## Student experience

An approved student now lands in the **original Classflow dashboard** with live Supabase deadlines and personal progress. Dashboard, calendar, week/month heatmap, and subject views read the same cloud deadline records. Progress controls update `deadline_progress` through Supabase. A green cloud banner shows the active section and provides Refresh and Sign out.

The timetable and academic exceptions are **local-only**; the bundled C19 timetable is shown only for C19, not falsely assigned to other sections. Documents, uploaded files, and notification history are also local. Student creation/editing of shared deadlines is disabled in this merged view because official publishing requires verified faculty/admin permissions. Faculty and administrator workspaces remain unchanged.

## Test plan

1. Log in with an approved C19 student account. Verify the existing published deadline appears in Dashboard, Calendar, and Heatmap.
2. Mark it completed, reload the browser, and confirm the completed state persists.
3. Open another browser signed into the same account and verify changes refresh (or click Refresh).
4. Confirm other sections cannot see C19-only deadlines, using separate approved accounts.
5. Log in as administrator and professor and confirm their existing workspaces still open.

## Limitations

No migration of existing local personal tasks, documents, or academic exceptions. Cloud assignment editing is available in the existing faculty/admin cloud workspace, not the student wizard. Live Supabase authorization depends on the existing RLS policies. This build has not been tested against your private Supabase project.
