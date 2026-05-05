# Appiombi User Flows

## Overview

This document defines the main MVP flows for farmer and veterinarian/hoof trimmer users, extended with authentication, legal acceptance, and SaaS access gating.

## Flow 1: Registration

1. User opens registration.
2. User enters:
   - email
   - password
   - password confirmation
   - first name
   - last name
   - requested role
3. User must accept:
   - Privacy Policy
   - Terms of Service
4. User may optionally accept marketing communications.
5. System validates:
   - email format
   - password policy
   - password confirmation match
   - required legal consents present
6. Supabase Auth creates the user account.
7. App creates `profiles` and `user_consents` records.
8. System sends email verification.
9. Account remains in limited state until email is verified.

## Flow 2: Email Verification

1. User receives Supabase verification email.
2. User confirms email.
3. System updates verified state.
4. On next app open/login, the user can proceed to full access checks.

## Flow 3: Login

1. User enters email and password.
2. Supabase Auth validates credentials.
3. System checks:
   - email verified
   - profile exists
   - account status is active
   - active required legal consents are present
4. If user is a farmer and owns one or more farms, system also checks subscription state for write access.
5. System loads accessible farms based on ownership or active `farm_users` records.
6. System routes the user to the correct home experience.

## Flow 4: Password Recovery

1. User requests password reset by email.
2. Supabase sends reset link or reset flow message.
3. User sets a new password.
4. If supported by the backend/session policy, old sessions are invalidated.
5. App clears local sensitive session material on next sign-in cycle.

## Flow 5: Logout

1. User taps logout.
2. App invalidates local session state.
3. App clears sensitive cached credentials and secure session material.
4. App returns to unauthenticated state.

## Flow 6: Session Management

1. User signs in.
2. App stores access/refresh tokens only in secure mobile storage.
3. App uses secure refresh flow without exposing tokens in URLs or logs.
4. If inactivity timeout is reached, app requires re-authentication according to configured policy.

## Flow 7: Farmer Home

1. Farmer signs in successfully.
2. System loads farms owned by the farmer.
3. Subscription state is evaluated per farm:
   - active/trialing/in grace means writable farm
   - expired/canceled/past due may force read-only behavior
4. If only one farm exists, farmer may enter it directly.
5. If multiple farms exist, farmer sees a farm list.
6. Farmer opens a farm workspace.

## Flow 8: Vet / Hoof Trimmer Home

1. Operator signs in successfully.
2. System loads farms where the operator has active `farm_users` membership.
3. Operator sees:
   - greeting/loading state
   - farm list
   - farm search
   - operational notifications
   - predisposizione futura for aggregate statistics
4. Operator opens a selected farm.

## Flow 9: Farmer Invites External Operator

1. Farmer opens farm access management.
2. Farmer requests a new invite code for the selected farm.
3. System creates a unique invite record tied to:
   - farm
   - invited role
   - optional invited email
   - expiration
   - pending status
4. Farmer shares the code externally.
5. Invited user authenticates and enters the code.
6. App calls protected backend RPC `accept_farm_invite(invite_code)`.
7. System validates the invite.
8. System creates or safely reactivates the `farm_users` membership.
9. System writes audit data and marks the invite as accepted.
10. Invited user now sees that farm in their farm list.

## Flow 10: Farmer Revokes Access

1. Farmer opens farm access management.
2. Farmer selects an active operator membership.
3. Farmer confirms revoke action.
4. System updates the membership to revoked.
5. Backend access stops immediately through RLS.
6. Future sync from revoked devices to that farm must be blocked.

## Flow 11: Enter Farm Workspace

1. User selects a farm.
2. System validates:
   - ownership or active membership
   - account active state
   - verified email
   - required legal acceptance
   - farm availability
3. System determines access mode through a safe backend helper/view such as `farm_access_modes`:
   - read/write
   - read-only due to subscription state
4. Farm workspace opens with:
   - dashboard
   - recent session stats
   - open tasks
   - cow search
   - cow history
   - new session entrypoint when writable

## Flow 12: Create New Session

1. User starts a new session for a writable farm.
2. System creates a session in open status.
3. Session opens with an empty cow visit list.
4. Before the first saved cow:
   - end session is available
   - exit without saving is visible
5. After the first saved cow:
   - session persists
   - exit without saving is no longer available

## Flow 13: Resume Existing Session

1. User opens an existing session.
2. System loads saved visits in insertion order by default.
3. User may always reopen, add, edit, search, or sort visits if write access is allowed.
4. Read-only access allows viewing but not changing data.

## Flow 14: Add Cow Visit

1. User taps new cow.
2. System opens a cow visit record with:
   - visit date prefilled with current date
   - empty cow ID
3. User enters cow ID.
4. System validates:
   - cow ID exists only once per farm master record
   - cow ID is not duplicated within the same session
5. User enters generic clinical data and lesion data.
6. User saves the cow visit.
7. System stores the visit and returns the user to:
   - next cow flow, or
   - session list, depending on action

## Flow 15: Duplicate Cow ID In Session

1. User attempts to save a cow visit with a cow ID already used in the same session.
2. System blocks the save.
3. System shows a validation error.
4. User must:
   - change the cow ID, or
   - close the cow without saving

## Flow 16: Navigate Between Cows

1. User opens an existing cow visit in a session.
2. User may move to:
   - previous cow
   - next cow
   - session list without losing data
3. Unsaved changes must remain recoverable locally until user discards or saves.

## Flow 17: View Cow History

1. User opens a cow visit or searches a cow in the farm workspace.
2. System loads historical visits for that cow ID in the same farm only.
3. User reviews previous sessions, notes, treatments, lesions, and generated tasks.

## Flow 18: Manage Session Sorting

1. User opens the session visit list.
2. User chooses a sort option:
   - insertion order
   - numeric cow ID
   - sole count
   - bandage count
   - antibiotic yes/no
   - criticality
3. System reorders the list without changing stored canonical order.

## Flow 19: End Session

1. User taps end session.
2. System shows a confirmation popup.
3. On confirm, system marks the session as closed but still editable.
4. User may trigger send tasks workflow.

## Flow 20: Generate And Send Tasks

1. User reviews cow visits during or after session work.
2. System derives or allows creation of operational tasks.
3. On send tasks:
   - system prepares a concise farmer-facing list
   - system stores channel readiness for future email or WhatsApp
4. MVP output stays inside app data structures.

## Flow 21: Legal Document Version Change

1. Admin activates a new required Privacy Policy or Terms version.
2. On next login, system detects missing acceptance for the active version.
3. User must review and accept the updated required document.
4. Access to normal app workflows remains blocked until required acceptance is stored.

## Flow 22: Offline Work

1. User opens farm/session while online.
2. Required records are cached locally.
3. User loses connectivity.
4. User continues editing local draft/session/cow data.
5. Sync queue stores pending mutations.
6. On reconnection, sync attempts replay only for farms still authorized.
7. If access was revoked, sync for that farm is blocked.
8. If conflict appears, system creates a conflict record for manual review.
