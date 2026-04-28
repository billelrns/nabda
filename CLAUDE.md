# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (requires connected device or emulator)
flutter run

# Build Android APK
flutter build apk

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Check for dependency updates
flutter pub outdated
```

## Architecture Overview

Nabda is a Flutter women's health app targeting Arabic-speaking users. It follows a layered architecture:

```
lib/
├── main.dart            # App entry point, locale management, inline translations (~135KB)
├── firebase_options.dart
├── config/              # Theme (Material 3, Almarai font) and GoRouter route definitions
├── models/              # Pure data classes (user, cycle, pregnancy, baby, community, doctor, message)
├── services/            # Firebase/external API wrappers (auth, firestore, notifications, AI)
├── blocs/               # BLoC state management — only auth and cycle are implemented
│   ├── auth/
│   └── cycle/
├── screens/             # One file per screen, organized by feature subdirectory
├── widgets/             # Reusable UI components (5 widgets)
├── utils/               # Constants, helpers, validators
└── l10n/                # ARB files (ar, en) — note: translations are also duplicated inline in main.dart
```

**State management split:** `AuthBloc` and `CycleBloc` use flutter_bloc. Other features (pregnancy, baby, community, doctors) call services directly from screens without a BLoC layer.

**Navigation:** GoRouter with 17 named routes defined in `lib/config/routes.dart`. Initial route is `/splash`.

**Data layer:** All remote data flows through `FirestoreService` (Firestore CRUD) and `AuthService` (Firebase Auth email/password). `sqflite` is declared as a dependency but the primary persistence is Firestore. Local preferences (language selection) use SharedPreferences.

**AI chat:** `lib/services/ai_service.dart` and the `AIChatScreen` in `lib/screens/ai_chat/` call the Google Gemini API directly from the client via `http`. The API key is embedded in `lib/main.dart` around line 2142.

**Localisation:** Three locales — Arabic (`ar-SA`, default), English (`en-US`), French (`fr-FR`). A custom `AppLocalizations` class with a large hardcoded translation map lives in `main.dart`. The `lib/l10n/` ARB files are a secondary/incomplete copy. Locale state is managed by a global `LocaleNotifier` (ChangeNotifier + Provider).

**Theme:** Material 3, primary teal `#00897B`, accent pink `#E91E63`, Almarai Google Font for all text (Arabic-optimised).

## Firebase Setup

The app requires Firebase before it can run:
1. Enable **Authentication** (Email/Password provider) in Firebase console.
2. Create a **Firestore** database.
3. Place `google-services.json` in `android/app/` (excluded from git).
4. Credentials are pre-configured in `lib/firebase_options.dart` for the `nabda-app-ca864` Firebase project.
