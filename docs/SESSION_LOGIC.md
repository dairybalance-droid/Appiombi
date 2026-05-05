# Session Logic

## Session Lifecycle

### Open Session

- Created when user starts a new trimming session inside a farm.
- Status = `open`.
- Editable by authorized users of that farm.

### Multi-Day Session

- A single session may remain open across multiple non-consecutive dates.
- Actual work days are tracked in `trimming_session_days`.
- The session remains the main editing container.

### Closed Session

- User confirms end session.
- Status changes to `closed`.
- Closed does not mean immutable.
- Session can be reopened or edited later.

### Archived Session

- Predisposizione futura administrative state for hiding old sessions from active workflows.

## Session Entry Rules

- User must have access to the farm.
- User may create a new open session even if earlier sessions exist, unless future business rules limit concurrent open sessions.
- No special UI/logic for concurrency is required in this phase beyond audit and sync readiness.

## First Visit Special Behavior

- Before the first cow visit is saved:
  - show `exit without saving`
  - allow full draft abandonment
- After the first cow visit is saved:
  - session exists as persisted data
  - hide `exit without saving`

## Cow Visit Save Rules

- `visit_date` defaults to current date.
- `cow_identifier` is mandatory through linked `cow_id`.
- Save must be blocked if no cow ID is provided.
- Save must be blocked if the same cow already exists in the same session.

## Cow Identity Rules

- Cow identity is farm-specific.
- A cow is represented in `cows`.
- If a typed cow ID does not exist for that farm, the app may create the farm-specific cow record during save.
- If a typed cow ID already exists in that farm, the visit must link to that existing cow.
- Same textual ID may exist in another farm.

## Session List Ordering

### Canonical Order

- Stored order uses `insertion_index`.
- This preserves original work sequence.

### Alternate Sort Modes

- numeric cow ID
- sole count
- bandage count
- antibiotic yes/no
- criticality

These are presentation sorts only and must not overwrite `insertion_index`.

## Navigation Between Visits

- User may move to previous saved visit.
- User may move to next saved visit.
- User may return to session list without discarding unsaved local edits.
- User may reopen and edit any saved visit in the session.

## Finish Session Logic

1. User taps finish session.
2. App shows confirmation dialog.
3. On confirm:
   - session `ended_at` is updated
   - status becomes `closed`
4. User may then trigger task generation/delivery review.

## Reopen Session Logic

- Any user with write access to the farm may reopen a closed session.
- Reopening is always allowed for authorized writable users.
- Reopening should only switch session status back to `open`.
- Historical records must remain intact.

Technical limits:

- reopen is not available when farm access has been revoked
- reopen is not available when the farm is in read-only or blocked mode

## Audit Expectations

Every mutable business table should keep:

- `created_at`
- `updated_at`
- `created_by_profile_id`, where appropriate
- `updated_by_profile_id`, where appropriate
- sync metadata, where appropriate

## Edge Cases

### Duplicate Cow In Session

- Block save.
- Show explicit validation error.
- Require user correction or discard.

### Unsaved Draft Cow

- Must be local draft only until save.
- Must not create duplicate server records.

### Concurrent Operators

- Multiple operators may add different cows to the same session.
- Same cow edited by multiple devices may create sync conflict requiring manual review.
