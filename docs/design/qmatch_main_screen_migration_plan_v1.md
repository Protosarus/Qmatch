# QMatch Main Screen Migration Plan v1

Phase: **P2C-1C-0** · Implementation order for P2C-1C-1+

---

## Global order

1. Shared main-app shell  
2. Bottom navigation  
3. Discover  
4. Messages  
5. Profile  
6. Settings  
7. Cross-screen loading / error / empty states  
8. iOS + Android visual verification  

Do **not** redesign CM v2 / preference / values / hard-constraint / structured-explanation UIs here.

---

## 1. Shared main-app shell

| item | detail |
|------|--------|
| Files | `lib/core/navigation/main_navigation_screen.dart`, optionally new `qmatch_scaffold` / background under `lib/core/widgets/` |
| Runtime today | IndexedStack-like swap of Discover / Messages / Profile; flat black scaffold |
| Data | none |
| Visual changes | `QMatchBackground` + `QMatchScaffold`; status bar light; optional subtle cosmic wash (no Welcome asset stack required) |
| Functional fixes | none required for shell-only |
| Components | QMatchScaffold, QMatchBackground, QMatchBottomNavigation |
| Acceptance | Tabs still switch; body not clipped by nav; safe area OK |
| Dependencies | Design contract tokens |
| Risk | Medium — padding miscalc can clip lists |

---

## 2. Bottom navigation

| item | detail |
|------|--------|
| Files | `main_navigation_screen.dart` |
| Runtime | 3 icons; selected gold border pill; no visible labels |
| Visual | Extract `QMatchBottomNavigation`; consider optional labels (l10n already exists) ⏳ |
| Functional | Keep Settings **out** of tabs (Profile → Settings) |
| Acceptance | Same indices; Semantics labels retained; height ~56+safe |
| Risk | Low if extracted carefully |

---

## 3. Discover

| item | detail |
|------|--------|
| Files | `lib/features/discover/screens/discover_screen.dart`, `lib/features/discover/widgets/*`, `lib/features/discover/utils/discover_identity_format.dart` (services/models unchanged for query/scoring) |
| Runtime | Load candidates; like/pass; match dialog; deletion banner |
| Data | `DiscoverService`, `SwipeService`, `MatchService`, user doc |
| Visual | **P2C-1C-2:** modern header, glass candidate card, photo scrim, cosmic action bar, loading/empty/error states, modernized match dialog |
| Functional problems to fix **separately if in scope** | SnackBar raw exceptions mitigated to localized copy + debugPrint; reverse-block still client TODO (backend_dependency — do not pretend visual fix); legacy CompatibilityScoring / CM v2 offline / filter gaps remain |
| Components | QMatchDiscoverHeader, QMatchCandidateCard, QMatchCandidatePhoto, QMatchDiscoverActionBar, Empty/Error/Loading, match dialog |
| Acceptance | Like/pass/match handlers unchanged; empty/error/loading styled; no overflow on small phones; **not** release-ready until ranking/filter work |
| Dependencies | Shell + cosmic buttons / glass card |
| Risk | Medium — card layout regression |
| Status | Visual migration implemented in P2C-1C-2; device checklist F2 pending verification |

---

## 4. Messages

| item | detail |
|------|--------|
| Files | `messages_screen.dart`, optionally `chat_detail_screen.dart` chrome only |
| Runtime | `ChatService.getMyThreadsStream` |
| Visual | Title + list rows as glass tiles; shared empty/error |
| Functional | Do not change stream queries / thread id rules |
| Acceptance | Open chat still works; empty/error l10n preserved |
| Risk | Low–medium |

---

## 5. Profile

| item | detail |
|------|--------|
| Files | `profile_screen.dart`, possibly avatar widget; **data fix may touch** `NameSelectionScreen` / `ProfileSetupScreen` / `AuthService` name writes |
| Runtime | `ProfileService.getProfile` |
| Visual | Avatar, section blocks, softer cosmic header (optional CosmicProfileHero later) |
| **Functional / data_binding (must fix, not hide in paint)** | Empty `name` → UI shows `, {age}`. Root: Firestore `name` empty; phone bootstrap stores null displayName; NameSelection updates Auth only; wrapper may skip NameSelection. **Classify: data_binding + functional.** |
| **P2C-1C-4A status** | Canonical display-name gate + shared resolver shipped; Profile no longer emits `, 26`. |
| **P2C-1C-4B status** | Modern Profile presentation migrated (`qmatch_profile_presentation.dart`); Settings + photo edit preserved; legacy archetype chip omitted (not CM v2). Profile Edit still **G-046**. Live iOS visual sign-off still required. |
| Acceptance | Display `name` via resolver without leading comma; photo edit works; Settings reachable; no raw IQ/EQ/Frequency or legacy compat scores |
| Dependencies | Shell; optional ProfileService write path |
| Risk | **Medium** for visual-only; data contract unchanged |

---

## 6. Settings + Profile Photos + shared cosmic (P2C-1C-5)

| item | detail |
|------|--------|
| Files | `settings_screen.dart`, `profile_photo_edit_screen.dart`, `qmatch_cosmic_background.dart` |
| Audits | `qmatch_settings_screen_audit_v1.md`, `qmatch_profile_photo_screen_audit_v1.md` |
| Runtime | Settings routes/actions preserved; photo max=9; Storage/Firestore paths unchanged |
| Visual | Grouped glass Settings; honest empty/partial/full photo grids; shared restrained cosmic backdrop on Profile / Settings / Photo Management |
| Functional | Do not break deletion request / logout / debug entry / upload-delete-reorder |
| **P2C-1C-5 status** | Code-complete; goldens + contact sheets under `test/goldens/settings|profile_photos|cosmic_background/` |
| Acceptance open | Live iOS visual sign-off for Settings, Photo Management, and Profile+cosmic (G-050 extended); Notifications/Privacy persistence + FCM still gaps |
| Risk | Low for visual-only; medium for live permission/upload QA |

---

## 7. Cross-screen states

Unify Empty / Error / Loading widgets; replace ad-hoc columns. Apply to Discover, Messages, Profile null/load.

---

## 8. Device verification

See `qmatch_visual_regression_checklist_v1.md`.

---

## Out of scope (placeholders)

| screen family | note |
|---------------|------|
| Partner preference / values / hard constraints | Design with runtime contracts later |
| CM v2 compatibility + structured explanation | Offline engines only today |
| Final Discover ranking card copy | Depends on scoring product decision |
