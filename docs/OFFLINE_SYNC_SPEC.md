# Offline Sync Specification

## Purpose

Define the offline-first synchronization model for Appiombi as a native Android/iOS application.

## Product Position

Offline behavior is not an enhancement. It is a primary requirement for field usage.

The app must allow users to:

- create trimming sessions without connection
- create and edit cow visits without connection
- save data locally immediately
- queue mutations for later synchronization
- recover state after crash, app close, or temporary loss of connectivity

## Native Assumption

This specification assumes:

- native Flutter app runtime
- mobile local database
- custom Dart sync engine
- Supabase backend as synchronization authority

## Local Persistence Requirement

Critical operational data must survive:

- app close
- app crash
- OS background kill
- prolonged no-network operation

Recommended direction for MVP:

- Drift over SQLite for local relational persistence

## Local Record Model

Each sync-relevant local record should support:

- `local_id`
- `remote_id`, nullable until synced
- `device_id`
- `sync_status`
- `record_version`
- `updated_at`
- `deleted_at`, for soft delete workflows where relevant

Required sync states:

- `local_only`
- `pending_sync`
- `synced`
- `conflict`
- `failed`

## Required Queues

### Sync Queue

Tracks pending outgoing mutations.

Required fields:

- local mutation id
- local record id
- remote record id if known
- device id
- farm id
- table/entity name
- operation type
- payload
- attempt count
- last attempt timestamp
- sync state

### Conflict Queue

Tracks records that need manual review.

Required fields:

- conflict id
- local record id
- remote record id
- device id
- farm id
- local payload
- server payload
- reason
- resolution status

## Sync Lifecycle

1. User creates or edits data locally.
2. Local transaction writes business record and queue item atomically.
3. Record becomes `local_only` or `pending_sync`.
4. Sync engine detects connectivity and valid auth.
5. Sync engine re-checks farm authorization on backend.
6. Sync engine submits queued mutations in stable order.
7. Backend accepts, rejects, or marks conflict.
8. Local state updates accordingly.

## Retry Strategy

- retry automatically on transient network failure
- backoff retries after repeated failures
- do not loop infinitely on authorization failure
- move persistent errors to `failed` for explicit review

## Conflict Principles

- no automatic last-write-wins for important business conflicts
- conflicts must preserve both server and local state for review
- users must be able to manually resolve clinically relevant collisions

Important conflict examples:

- same cow visit edited from two devices
- duplicate cow inside the same session caused by offline concurrency
- same farm data changed after access revocation or stale session context

## Authorization During Sync

- backend must re-check `farm_id` access at sync time
- app must not sync toward farms no longer authorized
- revoked farm access must block new outgoing sync immediately
- queued mutations for revoked farms must move to rejected, failed, or conflict flow

## Soft Delete Strategy

Use soft delete where sync integrity matters.

Recommended server fields:

- `deleted_at`
- `updated_at`
- `record_version`

Recommended client behavior:

- mark record deleted locally first
- sync delete intent
- remove from normal active lists
- retain enough metadata for conflict and recovery handling

UI query rule:

- when available, standard application queries should use active views such as:
  - `active_farm_users`
  - `active_animals`
  - `active_trimming_sessions`
  - `active_cow_visits`
  - `active_claw_observations`
  - `active_clinical_tasks`
- `deleted_at` exists for sync/offline integrity and recovery, not for immediate physical deletion in normal workflows

## Device Identity

Each device must register a durable `device_id`.

Device metadata should include:

- platform
- label
- app version
- last seen timestamp

## Offline Security

- tokens must be stored only in secure mobile storage
- local data should be protected as much as practical on device
- avoid logging sensitive local payloads
- clear local auth material on logout
- clear or quarantine farm data locally when access is revoked, where feasible

## FlutterFlow Compatibility

### FlutterFlow Can Cover

- UI forms
- page flows
- list rendering
- manual sync status indicators

### Custom Dart Is Required For

- local database repositories
- atomic local save plus queue write
- sync scheduler
- retry engine
- conflict queue management
- remote/local id reconciliation
- secure storage integration

## Tables Requiring Strong Conflict Handling

- `farm_users`
- `cows`
- `trimming_sessions`
- `cow_visits`
- `claw_zone_observations`
- `tasks`

## Design Rule

If a workflow only works while online, it is not sufficient for the native MVP unless it is explicitly marked as non-critical.
