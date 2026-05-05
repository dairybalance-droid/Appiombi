# MVP Roadmap

## MVP Goal

Deliver a usable native Android/iOS mobile workflow for hoof trimming session management, with offline-first operation as a core requirement.

## Architecture Rule

The MVP is not a web-first product.

- primary target: Android and iOS native builds
- primary UI approach: FlutterFlow
- primary runtime: Flutter/Dart mobile app
- primary operational assumption: field work with intermittent or absent connectivity

## Phase 0: Native Foundation

- Product specification
- User flows
- Data model
- Session logic
- Claw map model
- Task engine model
- Auth and access specification
- Security specification
- Native app architecture
- Offline/sync specification
- Supabase schema
- RLS policy design

## Phase 1: Backend Setup

- Create Supabase project
- Apply schema
- Apply RLS policies
- Configure auth
- Seed lookup values if needed

Current status:

- Supabase project initialized
- `schema.sql` applied successfully
- `rls_policies.sql` applied successfully
- initial tables and views verified in Supabase
- Auth configuration and first seeded test data still pending

## Phase 2: Native Data Foundation

- choose local database direction
- implement local repositories in custom Dart
- implement secure storage for tokens
- define local record sync model
- define sync queue and conflict queue storage

## Phase 3: Access And Farm Management

- login flow
- user profile creation
- farm ownership
- invite code creation
- invite redemption
- membership revocation
- revocation-aware sync blocking

## Phase 4: Farm Workspace MVP

- farmer home
- vet/hoof trimmer home
- farm list/search
- farm dashboard base
- open task list

## Phase 5: Session Workflow MVP

- create session offline or online
- resume session offline or online
- multi-day session support
- session close and reopen
- session visit list
- search and sorting

## Phase 6: Cow Visit MVP

- cow ID validation
- cow history
- generic visit fields
- simplified claw map input
- edit previously saved cows
- previous/next navigation
- local draft persistence

## Phase 7: Sync Engine MVP

- outbound mutation queue
- retry logic
- remote/local id reconciliation
- conflict queue
- manual conflict review foundation
- revocation-safe sync rules

## Phase 8: Task Workflow MVP

- task suggestion
- task creation
- farmer task list
- session close send-task flow

## Phase 9: Hardening

- audit checks
- access validation
- crash recovery checks
- offline durability checks
- basic dashboard summaries
- data export predisposizione futura

## Deferred But Prepared

- secondary web dashboard
- full anatomical map UX
- lesion photos
- BCS
- tit scoring
- non-podal lesions
- email sending
- WhatsApp sending
- live MFA enforcement
- advanced analytics

## MVP Exit Criteria

- user can log in on native mobile app
- farmer can access owned farm
- farmer can invite and revoke operator access
- operator can see authorized farms
- user can create and resume a session offline
- user can save cow visits offline with required validation
- local data survives app close and temporary connectivity loss
- queued changes synchronize when connectivity returns
- important conflicts do not auto-resolve with last-write-wins
- user can generate and review tasks
- user can view farm-specific cow history
