# Classflow v10 — 26-section backend foundation

This package preserves the existing v9 local frontend and adds a **Supabase SQL migration** at `supabase/001_academic_structure.sql`.

## Campus configuration
- Four actual degree branches: CSE, MnC, ECE, EE.
- Two UI streams: **CSE** (CSE + MnC) and **Electronics** (ECE + EE).
- **22 CSE-stream sections**: C01 through C22 (including C19).
- **4 Electronics-stream sections**: E01 through E04.
- Semester 1 and academic year 2026–27 seeded; schema supports other years/semesters.
- Exact branch-to-section allocation is **not provided**. Section-branch entries indicate possible stream membership, not confirmed student allocation.
- Section codes except C19 are **provisional**, not verified official designations.

## To set up
1. Create a Supabase project.
2. In Supabase SQL Editor, paste and run `supabase/001_academic_structure.sql`.
3. Check `select display_stream,count(*) from public.sections group by display_stream;` — expected 22 and 4.
4. Obtain the official section roster and subject assignments, then update codes and populate `subjects`/`section_subjects`.
5. Implement admin-controlled verification and restrictive RLS for profiles, enrollments, professor assignments, and deadlines **before** connecting real users.

## Important
The existing frontend still runs as a **local demo**. This migration does **not** connect the UI to Supabase or enable real authentication, multi-user synchronization, or professor permissions. Those require additional implementation and security review. Do not put a Supabase service-role key in browser code.
