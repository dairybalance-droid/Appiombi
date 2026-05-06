# FlutterFlow Supabase Queries

## Purpose

This document lists the main tables, views, and query intentions for the first Appiombi FlutterFlow screens.

## General Rules

- prefer `active_*` views when available for operational UI
- always use ids for navigation and writes
- do not use farm name as unique identity
- respect `farm_access_modes` for writable vs read-only presentation

## 1. Login

Primary backend:

- Supabase Auth

After login, load:

- `profiles`

Purpose:

- load current profile
- check role context

## 2. Lista Aziende

Primary sources:

- `farms`
- `farm_access_modes`

Recommended query shape:

- load farms visible to current authenticated user
- join or pair with access mode by `farm_id`

Display fields:

- `farms.id`
- `farms.name`
- `farms.street_address`
- `farms.street_number`
- `farms.postal_code`
- `farms.city`
- `farms.province`
- `farms.farm_code`
- `farm_access_modes.access_mode`
- `farm_access_modes.can_read`
- `farm_access_modes.can_write`

## 3. Dashboard Azienda

Primary sources:

- `farms`
- `farm_access_modes`
- `active_trimming_sessions`
- `active_clinical_tasks`

Purpose:

- load farm header
- determine if farm is writable
- show recent sessions
- show open tasks

## 4. Lista Vacche

Primary source:

- `active_animals`

Filter:

- `farm_id = selectedFarmId`

Fields:

- `id`
- `farm_id`
- `cow_identifier`
- `display_identifier`

## 5. Nuova Sessione

Write target:

- `trimming_sessions`

Read target after create:

- `active_trimming_sessions`

Required write inputs:

- `farm_id`
- `created_by_profile_id`

Optional:

- `title`
- `notes`

## 6. Visita Vacca Base

Read sources:

- `active_animals`
- `active_cow_visits`

Write target:

- `cow_visits`

Required save fields:

- `session_id`
- `farm_id`
- `cow_id`
- `visit_date`
- `insertion_index`
- `created_by_profile_id`

Initial basic editable fields:

- `sole_count`
- `bandage_count`
- `corkscrew_grade`
- `laminitis_status`
- `antibiotic_given`
- `antiinflammatory_given`
- `straw_box_required`
- `notes`

## Read-Only And Write-Aware Behavior

Use `farm_access_modes` to drive:

- show editable actions only when `can_write = true`
- show read-only state when `access_mode = read_only`

## Do Not Implement Yet

Do not build queries yet for:

- advanced podal map authoring UX
- offline sync tables for UI use
- WhatsApp integrations
- photos
- AI or voice

## Predispose But Delay

Later-use backend pieces:

- `farm_invites`
- RPC `accept_farm_invite(invite_code text)`
- `active_claw_observations`
- `trimming_session_days`
- `active_clinical_tasks` task review flows
