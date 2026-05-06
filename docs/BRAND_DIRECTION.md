# Brand Direction

## Visual Identity Summary

The Appiombi product should feel:

- precise
- reliable
- professional
- technologically solid
- clinically operational
- modern for dairy farm environments

The visual language should communicate:

- fast mobile usability
- trustworthy field operations
- clean data handling
- calm authority

It should not feel:

- playful
- overly veterinary or hospital-like
- consumer-startup trendy
- dark and heavy
- rustic agricultural
- visually crowded

## Relationship With Dairy Balance

Dairy Balance is the parent brand.
Appiombi should be recognizable as its own product.

Recommended relationship rules:

- the product name/logo is the main hero in splash and login
- Dairy Balance may appear as `by Dairy Balance`
- Dairy Balance logo should stay secondary
- parent-brand presence is appropriate in:
  - splash small caption
  - login footer
  - about/settings
- Dairy Balance should not dominate:
  - app title
  - navigation bar
  - dashboard header

The goal is brand continuity without parent-brand visual overload.

## Color Direction

The palette should be inspired by the Dairy Balance logo:

- warm orange
- gold / bronze
- sage green / grey-green
- cyan / light blue

The UI palette must stay readable outdoors and on mobile screens in bright conditions.

## Recommended Palette

### Core Palette

- `Primary`: `#D8831F`
  Warm technical amber-orange for primary actions and key emphasis.

- `Secondary`: `#2EA7D8`
  Clean cyan-blue for navigation, data context, and selected states.

- `Accent`: `#7F9C8F`
  Sage green for contextual balance, stable states, and softer highlights.

- `Background`: `#F7F8F6`
  Warm off-white to avoid sterile pure white while keeping brightness.

- `Surface / Card`: `#FFFFFF`
  Clean white for cards, forms, and elevated content.

### Functional Colors

- `Success`: `#5E8F69`
  Stable green with enough weight for field readability.

- `Warning`: `#C98A1A`
  Strong amber for non-critical attention and medium priority.

- `Danger`: `#C84B4B`
  Reserved only for critical states, blocking errors, or severe pathology emphasis.

### Text And UI Support

- `Text Primary`: `#223035`
  Deep slate for strong legibility.

- `Text Secondary`: `#5D6B71`
  Muted slate-grey for secondary information.

- `Border / Divider`: `#D8DFE1`
  Light cool divider that stays visible without feeling heavy.

## Color Usage Rules

- use orange/amber for primary CTA and non-critical attention
- use cyan/blue for navigation, active filters, selected tabs, and data widgets
- use sage green for stable/healthy/completed context
- use red only for:
  - destructive actions
  - overdue or blocked tasks
  - severe warning states
- avoid using too many saturated colors on the same screen
- prefer one dominant action color per screen

## Typography Recommendation

## Recommended Combination

- `Primary font`: `IBM Plex Sans`
- `Alternative font`: `Inter`

Why `IBM Plex Sans`:

- excellent readability on mobile
- numerals are clear and operational
- feels technical but not cold
- works well for lists, dashboards, and form-heavy interfaces
- has enough personality without becoming editorial

Why `Inter` as fallback:

- highly available
- excellent on Flutter/FlutterFlow
- strong UI consistency

## Typography Roles

- Titles: `IBM Plex Sans` semibold
- Body: `IBM Plex Sans` regular
- Buttons: `IBM Plex Sans` semibold
- Dashboard numbers: `IBM Plex Sans` semibold or bold
- Dense list/table labels: `IBM Plex Sans` medium

## Suggested Sizes

- `H1`: 28
- `H2`: 22
- `H3`: 18
- `Body`: 15
- `Small`: 13
- `Button`: 15
- `Table/List Item`: 15
- `Dashboard Numeric Highlight`: 24 to 30

## Typography Rules

- keep line height generous for field readability
- avoid ultra-light weights
- prefer medium/semibold for actionable labels
- keep numerals visually strong in KPI cards and session counts

## UI Style

The UI should be:

- mobile-first
- native-feeling on Android and iOS
- bright and clean
- operationally fast
- calm, not decorative

Visual principles:

- medium rounded corners
- large tap targets
- light shadows only
- clear dividers
- generous white space
- linear icons
- block-based dashboard layout
- minimal ornament in work-critical flows

## Component Guidelines

## 1. Splash Screen

- product logo centered
- optional small caption `by Dairy Balance`
- clear light background
- one calm accent color or subtle gradient
- no busy illustration

## 2. Login

- product identity is primary
- Dairy Balance reference small and low emphasis
- compact professional form
- background clean and bright
- primary button in orange/amber
- secondary actions in blue/cyan text or outline

## 3. Home Vet / Hoof Trimmer

- searchable farm list
- clear operational hierarchy
- notification area visible but not alarming by default
- future aggregate statistics may use muted dashboard cards

Recommended card content:

- farm name
- full address
- city and province
- optional farm code
- access mode if useful

## 4. Farm Dashboard

- summary cards at top
- open tasks visible early
- new session CTA prominent
- search cow and history access immediately reachable
- use blue/cyan for navigational sections
- use amber for primary action

## 5. Trimming Session

- minimum decoration
- maximum speed
- strong emphasis on hierarchy and touch targets
- sticky or highly visible action buttons where appropriate
- search and sort should feel utilitarian, not decorative

## 6. Cow Visit

- group generic data into clear cards or sections
- historical access always easy to reach
- map access visible but not visually dominant over mandatory fields
- `Save`, `Previous`, and `Next` actions must be visually distinct
- avoid placing too many equal-priority buttons together

## 7. Claw Map

- clean dark outlines
- high contrast selected states
- limited color system for severity

Severity suggestion:

- extension 1: `#E0B35A`
- extension 2: `#D8831F`
- extension 3: `#C84B4B`

Rules:

- keep neutral base drawing
- highlight only active selected areas
- reset area action must be clear and not hidden

## 8. Task / Reminder UI

- overdue tasks: red accent, strong contrast
- today tasks: amber/orange emphasis
- future tasks: neutral or sage/secondary styling
- avoid rainbow-coded lists
- one priority system should dominate over decorative color variety

## Buttons

Recommended styles:

- `Primary button`: filled amber-orange with white text
- `Secondary button`: white or light surface with blue border/text
- `Tertiary button`: text-only in slate/blue
- `Danger button`: red only for delete or critical actions

Button shape:

- medium rounded corners, around 12 to 14 px visual radius

Button sizing:

- tall enough for glove-friendly interaction
- avoid narrow pill buttons for critical field workflows

## Cards

- white background
- subtle shadow
- light divider when content is dense
- radius around 14 to 18 px
- clear header/value separation

## Dashboard And Graphs

Dashboard blocks should feel structured and operational.

Use:

- one strong KPI per card
- short labels
- clear numeric emphasis
- muted supporting text

Graph rules:

- avoid overloaded multi-series charts
- use blue/cyan for main series
- use sage as secondary stable series
- use amber for attention series
- reserve red for critical exception values only
- prioritize legibility over stylistic flourish

## Farm List Rule

To disambiguate similar farms, list cards should show:

- farm name
- full address
- city
- province
- optional farm code

Example:

`Azienda Agricola Rossi`
`Via Roma 12, 42025 Cavriago (RE)`

`Azienda Agricola Rossi`
`Via Roma 14, 42025 Cavriago (RE)`

## Icon Style

- linear icons
- medium stroke weight
- rounded but not cartoonish
- clean geometry
- use filled icons only for rare emphasis states

Avoid:

- playful rounded mascot icons
- overly medical iconography
- rustic farm pictograms as the dominant style

## Future Product Logo Criteria

The future product logo should be:

- clearly separate from Dairy Balance master logo
- visually compatible with the palette
- simple enough to work as square app icon
- recognizable at small sizes

Possible concept directions:

- hoof/claw geometry
- balance/equilibrium
- structured clinical mapping
- indirect bovine reference
- data tracking or route marks

Avoid:

- direct imitation of Dairy Balance logo
- generic veterinary cross as dominant symbol
- complex emblem with many fine details
- overly rustic animal illustration

## Things To Avoid

- dark-first UI
- low-contrast pastel palette
- bright red used as a common accent
- consumer wellness aesthetic
- hospital sterile blue/white identity
- rustic brown/green farm cliché
- over-decorated dashboards
- tiny action buttons
- weak typography for numbers and IDs

## Brand Summary

The product should look like a serious, modern, field-ready operational tool:

- bright enough for outdoor/stable use
- structured enough for professional trust
- modern enough to feel digital and advanced
- calm enough to support repeated daily use

Recommended short signature:

`Appiombi by Dairy Balance`
