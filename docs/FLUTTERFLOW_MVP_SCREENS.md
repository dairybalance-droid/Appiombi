# FlutterFlow MVP Screens

## Purpose

This document defines the first FlutterFlow MVP screens to build for Appiombi.

## Screen Order

Build in this order:

1. Login
2. Lista aziende
3. Dashboard azienda
4. Lista vacche
5. Nuova sessione
6. Visita vacca base

## 1. Login

Purpose:

- authenticate user with Supabase Auth

Main elements:

- email field
- password field
- login action
- forgot password entry

Notes:

- use FlutterFlow auth actions
- do not build advanced session gating logic in UI only

## 2. Lista Aziende

Purpose:

- show farms accessible to the authenticated user

Primary data sources:

- `farms`
- `farm_access_modes`

Fields to show for each farm:

- farm name
- full address
- city
- province
- `farm_code`

Recommended display example:

- Azienda Agricola Rossi
  Via Roma 12, 42025 Cavriago (RE)

- Azienda Agricola Rossi
  Via Roma 14, 42025 Cavriago (RE)

Important rule:

- the list must never rely on farm name as unique identifier
- selection must always use `farms.id`

## 3. Dashboard Azienda

Purpose:

- provide the first farm-level landing page

Primary data sources:

- `farms`
- `farm_access_modes`
- `active_trimming_sessions`
- `active_clinical_tasks`

Suggested sections:

- farm header
- access mode summary
- recent sessions
- open tasks
- shortcut to cow list
- shortcut to new session

## 4. Lista Vacche

Purpose:

- show cows belonging to the selected farm

Primary data source:

- `active_animals`

Suggested fields:

- cow identifier
- display identifier if present

Suggested actions:

- open cow history later
- start visit flow from farm context

## 5. Nuova Sessione

Purpose:

- create a trimming session for the current farm

Primary table:

- `trimming_sessions`

Suggested initial fields:

- farm id
- created_by_profile_id
- title, optional
- notes, optional

Status:

- default `open`

## 6. Visita Vacca Base

Purpose:

- create the first basic cow visit workflow

Primary tables:

- `active_animals`
- `cow_visits`

Initial fields to support:

- visit date
- cow selector / cow identifier
- sole count
- bandage count
- antibiotic
- anti-inflammatory
- straw box
- corkscrew grade
- laminitis status
- notes

Predisposed but not required in first screen version:

- advanced claw map
- task derivation UI
- rich history panel

## What Not To Implement Yet

Do not implement now:

- offline sync custom
- advanced claw map
- WhatsApp
- photos
- AI or voice features

## What To Predispose But Delay

- offline/local persistence hooks
- conflict-safe save flow
- legal acceptance gate page if needed by auth flow
- invite acceptance by RPC
- cow history details
- task generation review UI
