# Auth And Access Specification

## Scope

This document defines registration, login, session management, role access, invite/revoke behavior, and legal consent gating for Appiombi.

## Authentication Foundation

- Use Supabase Auth for email/password authentication.
- Require email verification before full app usage.
- Support password reset through Supabase.
- Use secure mobile storage for access and refresh tokens.
- Do not store credentials, secrets, or tokens in repository files or client logs.

## Registration Flow

Required fields:

- email
- password
- password confirmation
- first name
- last name
- requested role
- required privacy acceptance
- required terms acceptance

Optional fields:

- marketing communications consent

Rules:

- password and confirmation must match
- requested role must be one of `farmer`, `veterinarian`, `hoof_trimmer`
- `super_admin` is internal only and must never be user self-selected
- account starts as `pending_verification` until verified
- `user_consents` rows are created for required and optional accepted consents

## Login Flow

After Supabase credential validation, the app must verify:

- email is verified
- profile is active
- account status is not suspended or disabled
- required active legal documents were accepted
- accessible farms exist according to ownership or active `farm_users`

Additional farmer check:

- farm subscription state determines whether access is read/write or read-only

Backend enforcement rule:

- farm data access must not rely only on client-side login checks
- backend helpers must treat a user as fully enabled only if:
  - `profiles.account_status = 'active'`
  - `profiles.is_active = true`
  - email is verified
  - active required legal documents were accepted
- `can_access_farm(farm_id)` and `can_write_farm(farm_id)` must enforce this through helper logic such as `is_user_fully_enabled(profile_id)`

## Password Reset Flow

- user requests reset by email
- Supabase delivers reset flow
- user updates password
- previous sessions should be invalidated if supported by Supabase/session policy
- local secure session cache must be cleared on next sign-in boundary where needed

## Logout Flow

- manual logout signs out from Supabase
- local session state is cleared
- sensitive cached auth material is removed from secure storage
- app returns to unauthenticated state

## Session Management

- inactivity timeout must be configurable at app policy level
- refresh tokens must be handled only by trusted client auth logic
- tokens must not appear in URLs
- tokens must not appear in logs
- background token refresh should use Supabase SDK best practices

## MFA / 2FA Predisposition

MFA is not part of MVP, but architecture should be ready for future activation.

Prepared fields and logic:

- `profiles.mfa_enrolled`
- `profiles.mfa_required`
- `profiles.last_login_at`

Possible future policies:

- require MFA for `super_admin`
- require MFA for paying farmers
- require MFA for operators with many farm memberships

## Roles

- `super_admin`
- `farmer`
- `veterinarian`
- `hoof_trimmer`
- `farm_collaborator`, predisposizione futura

## Role Rules

### super_admin

- internal Appiombi role only
- not customer self-assignable
- may access system-wide administrative data according to dedicated backend policy

### farmer

- owns farm data
- can create farms
- can invite and revoke operators
- subscription payer and business owner

### veterinarian / hoof_trimmer

- may access only farms with active invitation-derived membership
- cannot discover or query other farms

### farm_collaborator

- predisposizione futura generic role for limited farm access

## Farm Access Model

- read access is controlled by `can_access_farm(farm_id)`
- write access is controlled by `can_write_farm(farm_id)`
- RLS must enforce both boundaries
- revocation must immediately disable access server-side

## Invite Flow

`farm_invites` must support:

- code-based invitation
- optional invited email
- role assignment
- expiration
- acceptance trace
- revocation

Acceptance rules:

- invite must be pending
- invite must not be expired
- if `invited_email` is present, it must match authenticated user email
- accepted invite creates one `farm_users` record
- client must not directly insert `farm_users` to self-authorize
- invite acceptance must pass through a protected backend function such as `accept_farm_invite(invite_code text)`

### Invite Acceptance RPC

Recommended backend path:

- `accept_farm_invite(invite_code text)`

The RPC must:

- require authenticated user context
- require verified email and required legal acceptance
- support generic invite codes and email-bound invite codes
- reject expired, revoked, or already accepted invites
- prevent duplicate farm membership rows
- create or reactivate the farm membership safely
- mark the invite as accepted
- write an audit log entry
- return `farm_id` and assigned role

## Legal Acceptance Gating

- active Privacy Policy acceptance is mandatory
- active Terms of Service acceptance is mandatory
- active Cookie/Tracking policy acceptance may be required depending on final legal approach and actual tracking use
- marketing consent is separate and optional
- if a new required legal version becomes active, the user must re-accept before normal app usage

## Audit Requirements

Audit logs should capture at least:

- registration
- login
- logout
- failed security-relevant access attempts, where feasible
- password change
- legal consent acceptance
- farm creation
- invite creation
- invite acceptance
- membership revocation

## Account Deactivation And Suspension

- suspended or disabled accounts must not receive normal app access
- historical farm data remains on the server according to retention policy
- legal export obligations for farmer-owned data must remain possible
