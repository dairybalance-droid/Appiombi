# Native Flutter Plan

## Purpose

This document describes how Appiombi should proceed if the project adopts pure Flutter native as the primary product stack.

## Primary Stack

- Flutter native
- Dart
- Supabase
- GitHub
- Codex-driven repository workflow

## Product Position

Appiombi remains:

- native Android/iOS
- mobile-first
- offline-first

The difference is that UI and product logic are now expected to be implemented primarily in Flutter code, not in FlutterFlow.

## What Moves Into Code

With pure Flutter as primary stack, the repository becomes the main implementation surface for:

- app theme
- navigation
- screens
- buttons
- cards
- lists
- dashboard blocks
- Supabase queries
- role-aware flows
- future local persistence
- future offline sync engine
- custom podal map

## Recommended App Layers

### 1. Presentation Layer

- Flutter widgets
- reusable UI components
- design tokens from brand direction
- route/navigation structure

### 2. Feature Layer

- auth feature
- farm selection feature
- dashboard feature
- session feature
- cow visit feature
- task feature

### 3. Data Layer

- Supabase service clients
- repositories
- DTO/model mapping
- future local database adapters

### 4. Offline Layer

- local storage abstraction
- sync queue
- conflict queue
- retry scheduler

This layer is predisposizione futura but should be planned now in architecture.

## First Implementation Priorities

### Phase 1

- Flutter app shell
- theme setup from brand direction
- auth integration with Supabase
- profile bootstrap checks

### Phase 2

- farm list
- farm selection
- farm access mode handling
- farm dashboard base

### Phase 3

- animal list
- session list
- session creation
- base cow visit flow

### Phase 4

- reusable forms and cards
- task list
- history entry points

### Phase 5

- local persistence foundation
- sync architecture foundation
- custom podal map foundation

## Recommended Flutter Architecture Direction

Without locking to a full framework choice yet, the app should favor:

- repository-based data access
- explicit typed models
- reusable screen scaffolds
- clean routing
- testable feature modules

Avoid:

- giant page files
- UI mixed directly with low-level query logic
- architecture that assumes permanent connectivity

## Query Strategy

Use Supabase with repository methods around:

- `profiles`
- `farms`
- `farm_access_modes`
- `active_farm_users`
- `active_animals`
- `active_trimming_sessions`
- `active_cow_visits`
- `active_clinical_tasks`

These should be wrapped in code-based services instead of spread across visual editor actions.

## Brand And UI Impact

Pure Flutter makes it easier to implement:

- consistent spacing system
- brand palette tokens
- typography system
- large glove-friendly buttons
- custom cards
- chart styles
- future app icon and splash refinements

## FlutterFlow Role After Decision

FlutterFlow may still be used for:

- quick visual experiments
- stakeholder prototype checks

It should not be considered the primary source of truth for the production app if the project adopts this decision.

## Recommendation

Proceed with pure Flutter as the primary implementation route for MVP and product evolution.
Keep FlutterFlow only as optional secondary tooling, not as the main development surface.
