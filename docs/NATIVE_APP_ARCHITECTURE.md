# Native App Architecture

## Architecture Position

Appiombi must be designed first as a native mobile application for:

- Android
- iOS

Primary implementation path:

- FlutterFlow for mobile UI construction
- generated Flutter/Dart code as the base application
- custom Dart modules where FlutterFlow is not sufficient
- native Android/iOS builds for distribution on Google Play Store and Apple App Store

Appiombi must not be architected as:

- primary web app
- desktop-first dashboard
- PWA
- responsive site pretending to be the main product

Web is only a predisposizione futura secondary surface and is not part of the MVP architecture.

## Architectural Principles

- mobile-first
- offline-first
- local-first for critical session work
- backend-synchronized, not backend-dependent for basic field operations
- native storage and native session handling
- no architecture decision should force Appiombi toward a web-first implementation

## High-Level Native Stack

### UI Layer

- FlutterFlow screens, navigation, forms, and base mobile interactions
- generated Flutter widgets and page logic
- custom Flutter widgets only where FlutterFlow cannot represent the required interaction

### Mobile Domain Layer

- custom Dart models for sessions, cows, tasks, and sync state
- local validation for required business rules during offline use
- mapping between local ids, server ids, and sync states

### Local Persistence Layer

- local mobile database required
- must survive:
  - app close
  - crash
  - device temporary offline state
  - long field sessions without connectivity

### Sync Layer

- custom Dart sync engine
- push local mutations to Supabase when network returns
- fetch remote changes
- manage retries
- create manual-review conflict items

### Backend Layer

- Supabase Auth
- Supabase Postgres
- RLS-based access control
- audit and legal consent data

## Local Database Strategy

## Evaluation Criteria

- strong Flutter/Dart support
- relational modeling support
- transaction safety
- migration support
- offline durability
- compatibility with generated FlutterFlow app through custom code entry points

## Recommended Direction For MVP

Recommended primary path:

- SQLite with Drift on top

Reasoning:

- relational model fits sessions, visits, tasks, sync queue, and conflict queue well
- robust migrations
- good Dart ergonomics
- strong control over indexed queries and transactional updates
- easier to model queue/state transitions than key-value only approaches

## Alternatives

### Isar

Pros:

- fast local object database
- good mobile performance

Cons:

- less natural fit for relational clinical/session workflows
- more translation work for sync-safe normalized data

### Hive

Pros:

- simple local persistence

Cons:

- not ideal as primary engine for relational offline-first clinical/session data
- weaker fit for conflict-aware sync workflows

## Recommendation Summary

- use FlutterFlow for UI
- use custom Dart repository/services layer
- use Drift/SQLite for primary offline persistence
- use secure storage separately for tokens and highly sensitive session material

## Local Data Categories

Store locally:

- authenticated profile metadata needed for app operation
- accessible farms summary
- active session records
- cow visit records
- claw observations
- tasks
- sync queue
- conflict queue
- lookup data needed offline

Do not store in plain local database where avoidable:

- raw passwords
- service keys
- refresh/access tokens outside secure storage

## Native Sync Engine Requirements

The app must include a custom sync engine with:

- `device_id`
- `local_id`
- `remote_id`
- `sync_queue`
- `conflict_queue`
- record-level sync status
- retry logic
- manual conflict review workflow

Required record sync states:

- `local_only`
- `pending_sync`
- `synced`
- `conflict`
- `failed`

## Sync Model

### Local Record Lifecycle

1. Record is created locally with a local UUID or temporary local id.
2. Record is saved in the local database immediately.
3. Record enters `local_only` or `pending_sync`.
4. Sync engine attempts upload.
5. On success, server `remote_id` is linked and state becomes `synced`.
6. On conflict, state becomes `conflict`.
7. On hard failure, state becomes `failed` and remains retryable.

### Soft Delete Model

- local deletes should normally become soft deletes first
- server records should support `deleted_at` where sync-safe deletion is needed
- hard delete should be limited and deliberate

## Multi-Device Model

- more than one operator may work on the same farm
- more than one device may work on the same farm
- same operator may switch devices across days
- important conflicts must not auto-resolve with last-write-wins

## Conflict Strategy

Conflict classes:

- same server record edited from multiple devices
- offline edits against stale base version
- duplicate cow identifier or business constraint collision
- revoked access while local queue still contains pending mutations

Resolution policy:

- manual review for important conflicts
- preserve both local and server payloads for inspection
- allow controlled duplication or identifier adjustment where clinically appropriate

## Native Security Requirements

- tokens stored with secure storage only
- no service role key in client
- local database protected as much as practical on device
- revoke access must block future sync to that farm
- logout must clear local session material

## FlutterFlow Compatibility Boundary

### Safe In FlutterFlow

- mobile page structure
- navigation
- forms and base validation
- list/detail pages
- simple local UI state

### Requires Custom Dart

- local SQLite/Drift layer
- sync engine
- conflict queue handling
- secure token orchestration
- retry scheduling
- offline reconciliation logic

### May Require Work Outside Pure FlutterFlow Visual Builder

- advanced background sync behavior
- large local repository/service architecture
- platform-specific storage hardening
- more advanced crash-safe sync recovery

## MVP Implementation Constraint

If a feature can only be made reliable by custom Dart, prefer custom Dart over redesigning the product as a web-style always-online flow.
