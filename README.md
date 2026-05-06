# Appiombi

## Status

Appiombi now includes:

- Supabase schema and RLS foundation
- native Flutter app skeleton in repository code
- brand-aligned theme tokens
- initial mobile routing and placeholder MVP screens

## Repository Areas

- [docs](</C:/Users/syste/Documents/New project 2/Appiombi/docs>) for product, architecture, UI, and setup guidance
- [supabase](</C:/Users/syste/Documents/New project 2/Appiombi/supabase>) for schema, RLS, and migrations
- [lib](</C:/Users/syste/Documents/New project 2/Appiombi/lib>) for the native Flutter application skeleton

## Flutter Skeleton Included

The first native Flutter structure already contains:

- `LoginPage`
- `FarmListPage`
- `FarmDashboardPage`
- `CowListPage`
- `SessionListPage`
- `SessionDetailPage`
- `CowVisitPage`
- app theme, routing, placeholder widgets, and Supabase bootstrap service

## Configuration

The repository includes:

- [.env.example](</C:/Users/syste/Documents/New project 2/Appiombi/.env.example>)

Use placeholders only in version control. Do not commit real Supabase credentials.

## Local Setup

Local Flutter setup instructions are documented in:

- [LOCAL_DEV_SETUP.md](</C:/Users/syste/Documents/New project 2/Appiombi/docs/LOCAL_DEV_SETUP.md>)

Important:

- the repository currently contains the Flutter app source structure and package configuration
- if Android/iOS native folders are not present locally yet, run `flutter create .` before the first build

## Planning References

- [TECH_STACK_DECISION.md](</C:/Users/syste/Documents/New project 2/Appiombi/docs/TECH_STACK_DECISION.md>)
- [NATIVE_FLUTTER_PLAN.md](</C:/Users/syste/Documents/New project 2/Appiombi/docs/NATIVE_FLUTTER_PLAN.md>)
- [MVP_ROADMAP.md](</C:/Users/syste/Documents/New project 2/Appiombi/docs/MVP_ROADMAP.md>)
