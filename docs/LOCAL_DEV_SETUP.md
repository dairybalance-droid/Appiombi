# Local Dev Setup

## Purpose

This document explains the minimum local setup to run the first native Flutter skeleton for Appiombi.

## Required Tools

- Flutter stable SDK
- Dart SDK bundled with Flutter
- Android Studio or Xcode for native targets
- Git

## 1. Clone And Enter The Repository

```powershell
git clone https://github.com/dairybalance-droid/Appiombi.git
cd Appiombi
```

## 2. Install Flutter Stable

- install Flutter stable from the official Flutter documentation
- confirm the SDK is available in `PATH`
- run `flutter doctor`

## 3. Prepare Environment Variables

The repository includes:

- `.env.example`

Update the placeholder values before real Supabase login tests:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Important:

- do not commit real keys or secrets
- keep production secrets outside the repository

## 4. Install Packages

Generate the native Android/iOS shell in the repository root if it is not present yet:

```powershell
flutter create .
```

Then install the packages:

```powershell
flutter pub get
```

## 5. Run Static Checks

```powershell
flutter analyze
```

## 6. Run The Native Skeleton

```powershell
flutter run
```

## Windows Shortcut Script

On Windows, after each Codex push, you can run:

```powershell
scripts\dev_run_chrome.bat
```

The script runs in sequence:

- `git pull`
- `flutter pub get`
- `flutter analyze`
- `flutter run -d chrome`

The script stops immediately if one step fails and keeps the terminal window open at the end.

## Windows Desktop Launcher

You can create a Desktop launcher once with:

```powershell
scripts\create_desktop_launcher.bat
```

After that, you can start Appiombi directly from the Windows Desktop with double click on:

- `Appiombi Dev Chrome`

The Desktop shortcut runs `scripts\dev_run_chrome.bat`, which:

- updates the repository with `git pull`
- runs `flutter pub get`
- runs `flutter analyze`
- launches the app with `flutter run -d chrome`

## Current Scope

This first Flutter skeleton includes:

- native app shell
- brand-aligned theme
- login page
- farm list page
- farm dashboard placeholder
- cow list placeholder
- session list/detail placeholders
- cow visit base placeholder
- Supabase service bootstrap

## Not Implemented Yet

- offline sync engine
- local database
- podal map
- photo flows
- WhatsApp
- AI/voice
