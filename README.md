# Classflow

**A shared academic deadline planner for students, professors, and administrators.**

Classflow brings assignments, projects, calendars, and progress tracking into one workspace so students can see what is due and faculty can keep deadlines consistent across a section.

## Features

- **Student dashboard:** shared deadlines, subject views, and personal completion tracking.
- **Calendar and heatmap:** week and month views with completed and overdue indicators. Heatmap intensity reflects deadline count.
- **Faculty workspace:** verified professors publish and edit deadlines for their assigned section–subject pairs.
- **Admin console:** manage academic structure, enrollment approvals, professor verification, and teaching assignments.
- **Cloud sync:** Supabase authentication, shared deadline records, private student progress, and realtime updates with manual refresh as a fallback.
- **Timetable and document tools:** local timetable, PDF/OCR utilities, and document workflows.
- **26 sections:** C01–C22 for CSE/MNC and E01–E04 for Electronics (ECE/EE).

## Current version

The latest source on `main` is **v15 layout fixed**. The original student dashboard now reads cloud deadlines and personal progress. Faculty and admin workspaces retain their role-based access.

Timetables, academic exceptions, uploaded files, documents, and notification history remain local. The bundled C19 timetable is shown only for C19. Students cannot publish or edit official shared deadlines from the merged dashboard.

## Tech stack

| Layer | Technology |
| --- | --- |
| Interface | React 19, CSS, Lucide icons |
| Development and builds | Vite 6 |
| Authentication and database | Supabase Auth, PostgreSQL, Row Level Security |
| PDF and OCR | PDF.js, Tesseract.js |

## Run locally

Install Node.js compatible with Vite 6 (Node 22 is a suitable choice), npm, and Git.

```bash
git clone https://github.com/Mayank-Praveen-Kumar/class-flow.git
cd class-flow
npm install
```

Copy `.env.example` to `.env.local` beside `package.json`, then supply your Supabase values:

```dotenv
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Use the project publishable key; never put a service-role or secret key in frontend environment variables. Keep `.env.local` out of version control.

```bash
npm run dev
```

Open the local URL printed by Vite. On Windows PowerShell, use `npm.cmd` if script execution policy prevents running `npm`.

## Configure Supabase

For a new project, apply the SQL files in `supabase/` in order through the Supabase SQL Editor:

1. `001_academic_structure.sql`
2. `002_authentication.sql`
3. `003_admin_console.sql`
4. `004_cloud_deadlines.sql`
5. `005_progress_realtime.sql`

For an existing database, apply only missing migrations; earlier policies may not be safe to rerun.

Enable email/password authentication and email confirmation. Configure the Site URL and allowed redirect URLs for your local Vite origin and, when deployed, your production origin.

Create and verify an account, then request enrollment for the appropriate branch and section. A trusted administrator must approve enrollment. Bootstrap the first administrator through trusted Supabase administration by setting their `public.profiles` role to `admin` and `verified` to `true`. Professor verification and section–subject assignments are managed through the admin workflow. Configure section subjects before publishing deadlines.

Keep RLS enabled. Cloud access depends on the database policies, verified roles, and approved enrollment. Realtime publications are configured by migrations 004 and 005.

## Build

```bash
npm run build
npm run preview
```

Vite outputs the production site to `dist/`. Configure the same frontend environment variables in your hosting environment before building, and update Supabase authentication URLs for the deployed site.

## Repository guide

| Path | Purpose |
| --- | --- |
| `src/` | React interface, planner, authentication, and role-based workspaces |
| `supabase/` | Database, authorization, and realtime migrations |
| `.env.example` | Required frontend configuration template |
| `C19_Sem1_Timetable.json` | Bundled C19 timetable |
| `README-V*.md` and `README-*.txt` | Version-specific notes and setup details |

## Version history

All **17 available source versions** are preserved as individual commits and tags, from the original Campus Deadline prototype through the v15 layout fix.

- [Browse commit history](https://github.com/Mayank-Praveen-Kumar/class-flow/commits/main/)
- [Browse version tags and download snapshots](https://github.com/Mayank-Praveen-Kumar/class-flow/tags)
- [Read v15 implementation notes](README-V15.md)

To inspect an older version locally:

```bash
git fetch --tags
git tag --list
git switch --detach classflow-v15-layout-fixed
```

Run `git switch main` to return to the latest source.

## Scope and limitations

Classflow is an evolving college project. Cloud deadlines and personal progress are synchronized; local timetable and document data are not shared across devices. Existing local tasks are not automatically migrated into cloud records. OCR output needs review, and email delivery depends on Supabase SMTP configuration and rate limits. Validate authorization policies and workflows in your own Supabase project before relying on it for official academic use.

## License

Licensed under [GNU General Public License v3.0](LICENSE).
