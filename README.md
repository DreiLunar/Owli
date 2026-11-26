# Owli

A mobile study companion built with Flutter/Dart and Firebase, aligned with **UN SDG 4 (Quality Education)**. Owli helps students organize subject-based study notes and practice active recall with manual flashcard decks.

## MVP Scope

- **Authentication & Isolation:** Email/password sign-up and sign-in via Firebase Auth with per-user data isolation (`users/{uid}/...`).
- **Subjects & Notes:** Subject folders and plain-text note CRUD.
- **Flashcards & Study Mode:** Manual flashcard decks, Q/A card editor, flip-card study sessions (`Got It` / `Still Learning`), and basic progress tracking.

## Project Structure

```text
lib/
├── core/
│   ├── navigation/
│   │   ├── app_routes.dart
│   │   └── app_shell.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_spacing.dart
│       └── app_theme.dart
├── features/
│   ├── account/
│   │   └── presentation/screens/account_screen.dart
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   └── presentation/sign_in_screen.dart
│   ├── decks/
│   │   └── data/
│   │       ├── deck_providers.dart
│   │       └── deck_repository.dart
│   ├── flashcards/
│   │   ├── data/
│   │   │   ├── mock/
│   │   │   │   ├── mock_decks.dart
│   │   │   │   └── mock_study_store.dart
│   │   │   └── repositories/mock_study_repository.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── deck.dart
│   │   │   │   ├── flashcard.dart
│   │   │   │   └── study_progress.dart
│   │   │   ├── repositories/study_repository.dart
│   │   │   └── services/study_session_controller.dart
│   │   └── presentation/
│   │       ├── create_deck_screen.dart
│   │       └── screens/
│   │           ├── create_deck_screen.dart
│   │           ├── create_flashcard_screen.dart
│   │           ├── deck_details_screen.dart
│   │           ├── deck_library_screen.dart
│   │           └── study_session_screen.dart
│   ├── home/
│   │   └── presentation/screens/home_screen.dart
│   └── notes/
│       └── presentation/screens/notes_screen.dart
├── widgets/
│   ├── empty_state.dart
│   ├── error_state.dart
│   ├── loading_state.dart
│   ├── section_header.dart
│   └── stat_tile.dart
├── main.dart
└── study_preview.dart
```

## Getting Started (Local Setup)

### Prerequisites

- **Flutter SDK** (`stable` channel, Dart `^3.14.0`)
- **Android Studio** or **VS Code** (with Flutter & Dart extensions)
- **Android device or emulator** (API 24+)

### Setup & Run

```bash
# 1. Clone the repository
git clone https://github.com/DreiLunar/Owli.git
cd Owli

# 2. Switch to the active integration branch
git checkout dev

# 3. Install dependencies
flutter pub get

# 4. Run on a connected Android device or emulator
flutter run

# 5. Run the test suite
flutter test
```

> **Note:** Local Firebase configuration files (`lib/firebase_options.dart` and `android/app/google-services.json`) are gitignored and must be generated or added locally before running the full Firebase-backed app.

## Branch Workflow

- `main`: Stable release builds and verified APK milestones
- `dev`: Active integration branch
- `feature/*` & `docs/*`: Working branches merged into `dev` via Pull Requests

## Team & Roles

| Role | Member | Responsibilities |
| :--- | :--- | :--- |
| `3Y-1 Lead / Integration` | Von | Coordination, integration, release APK, submission |
| `3Y-2 Flutter / UI` | Tine | Navigation, UI screens, subject & note CRUD, video editing |
| `3Y-3 Firebase / Data` | Nath | Authentication, Firestore schema, security rules, setup docs |
| `3Y-4 Study / QA` | Ed | Flashcard decks, study mode, automated & physical device QA |

## Architecture & Database Notes (OW-034)

> **Placeholder:** Nath (`3Y-3`) will expand this section prior to final handoff with Firebase configuration steps, Firestore collection schemas, security rules, and known limitations.
