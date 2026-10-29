# Classflow v14 — Live calendar and heatmap

## What's new
- Live calendar backed by Supabase `deadlines` and `deadline_progress`.
- Toggle between **Calendar** and **Heatmap** and between **Week** and **Month**.
- Navigate periods, jump to today, and click any day to view assignments.
- Student progress changes propagate to the calendar/heatmap immediately after the Supabase write.
- Completed deadlines remain visible, with distinct visual indicators.
- Fixed a malformed `if(!backendConfigured)` conditional in AuthGate that previously caused admin users to see the enrollment screen even when their role was admin.

## Install
1. Use your existing Supabase project. Run migrations 001–004 from prior versions if not already applied. **No new SQL migration is needed for v14.**
2. Copy `.env.local` from v13 into this `campus-deadline` folder.
3. Run `npm.cmd install`, then `npm.cmd run dev`.
4. Sign in as an approved student, verified professor, or admin. Open **Calendar & heatmap** in the cloud workspace.

## Important scope
- Cloud planner shows Supabase deadlines only. It does not show offline demo deadlines, timetable slots, holidays or lecture cancellations.
- A student needs approved enrollment to see cloud deadlines.
- Professors and admins see their authorized deadline data; individual progress belongs to students.
- The heatmap intensity represents deadline *count*, with completion and overdue counts displayed in cells.
- Supabase Realtime must be enabled for `deadlines` as in migration 004.
