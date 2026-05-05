# Task Engine Specification

## Purpose

Appiombi must produce operational follow-up tasks from trimming work so the farmer can act after the session.

## MVP Scope

- Store and manage tasks in database.
- Support task generation during session handling or at session close.
- Support concise task output for the farmer.
- Prepare delivery channels without implementing WhatsApp or email sending.

## Task Sources

Tasks may be created from:

- explicit operator choice
- derived logic from visit data
- session close review flow

## MVP Task Types

- Remove bandage after X days
- Give antibiotic
- Give anti-inflammatory
- Give antibiotic + anti-inflammatory
- Move to straw box
- Recheck cow
- Evaluate culling
- Custom task text

## Task Data Fields

- `farm_id`
- `session_id`
- `cow_visit_id`
- `cow_id`
- `task_type`
- `title`
- `details`
- `due_date`
- `status`
- `assigned_to_profile_id`, predisposizione futura
- `delivery_state`

## Suggested Derivation Rules

### Bandage

- If `bandage_count > 0`, app may suggest `remove_bandage`.

### Antibiotic

- If `antibiotic_given = true`, app may suggest follow-up antibiotic task where clinically applicable.

### Anti-inflammatory

- If `antiinflammatory_given = true`, app may suggest follow-up anti-inflammatory task where clinically applicable.

### Straw Box

- If `straw_box_required = true`, app may suggest move to straw box task.

### Cull Evaluation

- If `evaluate_culling = true`, app may suggest evaluate culling task.

### Chronic Cow

- If `is_chronic_cow = true`, app may suggest recheck task.

## Session Close Behavior

1. User closes or reviews a session.
2. App prepares task candidates.
3. User confirms, edits, or skips task creation.
4. Created tasks are stored and shown in farm operational lists.

## Farmer Output

MVP output should support:

- concise task list per farm
- concise task list filtered by due date or status, predisposizione futura

## Delivery Readiness

### Email

Predisposizione futura:

- task delivery records should support email channel metadata.

### WhatsApp

Predisposizione futura:

- task delivery records should support WhatsApp channel metadata.
- no live integration in MVP.

## Status Model

- `open`
- `done`
- `cancelled`

## Delivery State Model

- `not_sent`
- `prepared`
- `sent`
- `failed`

## Editing Rules

- Tasks remain editable after session close.
- Tasks should not be hard-deleted in normal workflows.
- Prefer status transitions and audit updates.
