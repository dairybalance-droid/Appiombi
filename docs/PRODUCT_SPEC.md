# Appiombi Product Specification

## Purpose

Appiombi is a mobile application for managing hoof trimming sessions in dairy cows.
The product must support farmers, veterinarians, and hoof trimmers working across one or more farms, with Supabase as the primary backend and future-ready offline sync.

## Product Goals

- Manage farm access with owner-controlled invitations.
- Create and maintain hoof trimming sessions that may span multiple non-consecutive days.
- Record one cow visit at a time with strict farm/session validation.
- Store simplified MVP lesion input while keeping the data model ready for a full claw map.
- Generate operational follow-up tasks for the farmer.
- Preserve future compatibility with offline work, conflict review, media, scoring, and exports.

## Non-Goals For This Phase

- No Flutter or FlutterFlow UI implementation yet.
- No live WhatsApp integration.
- No active lesion photo upload.
- No advanced aggregate analytics beyond basic dashboard readiness.
- No automatic conflict winner strategy for offline edits.

## Primary Stack

- Mobile UI: FlutterFlow
- Custom logic: Flutter/Dart where needed
- Backend: Supabase
- Auth: Supabase Auth
- Database: PostgreSQL on Supabase
- File storage: Supabase Storage, predisposizione futura
- Offline: local persistence and sync queue, predisposizione futura

## User Roles

### Farmer

- Pays the subscription.
- Owns farm data.
- Can access only their own farms.
- Can invite veterinarians and hoof trimmers with a unique invite code.
- Can revoke access at any time.

### Veterinarian / Hoof Trimmer

- Can access only farms explicitly shared by a farmer.
- Can work across multiple farms.
- Has a home area listing authorized farms.
- Once inside a farm, follows the same functional flow as the farmer.

## Core Product Areas

### Authentication And Access

- Sign in with Supabase Auth.
- Role-aware app home.
- Membership-based access to farms.
- Invite and revoke workflow managed by the farmer.

### Farm Workspace

- Farm dashboard.
- Recent session statistics.
- Open reminders and tasks.
- Cow search.
- Cow history.
- Start or resume hoof trimming session.

### Session Management

- A session can remain open across multiple days.
- A session can be re-opened and modified at any time by authorized users with write access.
- A session contains an ordered list of cow visits.
- Session list supports search and multiple sort options.

### Cow Visit Management

- Date auto-filled with current date.
- Cow ID required.
- Cow ID unique within a farm.
- Same cow ID cannot be saved twice in the same session.
- Historical data limited to the same farm.

### Claw Map

- MVP uses a simplified clickable map.
- Database must already support full anatomical detail.
- Each claw 1-8 supports horn and derm zones.

### Task Engine

- Session work may generate farm tasks.
- Tasks can be reviewed during session handling and on session close.
- Future delivery channels are prepared in the model, but only in-app/list output is required now.

### Offline And Multi-Device

- Local offline save required as a product constraint.
- Sync must handle multi-device operators on the same farm.
- Conflicts require manual review, not last-write-wins.

## Functional Requirements

### Farmer Home

- Direct access to the single owned farm, or a list if more than one exists.
- View only farms owned by or assigned to that farmer profile.

### Vet / Hoof Trimmer Home

- Greeting or loading state.
- Authorized farm list.
- Farm search.
- Operational notifications.
- Predisposizione futura for aggregate statistics.

### Farm Dashboard

- Summary of recent sessions.
- Open tasks and reminders.
- Cow search entrypoint.
- Cow history access.
- New session entrypoint.

### Session Screen

- View cows already recorded in the session.
- Create new cow entry.
- End session with confirmation.
- Exit without saving visible only before the first saved cow.
- Search inside session.
- Sorting by:
  - insertion order
  - numeric cow ID
  - sole count
  - bandage count
  - antibiotic yes/no
  - severity/criticality

### Cow Visit Screen

- Save cow and continue to next.
- Move to previous saved cow.
- Move to next saved cow.
- Close cow without saving.
- Return to session list without losing in-progress data.
- Edit previously saved cows.
- View farm-specific history for that cow.

## Required Cow Visit Data

- Visit date
- Cow ID
- Sole count
- Bandage count
- Corkscrew score 1-3
- Laminitis classification
- Antibiotic yes/no
- Anti-inflammatory yes/no
- Straw box yes/no
- Cull evaluation
- Chronic cow
- Other flag
- Free notes
- History recall
- Claw map access

## Predisposizione Futura

- Lesion photos
- BCS
- Tit scoring
- Non-podal body lesions
- Email task sending
- WhatsApp task sending
- Exports

## Design Constraints

- Keep schema and relations easy to consume in FlutterFlow.
- Prefer UUID primary keys.
- Use explicit foreign keys and lookup tables.
- Store both current state and audit-ready metadata for sync/conflicts.
- Keep session and cow visit editing open-ended.
