# Claw Map Specification

## Purpose

Define the anatomical model for claw observations. MVP uses a simplified clickable map, but backend storage must already support the complete structure below.

## Claw Numbering

Use this numbering in all database and code logic:

1. external left front
2. internal left front
3. internal right front
4. external right front
5. external left rear
6. internal left rear
7. internal right rear
8. external right rear

## Observation Model

Each saved map input belongs to:

- one cow visit
- one claw number 1-8
- one anatomical zone
- one observation group

## Horn / Keratogenous Zones

Zones supported for each claw:

- `bulb`
- `abaxial_wall`
- `axial_wall`
- `apex`
- `toe`
- `sole`

### Horn Popup Data

Fields:

- `extension_grade`: `1`, `2`, `3`
- `lesion_code`:
  - `erosion`
  - `ulcer`
  - `necrosis`
  - `abscess_pus`
  - `hemorrhage`
  - `petechiae`
  - `deep_planes`
  - `sequelae`
- reset area action

## Derm Zones

Zones:

- `digital`
- `interdigital`
- `dewclaw`

### Derm Popup Data

Fields:

- `derma_stage_code`:
  - `stage_1_early`
  - `stage_2_acute`
  - `stage_3_healing`
  - `stage_4_chronic`
  - `stage_4_1_reactivated`
- `extension_grade`: `1`, `2`, `3`
- reset area action

## MVP Simplification

For MVP:

- map interactions may expose a reduced number of clickable areas
- all saved records must still map to the full canonical zone codes
- UI simplification must not force schema changes later

## Reset Behavior

- Reset on one area only clears the targeted active observation.
- Reset should preserve audit history where possible by deactivating the row instead of deleting it.

## Data Storage Pattern

Use one normalized row per observed area:

- `claw_number`
- `zone_type` = `horn` or `derma`
- `zone_code`
- `observation_group`
- `extension_grade`
- lesion or stage payload
- active flag

## Criticality Support

The model must support future derived severity calculations based on:

- number of affected claws
- number of active lesions
- specific lesion codes
- bandages, therapies, and chronic status

This is predisposizione futura and not part of the current UI logic.
