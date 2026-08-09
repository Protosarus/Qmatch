# QMatch Assessment Capture Protection v1

## Scope

Active canonical question screens only (IQ / EQ / Frequency).

Central coordinator: `AssessmentCaptureProtection` (reference-counted) +
`AssessmentCaptureGuard` (PopScope + privacy overlay).

## Android

While any protected question screen holds a ref:

- `WindowManager.LayoutParams.FLAG_SECURE` via local `flutter_windowmanager`
- Screenshots blocked (secure-window semantics)
- Ordinary screen recording / capture blanked where FLAG_SECURE applies
- Recent-app / task preview protected by secure-window behavior

Protection clears when the last protected screen releases its ref.

## iOS

**Screenshot blocking is not guaranteed** by any public platform API used here.

Implemented:

| Capability | Status |
|------------|--------|
| Screenshot blocking | Not claimed / not guaranteed |
| Screenshot detection | `UIApplication.userDidTakeScreenshotNotification` → local UI obscure flash only |
| Screen recording / capture detection | `UIScreen.isCaptured` + `capturedDidChangeNotification` |
| Capture obscuring | Full-screen privacy overlay while captured |
| App-switcher privacy | Overlay while app inactive/paused/hidden under an active protection ref |

## Explicit non-coupling

Capture / screenshot signals must **not** affect:

- IQ / EQ / Frequency scores
- 20D profile
- Persona / RVI / Matching / account status

No sensitive logging of screenshots, pixels, answers, or UID-linked capture telemetry in this phase.

## Manual QA

### Navigation (all modules)

1. Answer 3+ questions; confirm no top-bar back.
2. Attempt Android system back / iOS swipe — route must not pop.
3. Kill app; relaunch — resume at correct index; prior answers immutable.

### Android capture

1. On IQ, EQ, Frequency: attempt screenshot / screen record — expect secure blank.
2. Leave assessment flow — non-assessment screens should not remain FLAG_SECURE.

### iOS capture

1. Start screen recording on a question screen — content obscured; stop — restored.
2. Background app — app-switcher should not show clear question content.
3. Take a screenshot — document that OS may still capture; app may flash overlay (detection, not blocking).
