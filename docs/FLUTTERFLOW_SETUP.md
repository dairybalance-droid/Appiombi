# FlutterFlow Setup

## Purpose

This document explains how to connect FlutterFlow to the existing Appiombi Supabase project if FlutterFlow is used as a secondary prototype or exploratory UI tool.

Strategic note:

- FlutterFlow is no longer the recommended primary implementation path for Appiombi
- the recommended primary stack is pure Flutter native + Supabase + GitHub + Codex
- this document remains useful for prototype experiments, stakeholder previews, or temporary visual validation

## Current Backend Status

Confirmed as already available in Supabase:

- test farmer auth user
- linked profile
- test farm
- active farm owner membership
- active test subscription
- test cows `101`, `234`, `789`
- farm address fields for company disambiguation

## 1. Where To Find Project URL And Anon Key In Supabase

In Supabase dashboard:

1. Open the Appiombi Supabase project.
2. Go to `Project Settings`.
3. Open `API`.
4. Copy:
   - `Project URL`
   - `anon public` key

Use only:

- Project URL
- anon key

Do not use:

- service role key
- database passwords
- JWT secrets

## 2. How To Connect Supabase In FlutterFlow

In FlutterFlow:

1. Open the Appiombi FlutterFlow project.
2. Go to `Settings & Integrations`.
3. Open `Supabase`.
4. Paste:
   - Project URL
   - anon key
5. Save the integration.
6. Verify table and auth access.

## 3. Authentication Setup In FlutterFlow

Enable and configure:

- email/password sign up
- login
- logout
- password reset

Important:

- Appiombi uses Supabase Auth as the source of authentication truth.
- Full app access depends on backend state too:
  - verified email
  - active profile
  - required legal consents
  - farm-level access via RLS

FlutterFlow should handle the visible auth flows, but backend gating must remain authoritative.

## 4. Data Sources To Import In FlutterFlow First

Prioritize these:

- `profiles`
- `farms`
- `farm_access_modes`
- `active_farm_users`
- `active_animals`
- `active_trimming_sessions`
- `active_cow_visits`
- `active_clinical_tasks`

Secondary for later:

- `farm_invites`
- `trimming_session_days`
- `active_claw_observations`

## 5. Navigation Rule

All app navigation and record selection must use:

- `farms.id`
- `cows.id`
- `trimming_sessions.id`
- `cow_visits.id`

Never use display names as identifiers.

Farm name is display-only and may be duplicated across farms.

## 6. What FlutterFlow Can Handle As Secondary Tool

- login and logout screens
- email/password forms
- farm list pages
- dashboard list widgets
- basic detail pages
- simple form submission
- session list views
- cow list views

These are best treated as prototype-level or exploratory screens unless the team intentionally chooses FlutterFlow for a non-production branch.

## 7. What Must Stay Outside Pure FlutterFlow For Now

Not to implement yet inside FlutterFlow-only logic:

- custom offline sync engine
- local SQLite/Drift persistence
- conflict queue handling
- advanced podal map logic
- secure background retry flows

These are native mobile custom Dart responsibilities for later phases.

## 8. Recommendation

For Appiombi production development:

- prefer pure Flutter native for implementation
- use FlutterFlow only if needed for rapid mockup or UI exploration
- do not make FlutterFlow the source of truth for offline-first or custom clinical workflows

## 9. Immediate Validation After Connection

Once FlutterFlow is connected:

1. confirm Auth works with test user
2. confirm `profiles` row is readable after login
3. confirm test farm is visible
4. confirm `farm_access_modes` shows writable access for the owner
5. confirm the three test cows are visible through `active_animals`
