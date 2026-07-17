<!-- .github/copilot-instructions.md -->
# QMatch — Copilot instructions

Purpose
- Help AI coding agents become productive quickly in this Flutter project.

Quick summary
- Flutter app using Riverpod for state management and Firebase for backend services.
- Feature-driven layout: domain features live under `lib/features/*`; shared utilities and widgets live under `lib/core/*`.

Key files to read first
- `lib/main.dart` — app entry, Firebase initialization, and global providers.
- `lib/core/` — app-wide constants, models, services, theme, utils, and shared widgets.
- `lib/features/*` — each feature (auth, assessment, matching, chat, profile, ai_coach) contains its own screens, providers and services.
- `lib/firebase_options.dart` — generated Firebase configuration (do not hand-edit; update via FlutterFire CLI).
- `pubspec.yaml` — dependencies and asset listing.
- `assets/data/iq_questions.json` — example domain data used by assessment feature.
- `ios/Runner/AppDelegate.swift` and `android/app` — native integration points (Google Sign-In, Firebase config).

Project architecture notes
- Domain-driven features: add new UI/screens under `lib/features/<feature>/screens` and place related providers/services under that feature folder.
- Shared logic belongs in `lib/core/services` and `lib/core/widgets` to avoid duplication.
- State management is Riverpod-based (look for `Provider`/`StateNotifierProvider` usages across `features/*`).

Build & run (developer workflows)
- Get dependencies: `flutter pub get`.
- Static checks & formatting: `flutter analyze` and `dart format .` (project includes `analysis_options.yaml` with `flutter_lints`).
- Run on device/emulator: `flutter run -d <device-id>` from repo root.
- iOS specifics: `cd ios && pod install` then open `ios/Runner.xcworkspace` in Xcode for signing/building. Native Firebase/GoogleSignIn code is in `ios/Runner/AppDelegate.swift`.
- Android specifics: `./gradlew assembleDebug` from `android/` (gradle wrapper present).

Generated & vendor files
- Avoid editing generated files: `build/`, `ios/Pods/`, `ios/Runner/GeneratedPluginRegistrant.*`, and `*.g.dart`/generated code. Use the appropriate generator/CLI to update.
- Firebase config is generated into `lib/firebase_options.dart`; use the FlutterFire CLI to re-run configuration.

Patterns & conventions
- Keep UI, state (providers), and services separated: `screens/` for UI, `providers/` (or `notifiers`) for state, `services/` for backend calls.
- Assets: update `pubspec.yaml` when adding images or JSON in `assets/` and run `flutter pub get`.
- Native callbacks (e.g., Google Sign-In) are implemented in platform AppDelegate/Activity — check `ios/Runner/AppDelegate.swift` and `android/` for deep links and intent handling.

Integration points & external deps
- Firebase (Analytics/Auth/Firestore/Storage) — initialized in `lib/main.dart` and `ios/Runner/AppDelegate.swift`.
- Google Sign-In — native hook in `AppDelegate.swift` (see `application(_:open:options:)`).
- JSON assets (e.g., `assets/data/iq_questions.json`) are used directly by assessment features; treat them as immutable fixtures unless specifically modified.

What the AI should NOT do
- Do not modify files under `build/`, `ios/Pods`, or other generated outputs.
- Do not replace `lib/firebase_options.dart` manually; reconfigure via FlutterFire tools if needed.

If you need more context
- Start by opening [lib/main.dart](lib/main.dart#L1-L40), [lib/core](lib/core), and a feature like [lib/features/auth](lib/features/auth).

When you produce changes
- Keep edits local to `lib/` unless a clear native change is required (and then document the native steps). Run `flutter analyze` and `dart format` before submitting PRs.

Questions for the repo owner
- Are there CI or environment secrets required to run integration flows (Firebase emulators, API keys)?
- Any feature branching or flavor builds to be aware of?

End of file
