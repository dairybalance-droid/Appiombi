# Security Specification

## Purpose

This document defines the technical security baseline for Appiombi as a native Android/iOS mobile SaaS product. The goal is to reduce risk and document technical and organizational controls, not to claim the system is unattainable or risk-free.

## Security Baseline

- Supabase Auth for authentication
- RLS required on all business tables
- secure native mobile token storage
- farm-scoped access control using `farm_id`
- audit logging for critical actions
- no secrets committed to GitHub
- privacy by design and by default
- no service role key in the mobile client

## Native Mobile Security Position

Appiombi is a native mobile app first.

Security assumptions must therefore prioritize:

- secure storage on Android and iOS
- protection of offline cached business data
- safe token lifecycle on device
- revocation-aware sync behavior
- device-aware audit and conflict handling

## Authentication Security

- email/password via Supabase Auth
- mandatory email verification before full usage
- password reset via Supabase Auth flows
- future MFA readiness without enabling MFA in MVP
- no password handling outside trusted auth SDK flows

## Session Security

- access and refresh tokens stored only in secure mobile storage
- no tokens in URLs
- no tokens in application logs
- clear local session material on logout
- inactivity timeout configurable at app policy level
- never expose auth tokens through debug screens or analytics payloads

## Authorization Security

- every table containing farm data must enforce RLS
- all reads must respect `can_access_farm(farm_id)`
- all writes must respect `can_write_farm(farm_id)`
- revocation must have immediate backend effect
- subscription state may force read-only mode but must not silently bypass ownership rules
- `can_access_farm(farm_id)` and `can_write_farm(farm_id)` should depend on a fully enabled user state, not only on `is_active`
- fully enabled means:
  - `account_status = 'active'`
  - `is_active = true`
  - email verified
  - required active legal documents accepted

## Offline Security

- use secure storage for auth material
- protect local database as much as platform capabilities allow
- prefer encrypted or OS-protected local storage where practical
- block sync for farms that are no longer authorized
- require manual review for clinically relevant conflicts instead of silent overwrite
- clear or quarantine locally cached farm data after access revocation where feasible

## Client Security Rules

- never ship Supabase service role keys in the mobile client
- only use publishable anon client configuration in app code
- do not embed operational secrets in FlutterFlow custom actions or generated code
- do not persist sensitive data in plain-text local storage where secure alternatives exist
- do not rely on web storage assumptions such as browser localStorage/sessionStorage

## Backend And Data Security

- validate input both client-side and backend-side where possible
- use check constraints, foreign keys, and explicit sync metadata in PostgreSQL
- apply least-privilege access patterns
- use append-oriented audit logging for sensitive actions
- prepare secure storage patterns for future lesion photos without enabling them now
- use protected RPC/security definer functions for sensitive transitions such as invite acceptance instead of exposing direct self-authorization writes from the client

## Logging And Monitoring

- log security-relevant actions in `audit_logs`
- avoid logging tokens, passwords, reset payloads, or raw secrets
- sanitize error details returned to clients
- prefer generic auth failure messages when possible to reduce user enumeration risk

## Abuse Resistance

- use rate limiting where Supabase or edge infrastructure allows
- limit repeated auth attempts where platform capabilities support it
- avoid overly detailed error responses on login, reset, or invite checks

## Privacy And Data Protection

- no human health data is planned
- zootecnical and professional business data should still be treated carefully
- minimize personal data to what is necessary for access, billing, legal traceability, and operations
- document retention, deletion, anonymization, and export workflows

## FlutterFlow Boundary

FlutterFlow may build the UI, but security-critical mechanisms should not depend only on visual builder logic.

Custom Dart or external Flutter code is required for:

- secure storage orchestration
- offline database protection strategy
- sync retry and revocation-aware behavior
- conflict-safe local state management

## SaaS Billing Security

- no payment provider secrets in client or repository
- no real payment implementation in MVP
- store only provider references required for subscription state tracking
- never depend on client-only flags for paid access

## MFA Readiness

Predisposizione futura:

- support profile flags for `mfa_required` and `mfa_enrolled`
- allow future enrollment for admins, paying farmers, or high-reach operators

## OWASP Alignment

This project should use OWASP ASVS and OWASP MASVS as engineering checklists.

Recommended mapping:

- ASVS for authentication, access control, input validation, logging, and data protection
- MASVS for mobile token storage, local data protection, device-side trust boundaries, and platform hardening

These references are for implementation guidance and review checklists, not as a guarantee of full compliance by default.
