# Next Step Plan

## Current Status

The initial Supabase setup is complete.

Confirmed:

- `supabase/schema.sql` executed successfully
- `supabase/rls_policies.sql` executed successfully
- base tables available
- active views available
- initial backend structure is ready for the next implementation step

## 1. Supabase Auth Configuration Checklist

- Enable email/password sign-in in Supabase Auth.
- Enable email confirmation.
- Configure redirect URLs required for mobile auth flows.
- Configure reset-password email flow.
- Review default session duration and refresh behavior.
- Confirm no service role key is used in the mobile client.
- Prepare branded email templates, predisposizione futura if not needed immediately.
- Decide where `profiles.email_verified_at` is synchronized from the auth lifecycle.
- Decide where `profiles.account_status` transitions from `pending_verification` to `active`.
- Decide where required legal acceptance is checked before full app access.

## 2. First Test Farmer User Checklist

- Create one test auth user with a real test email inbox.
- Verify the email through the normal confirmation flow.
- Create the linked `profiles` row for that auth user.
- Set:
  - `default_role = 'farmer'`
  - `account_status = 'active'`
  - `is_active = true`
  - `email_verified_at` populated
- Insert required active `legal_documents` rows if not present yet.
- Insert matching required `user_consents` rows for:
  - `privacy_policy`
  - `terms_of_service`
- Add optional `marketing` consent only if intentionally being tested.
- Confirm the user can authenticate and read only their own profile data.

## 3. First Test Farm Checklist

- Create one `farms` row owned by the farmer test profile.
- Choose a stable test `farm_code`.
- Create one `subscriptions` row for that farm with:
  - `provider = 'manual'`
  - a test `plan`
  - `status = 'active'` or `trialing`
- Confirm the farmer can:
  - read the farm
  - read `farm_access_modes`
  - write data for that farm through RLS-protected tables
- Confirm no second unrelated user can read the farm.

## 4. FlutterFlow To Supabase Connection Checklist

- Create or open the FlutterFlow project for Appiombi.
- Connect FlutterFlow to the Supabase project using the public project URL and anon key only.
- Verify the Supabase connection from FlutterFlow.
- Configure Auth integration in FlutterFlow for:
  - sign up
  - login
  - logout
  - reset password
- Confirm FlutterFlow can read base tables/views needed for MVP.
- Treat RLS-protected writes as backend-dependent and verify them with the test user.
- Mark the following as custom Dart/backend integration areas, not pure visual-builder logic:
  - secure storage orchestration
  - local offline database
  - sync queue and retry
  - conflict queue
  - RPC-based invite acceptance

## 5. First MVP Screens To Build In FlutterFlow

- Authentication entry screen
- Registration screen
- Login screen
- Password reset screen
- Legal acceptance gate screen, if needed by flow
- Farmer home / farm selector
- Farm dashboard base
- Session list screen
- New session / resume session entry screen
- Session cow list screen
- Cow visit editor base

These are screen planning items only. No Flutter UI is implemented in this step.

## 6. First Queries, Tables, And Views To Use

### Authentication And Profile

- `profiles`

Use cases:

- load current app profile
- check role
- check account state

### Legal Access Readiness

- `legal_documents`
- `user_consents`

Use cases:

- confirm active privacy and terms versions
- check whether required consents exist for the signed-in user

### Farm Selection And Access Mode

- `farms`
- `farm_users`
- `farm_access_modes`
- `active_farm_users`

Use cases:

- load farms accessible to current user
- show whether a farm is writable or read-only
- show active memberships

### Invitation Flows

- `farm_invites`
- RPC `accept_farm_invite(invite_code text)`

Use cases:

- owner creates/manages invites
- invited operator accepts invite through RPC, not direct insert into `farm_users`

### Farm Workspace And Sessions

- `active_trimming_sessions`
- `trimming_session_days`
- `active_cow_visits`
- `active_animals`
- `active_claw_observations`
- `active_clinical_tasks`

Use cases:

- list sessions
- load one session
- load cows already visited
- search animal history
- load active clinical tasks

## Recommended Screen-To-Data Mapping

### Login / Registration

- Supabase Auth
- `profiles`
- `legal_documents`
- `user_consents`

### Farmer Home

- `farms`
- `farm_access_modes`

### Farm Dashboard

- `farms`
- `farm_access_modes`
- `active_trimming_sessions`
- `active_clinical_tasks`

### Session List

- `active_trimming_sessions`
- `trimming_session_days`

### Session Cow List

- `active_cow_visits`
- `active_animals`

### Cow Visit Detail

- `active_cow_visits`
- `active_animals`
- `active_claw_observations`
- `active_clinical_tasks`, if task preview is needed

## Native App Constraint

FlutterFlow can handle the first connected screens, but offline-first persistence, sync, retry, and conflict handling still require custom Dart and should not be postponed by switching to a web-style architecture.
