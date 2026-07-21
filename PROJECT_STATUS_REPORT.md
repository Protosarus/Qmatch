# Qmatch — Complete Project Status Report

**Date:** March 9, 2025  
**Scope:** Full repository audit (structure, features, database, matching, UI, security, gaps, technical debt, roadmap)

---

## STEP 1 — PROJECT STRUCTURE

### Framework & language
- **Framework:** Flutter
- **Language:** Dart (SDK `>=3.5.0 <4.0.0`)
- **State management:** `flutter_riverpod` (in `pubspec.yaml`); actual usage is minimal (only `ProviderScope` in `main.dart`). Most screens use local `StatefulWidget` state.
- **Backend:** None. All logic is client-side with **Firebase** as BaaS:
  - **Firebase Auth** — email/password auth
  - **Cloud Firestore** — users, questions
  - **Firebase Storage** — profile photos

### Important folders

| Path | Purpose |
|------|--------|
| `lib/` | Application source |
| `lib/core/` | Shared: theme, auth service, navigation, models, widgets, utils |
| `lib/features/` | Feature modules (auth, profile, assessment, discover, messages, settings) |
| `lib/features/auth/` | Welcome, login, signup, email/phone signup, verification screens |
| `lib/features/profile/` | Profile setup (multi-step), profile screen, photo edit, step widgets |
| `lib/features/assessment/` | IQ/EQ tests, intro screens, question/archetype models, question service |
| `lib/features/discover/` | Discover screen (placeholder) |
| `lib/features/messages/` | Messages screen (empty state) |
| `lib/features/settings/` | Settings screen (UI only) |
| `assets/images/` | Logo and images |
| `assets/data/` | `iq_questions.json`, `eq_questions.json` (bundled question data) |
| `ios/`, `android/` | Platform projects (e.g. iOS Pods include Firebase) |

### Dependencies (notable)
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `google_sign_in`, `sign_in_with_apple` — **present in pubspec but not used in `lib/`**
- `flutter_windowmanager` — used to disable screenshots during tests
- `geolocator`, `geocoding` — location in profile setup
- `image_picker` — profile photos
- `google_fonts` — Playfair Display, Inter, Cinzel

---

## STEP 2 — IMPLEMENTED FEATURES

### 1. Authentication (email)
- **What:** Email/password sign up and login, Firestore user document creation, optional email verification flow.
- **Files:**  
  `lib/core/services/auth_service.dart`,  
  `lib/features/auth/screens/welcome_screen.dart`,  
  `lib/features/auth/screens/signup_screen.dart`,  
  `lib/features/auth/screens/login_screen.dart`,  
  `lib/features/auth/screens/email_signup_screen.dart`,  
  `lib/features/auth/screens/email_verification_screen.dart`,  
  `lib/features/auth/screens/verification_screen.dart`,  
  `lib/features/auth/screens/phone_signup_screen.dart` (present; integration level not fully traced).

### 2. Auth flow & onboarding routing
- **What:** After login, user is routed by: user doc exists → `test_completed` → `profile_completed`. If no user doc or incomplete test → IQ test; if test done but profile not → profile setup; else main app.
- **Files:**  
  `lib/core/navigation/auth_wrapper.dart`,  
  `lib/core/navigation/main_navigation_screen.dart`.

### 3. IQ & EQ assessment (“Minds First”)
- **What:** Sequential IQ then EQ tests (10 questions each), correct-answer scoring, archetype from IQ+EQ bands (HH, HM, … LL), result saved to Firestore. Screenshot disabled during tests.
- **Files:**  
  `lib/features/assessment/services/question_service.dart`,  
  `lib/features/assessment/screens/iq_test_intro_screen.dart`,  
  `lib/features/assessment/screens/iq_test_screen.dart`,  
  `lib/features/assessment/screens/eq_test_intro_screen.dart`,  
  `lib/features/assessment/screens/eq_test_screen.dart`,  
  `lib/features/assessment/models/question_model.dart`,  
  `lib/features/assessment/models/archetype_model.dart`,  
  `lib/core/services/auth_service.dart` (`updateTestCompletion`).

### 4. Questions from Firestore or local JSON
- **What:** IQ/EQ questions loaded from Firestore `questions` collection (by `type`: `iq`/`eq`, `active: true`); fallback to bundled `assets/data/iq_questions.json` and `eq_questions.json`. Dev helper to upload questions to Firestore.
- **Files:**  
  `lib/features/assessment/services/question_service.dart`,  
  `lib/core/utils/upload_questions_helper.dart`.

### 5. User profiles (create & view)
- **What:** Multi-step profile setup (basic info, bio, interests, lifestyle, preferences), save to Firestore under `users/{uid}`. Profile screen shows name, age, archetype, location, bio, interests, education, lifestyle.
- **Files:**  
  `lib/features/profile/screens/profile_setup_screen.dart`,  
  `lib/features/profile/screens/profile_screen.dart`,  
  `lib/features/profile/screens/steps/basic_info_step.dart`,  
  `lib/features/profile/screens/steps/bio_step.dart`,  
  `lib/features/profile/screens/steps/interests_step.dart`,  
  `lib/features/profile/screens/steps/lifestyle_step.dart`,  
  `lib/features/profile/screens/steps/preferences_step.dart`,  
  `lib/features/profile/models/user_profile_model.dart`,  
  `lib/features/profile/services/profile_service.dart`.

### 6. Profile photos
- **What:** Pick single/multiple images, upload to Firebase Storage (`profile_photos/{userId}/...`), store URLs in user profile. Delete photo from Storage and update profile.
- **Files:**  
  `lib/features/profile/services/photo_upload_service.dart`,  
  `lib/features/profile/screens/profile_photo_edit_screen.dart`.

### 7. Name selection (post–EQ)
- **What:** Screen to set/confirm display name after assessment, then continue to profile setup.
- **Files:**  
  `lib/features/profile/screens/name_selection_screen.dart`.

### 8. Discover screen (placeholder)
- **What:** Static “Keşfet” screen with icon and text “Yakında burada IQ/EQ uyumlu eşleşmeler görebileceksin.” No feed, no like/pass.
- **Files:**  
  `lib/features/discover/screens/discover_screen.dart`.

### 9. Messages screen (placeholder)
- **What:** “Mesajlar” tab with empty state: “Henüz mesajın yok” / “Eşleşmeye başladığında mesajların burada görünecek.” No matches or messaging logic.
- **Files:**  
  `lib/features/messages/screens/messages_screen.dart`.

### 10. Settings screen (UI only)
- **What:** List of options: Notifications, Privacy, Blocked users, Help, About, Logout. All `onTap` are `// TODO`; no navigation or logout implementation.
- **Files:**  
  `lib/features/settings/screens/settings_screen.dart`.

### 11. Theming & shared UI
- **What:** Central colors (gold primary, dark background), shared widgets (e.g. `SuccessDialog`, `elegant_warning`).
- **Files:**  
  `lib/core/theme/app_colors.dart`,  
  `lib/core/theme/app_theme.dart`,  
  `lib/core/widgets/success_dialog.dart`,  
  `lib/core/widgets/elegant_warning.dart`.

### 12. Debug entry (development)
- **What:** In debug mode, home is a debug screen with: “Upload Questions to Firebase”, “Go to Auth Wrapper”, “Go to Welcome Screen”, “Go to Main App Screen”.
- **Files:**  
  `lib/main.dart` (`kDebugMode ? const DebugHomeScreen() : const AuthWrapper()`).

---

## STEP 3 — DATABASE ANALYSIS

All persistence is **Firestore** and **Firebase Storage**; no separate SQL or other DB.

### Firestore collections

| Collection | Document / structure | Purpose |
|------------|----------------------|--------|
| **users** | `users/{uid}` | One doc per user. Holds auth-related flags, assessment results, and full profile (merged from `UserProfileModel.toFirestore()`). |
| **questions** | `questions/iq_feb_2026`, `questions/eq_feb_2026` (or similar) | Single docs per type with `type`, `active`, `questions` (array), `question_count`, `created_at`. Used for IQ/EQ tests. |

### User document shape (in code)

From `auth_service.dart` and `user_profile_model.dart`:

- **Auth/onboarding:** `name`, `email`, `test_completed`, `profile_completed`, `created_at`
- **Assessment:** `archetype`, `category`, `iq_score`, `eq_score`, `iq_normalized`, `eq_normalized`, `test_completed_at`
- **Profile:** `name`, `age`, `gender`, `location` (GeoPoint), `location_text`, `education`, `bio`, `interests`, `occupation`, `drinking`, `smoking`, `pets`, `children`, `religion`, `animal_love`, `looking_for`, `age_range`, `distance_preference`, `photos`, `profile_photo_url`, `profile_completed`, `verified`, `completed_at`

So **one flat user document** holds both “account” and “profile” data; no separate `profiles` collection.

### Relationships
- **users ↔ questions:** None. Questions are global config docs.
- **users ↔ users:** No links in data model (no likes, matches, or blocks stored).

### What is not in the database
- **Likes** — no collection or subcollection
- **Matches** — no collection or documents
- **Messages** — no collection or documents
- **Reports** — none
- **Blocks** — none

### Firebase Storage
- **Path:** `profile_photos/{userId}/{fileName}` (e.g. `profile_${userId}_${timestamp}_$i.jpg`)
- Used only for profile photo upload/delete in `PhotoUploadService`.

---

## STEP 4 — MATCHING SYSTEM

**Status: Not implemented.**

- There is **no like/pass** (no “like” or “pass” actions, no storage of who liked whom).
- There is **no match creation** when two users like each other.
- **Discover** does not show other users’ profiles and does not call any matching or recommendation logic.
- **Messages** do not depend on matches; there is no “matches” list and no chat backend.

The product concept (private likes → mutual match → then messaging) is **not** implemented; only the assessment and profile flows are in place.

---

## STEP 5 — UI / SCREEN ANALYSIS

| Screen | Implemented | Notes |
|--------|-------------|--------|
| **Welcome** | ✅ | Logo, slogan, Sign Up / Login. |
| **Login** | ✅ | Email, password, validation, error handling. |
| **Sign Up** | ✅ | Name, email, password; creates Auth + Firestore user. |
| **Email signup / verification** | ✅ | Alternative signup path; verification screen (code entry) present; actual verification logic may be partial. |
| **Phone signup** | Present | Screen exists; integration with auth flow not fully verified. |
| **Verification** | ✅ | Code entry; navigates to IQ test intro. |
| **IQ test intro** | ✅ | “IQ Test” title, “START IQ TEST” button. |
| **IQ test** | ✅ | 10 questions, next, transition to EQ. |
| **EQ test intro** | ✅ | Intro before EQ test. |
| **EQ test** | ✅ | 10 questions, archetype result dialog, then name selection. |
| **Name selection** | ✅ | Display name, then profile setup. |
| **Profile setup** | ✅ | 5 steps: Basic info, Bio, Interests, Lifestyle, Preferences. |
| **Profile** | ✅ | View own profile, archetype, photo; edit photo via separate screen. |
| **Profile photo edit** | ✅ | Add/remove photos, set profile photo, save to Firestore. |
| **Discover** | Placeholder | Static “Keşfet” / “coming soon” content. |
| **Messages** | Placeholder | Empty state only. |
| **Settings** | UI only | No behavior behind items; logout/blocked/etc. are TODO. |
| **Main app (tabs)** | ✅ | Discover, Mesajlar, Profil, Ayarlar. |
| **Debug home** | ✅ | Only in debug; upload questions, shortcuts. |

There is **no** dedicated onboarding screen beyond welcome → signup/login; no separate “Matches” or “Chat” screen; no report/moderation screens.

---

## STEP 6 — SECURITY & PRIVACY

### Implemented
- **Screenshot blocking:** `FlutterWindowManager.addFlags(FLAG_SECURE)` on IQ and EQ test screens to reduce copying of questions; cleared on dispose.
- **Firebase Auth:** Email/password; email verification sent on signup (usage in flow may be optional).
- **Profile photos:** Stored under `profile_photos/{userId}/`; access not further restricted in app code (relies on Firebase Storage rules, not in repo).

### Not in repository
- **Firestore rules:** No `firestore.rules` (or similar) file found. If none are deployed, Firestore may be open for read/write by any authenticated (or even unauthenticated) client, which is a **critical** risk.
- **Storage rules:** No `storage.rules` audited in this repo.

### Gaps
- No **server-side** validation of likes/matches/messages (no Cloud Functions).
- **Google Sign-In / Sign in with Apple:** In pubspec but unused; no OAuth flows.
- **Logout:** Settings “Çıkış Yap” is TODO; users cannot log out from the app.
- **Blocking / reporting:** No data model or APIs; only Settings UI placeholders.
- **Privacy:** No in-app privacy settings (e.g. who can see profile, optional screenshot protection beyond tests). Optional “screenshot protection” for chats is not implemented (no chats).

---

## STEP 7 — MISSING FEATURES

Against the expected core feature list:

| # | Feature | Status |
|---|--------|--------|
| 1 | User profiles | ✅ Implemented (create, view, edit photo). |
| 2 | Profile discovery feed | ❌ Missing (Discover is placeholder). |
| 3 | Like / pass system | ❌ Missing. |
| 4 | Mutual match creation | ❌ Missing. |
| 5 | Matches list | ❌ Missing. |
| 6 | Messaging between matches | ❌ Missing. |
| 7 | Blocking users | ❌ Missing (Settings entry only). |
| 8 | Reporting users | ❌ Missing. |
| 9 | Moderation tools | ❌ Missing. |
| 10 | Privacy protections (e.g. optional screenshot protection) | ⚠️ Partial (screenshot off only during IQ/EQ tests). |

Additional gaps:
- **Logout** not implemented.
- **Settings** sub-screens (notifications, privacy, blocked, help, about) not implemented.
- **Profile edit** (bio, interests, etc.) is TODO on profile screen.
- **Discovery filters** (age, distance, preferences) exist in profile model but are not used in any feed or matching logic.

---

## STEP 8 — TECHNICAL DEBT

### Architecture
- **State management:** Riverpod declared but barely used; most logic is in `StatefulWidget` and direct service calls. Harder to test and to share state (e.g. current user profile, matches).
- **Navigation:** Imperative `Navigator.push`/`pushReplacement`/`pushAndRemoveUntil`; no single routing/navigation abstraction or deep links.
- **Feature structure:** Features are organized by folder, but services are instantiated per screen (e.g. `ProfileService()`, `AuthService()`) rather than injected or provided once.
- **Backend:** All logic in client; no Cloud Functions for match creation, notifications, or security-sensitive operations. Matching and messaging will be hard to do safely and consistently without server logic.

### Bugs / quality
- **Profile setup success:** In `profile_setup_screen.dart`, `onContinue` of `SuccessDialog` calls `pushAndRemoveUntil` **twice** with the same route (lines 144–156). Redundant and can cause odd stack behavior.
- **Verification screen:** `_handleVerify()` navigates to IQ test intro without verifying the code; verification is effectively bypassed.
- **Mixed locales:** UI mixes English (Welcome, Login, Create Account) and Turkish (Keşfet, Mesajlar, Ayarlar, profil strings). No centralized i18n.

### Scalability & performance
- **User discovery:** When implemented, loading “all users” or large subsets from Firestore without server-side logic (e.g. recommendation service) will not scale and will increase cost and latency.
- **Questions:** Full question sets loaded into memory; for very large sets, paging or chunking would be better.
- **Profile photos:** Multiple URLs stored in one document; if many photos per user, consider subcollections or separate docs to avoid document size limits.

### Security
- **Firestore:** Absence of rules in repo implies risk of misconfiguration in production.
- **Sensitive data:** IQ/EQ raw scores and normalized scores stored in user document; any client with read access to that doc can see them. Product intent (only show archetype) is not enforced by access control in app.

### Duplication
- **Auth error handling:** Similar `FirebaseAuthException` handling in login and signup; could be a shared helper.
- **Form styling:** Repeated `InputDecoration` and border styles across auth and profile steps; could be shared in theme or widgets.

---

## STEP 9 — PROJECT STATUS

**Classification: Early development (leaning prototype).**

**Reasoning:**
- **Prototype:** Core idea (private like → mutual match → chat) is not built; no discovery, no likes, no matches, no messaging. The app currently demonstrates **onboarding + assessment + profile** only.
- **Early development:** Codebase is structured (features, services, models), uses Firebase consistently, and has a clear path to add Firestore collections and screens for likes/matches/messages. So it is beyond a one-off prototype.
- **Not partial MVP:** An MVP for Qmatch would require at least: discovery feed, like/pass, mutual match creation, matches list, and basic messaging. None of these exist.
- **Not near production:** Logout missing, settings non-functional, no Firestore/Storage rules in repo, no moderation/reporting, and no real security or privacy story for the core product.

**Verdict:** **Early development** — solid onboarding and profile foundation, but the core matching product is not yet implemented.

---

## STEP 10 — DEVELOPMENT ROADMAP

### 1) Critical fixes (before any production use)
- Add **Firestore rules** (and Storage rules): e.g. users can read/write only their own `users/{uid}`; define rules for future `likes`, `matches`, `messages` so only involved users can read/write.
- Implement **logout** in Settings (call `FirebaseAuth.instance.signOut()`, then navigate to Welcome/AuthWrapper).
- Fix **profile setup** success flow: single `pushAndRemoveUntil` to the main app or profile, and ensure `profile_completed` is set so `AuthWrapper` shows main app.
- Either implement **email/phone verification** properly in `VerificationScreen` or remove/bypass it so the flow is consistent.

### 2) Core features (MVP)
- **Discovery feed:**  
  - Firestore query for other users (exclude current user; respect blocks later).  
  - Apply filters (age range, distance, preferences) and optionally archetype/category.  
  - Pagination or limit to avoid loading entire user set.
- **Like / pass:**  
  - New collection e.g. `likes` (e.g. `from_uid`, `to_uid`, `created_at`).  
  - Ensure “pass” is not stored as a like (or use a separate structure if needed).  
  - Enforce “one like per pair” and privacy (B cannot see A’s like until B likes A).
- **Match creation:**  
  - On “like”, check if the other user has already liked current user; if yes, create a match (e.g. `matches` collection or subcollection).  
  - Prefer **Cloud Functions** (or similar) to create matches and keep logic consistent and secure.
- **Matches list:**  
  - Screen that lists matches (from `matches` where user is participant).  
  - Tap → open chat (or placeholder).
- **Messaging:**  
  - Subcollection e.g. `matches/{matchId}/messages` (or similar).  
  - Real-time listener for the conversation; send message (with security rules).  
  - Basic chat UI (list + input).

### 3) UX improvements
- **Profile edit:** Implement the “Edit profile” path (bio, interests, lifestyle, preferences) instead of TODO.
- **Settings:** Implement Notifications, Privacy, Help, About (and optionally Blocked) with real screens or in-app content.
- **Discovery UX:** Card stack or tinder-like interaction; clear like/pass buttons; optional “undo” for last action.
- **Localization:** Centralize strings; support at least English and Turkish consistently.
- Remove **duplicate** navigation in profile setup success and fix any similar double-push patterns elsewhere.

### 4) Growth & safety features
- **Blocking:** `blocks` collection or field; filter discovery and matches by blocked users; hide blocked user’s content and messages.
- **Reporting:** `reports` collection; report user or message; optional Cloud Function to notify moderators or flag content.
- **Moderation:** Admin/moderator view (separate app or protected route): list reports, view users, ban/restrict accounts. Depends on reporting and possibly custom claims or a separate “admin” store.

### 5) Optional future features
- **Google / Apple sign-in:** Use existing `google_sign_in` and `sign_in_with_apple` for alternative login.
- **Optional screenshot protection:** Extend FLAG_SECURE to chat or sensitive profile screens if desired.
- **Push notifications:** FCM for new matches and new messages (with backend or Firebase triggers).
- **Recommendation logic:** Use archetype, location, preferences (and later behavior) to rank discovery feed (e.g. Cloud Functions or separate service).
- **Verification badge:** Use `users.verified` and show badge in profile and cards when verified (after implementing a verification flow).

---

## Summary table

| Area | Status |
|------|--------|
| **Stack** | Flutter, Dart, Firebase (Auth, Firestore, Storage) |
| **Auth** | Email signup/login ✅; verification flow partial; logout ❌ |
| **Onboarding** | IQ → EQ → archetype → name → profile setup ✅ |
| **Profiles** | Create, view, photo upload/edit ✅ |
| **Discover** | Placeholder only ❌ |
| **Likes / pass** | Not implemented ❌ |
| **Matches** | Not implemented ❌ |
| **Messages** | Empty state only ❌ |
| **Block / report / moderation** | Not implemented ❌ |
| **Security (rules)** | No rules in repo ⚠️ |
| **Project phase** | **Early development** |

This report should be enough for someone returning after months to understand the codebase, what works, what is missing, and what to do next.
