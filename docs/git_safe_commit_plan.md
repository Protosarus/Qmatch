# Git Safe Commit Plan (Phase 3Q-A1)

**Date:** 2026-07-18
**Mode:** Inspection + plan only — **no commit, no push, no `git add .`, no `git clean`, no deletes**
**Branch:** `main` @ `04da802` (`style: polish auth entry screens`)
**Remote:** **none configured** (`git remote -v` empty)

---

## 1. Git state summary

| Item | Value |
|------|------:|
| Tracked files in repo | **3** |
| Tracked modified (`M`) | **3** |
| Untracked path groups (`??` status lines) | **~48** |
| Untracked files (expanded) | **~279** |
| Diff (tracked only) | 3 files, +343 / −156 |

### Tracked modified files

```
 M lib/features/auth/screens/login_screen.dart
 M lib/features/auth/screens/phone_signup_screen.dart
 M lib/features/auth/screens/welcome_screen.dart
```

### Important structural note

This is effectively a **near-empty Git history** with almost the entire Flutter app still **untracked**. The first real project commit will be large. Staging must be **explicit path adds**, never `git add .` / `git add -A`.

`.gitignore` exists on disk and **is already applied** for some paths (`build/`, `.dart_tool/`, `.flutter-plugins-dependencies`), but `.gitignore` itself is still **untracked** and is missing several important exclude rules (see §4).

---

## 2. Files that must NOT be committed

### Secrets / credentials / env

| Path | Reason |
|------|--------|
| `lib/.env` | Env file (currently empty 0 bytes, still must never be committed) |
| Any future `.env` / `*.env` | Secrets risk |

### Logs / device artifacts

| Path | Reason |
|------|--------|
| `app_logs.txt` | Contains device names / UDIDs / simulator IDs |
| `*.log` | Logs (partially covered by current `*.log`) |

### Personal / junk / local notes

| Path | Reason |
|------|--------|
| `Adsız.txt` | Local/personal text |
| `tüm konuşma Qmatch.txt` | Large personal conversation dump (~532 KB) |
| `devir teslim 6 ocak.pages` | Personal Apple Pages handoff doc |
| `email_signup_screen.dart.txt` | Dump/scratch copy of a screen |
| `ios/Runner/Info.plistyq` | Typo/junk sibling of `Info.plist` |
| `PROJECT_STATUS_REPORT.md` | Review before commit; may be internal/status only (optional exclude) |

### Generated / local tooling caches

| Path | Reason |
|------|--------|
| `build/` | Already ignored |
| `.dart_tool/` | Already ignored |
| `.flutter-plugins-dependencies` | Already ignored |
| `scripts/__pycache__/` | Python bytecode — must exclude |

### Firebase client config — review before push (not auto-exclude)

These are **normal in many Flutter apps** but contain **client API keys** and project IDs. They are restricted by app ID / bundle ID, yet should be reviewed before a **public** remote:

| Path | Note |
|------|------|
| `lib/firebase_options.dart` | Contains `apiKey` values |
| `android/app/google-services.json` | Firebase Android client config |
| `ios/GoogleService-Info.plist` | Firebase iOS client config |
| `ios/Runner/GoogleService-Info.plist` | Duplicate/copy — review which is needed |

**Recommendation:** OK to commit for a **private** GitHub repo if the team already treats Firebase client configs as shareable. For a **public** repo, prefer keeping them out or confirming Firebase App Check / API key restrictions first.

---

## 3. Files that SHOULD be committed (grouped)

### A. Auth phone fix + localization (tracked mods + related untracked)

**Tracked (intended, safe):**

- `lib/features/auth/screens/login_screen.dart` — AppLocalizations wiring
- `lib/features/auth/screens/welcome_screen.dart` — AppLocalizations wiring
- `lib/features/auth/screens/phone_signup_screen.dart` — intl_phone_field + E.164 hardening + l10n

**Untracked auth screens (intended product code):**

- `lib/features/auth/screens/email_signup_screen.dart`
- `lib/features/auth/screens/email_verification_screen.dart`
- `lib/features/auth/screens/signup_screen.dart`
- `lib/features/auth/screens/social_login_screen.dart`
- `lib/features/auth/screens/verification_screen.dart`

### B. Localization

- `l10n.yaml`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_tr.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_tr.dart`
  (This project treats generated l10n Dart as source — currently untracked; **include** so CI/checkouts match.)

### C. App UI / core (product)

- `lib/main.dart` (locale fallback)
- `lib/core/` (navigation, theme, widgets, compatibility scoring, auth service, etc.)
- `lib/features/profile/`
- `lib/features/discover/`
- `lib/features/messages/`
- `lib/features/settings/`
- `lib/features/main/`
- `lib/features/assessment/` (runtime assessment UI/services — not JSON scoring changes for commit *content*, but code belongs in repo)
- `lib/features/matching/`, `lib/features/reveal/`, `lib/features/safety/`, `lib/features/debug/` (debug is code; keep `kDebugMode` gated)

### D. Assessment content assets

- `assets/data/assessment_sets/iq_sets.json`
- `assets/data/assessment_sets/eq_sets.json`
- `assets/data/assessment_sets/frequency_sets.json`
- Other intentional assets under `assets/` (images, legacy question JSON if still used)

### E. Docs / reports

- `docs/assessment_*.md`
- `docs/full_app_localization_*.md`
- `docs/git_safe_commit_plan.md` (this file)

### F. Scripts (tooling; exclude `__pycache__`)

Safe intentional tooling examples:

- `scripts/validate_assessment_sets.py`
- `scripts/audit_assessment_content_quality.py`
- `scripts/audit_flutter_localization.py`
- `scripts/audit_assessment_firestore_sync.py`
- `scripts/export_assessment_sets_v2.py`
- `scripts/apply_*.py` + batch JSON helpers
- `scripts/generate_*.py`
- `scripts/README.md`

### G. Flutter / platform scaffolding

- `.gitignore` (**first**, after strengthening — see §4)
- `.gitattributes`, `.metadata`, `analysis_options.yaml`
- `README.md`
- `pubspec.yaml`, `pubspec.lock`
- `firebase.json`
- `android/`, `ios/`, `macos/`, `linux/`, `web/`, `windows/` (exclude junk like `Info.plistyq`)

### H. Optional / decide consciously

- `.github/copilot-instructions.md` — team preference
- `PROJECT_STATUS_REPORT.md` — exclude unless you want it public in-repo

---

## 4. Risky tracked changes (detail)

### `login_screen.dart`

| Question | Answer |
|----------|--------|
| Why changed | Wire UI/errors to `AppLocalizations` |
| Intended? | Yes (3P-A2/A3 localization) |
| Safe to commit? | **Yes** |
| Secrets/phone numbers? | **No** (no real numbers in diff) |

### `welcome_screen.dart`

| Question | Answer |
|----------|--------|
| Why changed | Wire welcome chrome to `AppLocalizations` |
| Intended? | Yes |
| Safe to commit? | **Yes** |
| Secrets? | **No** |

### `phone_signup_screen.dart`

| Question | Answer |
|----------|--------|
| Why changed | Phone auth UX/E.164 via `intl_phone_field`; localization; default dial `+90` / ISO `TR` as **defaults**, not a user’s number |
| Intended? | Yes (auth fix + l10n) |
| Safe to commit? | **Yes**, after quick human skim |
| Secrets / real phones? | Diff shows formatting helpers and `+90` country default only — **no personal phone numbers** spotted in inspection |

---

## 5. `.gitignore` gaps (propose — do **not** apply in this phase)

Current `.gitignore` covers Flutter build caches but **does not** protect:

- `.env` / `*.env` / `lib/.env`
- `app_logs.txt`
- personal docs (`*.pages`, conversation dumps)
- `scripts/__pycache__/`
- odd local dumps (`*.dart.txt`, `Info.plistyq`)

### Proposed additions (exact text to append later)

```gitignore
# Secrets / env
.env
*.env
lib/.env
**/.env

# Local logs / device captures
app_logs.txt
*.log

# Python caches
**/__pycache__/
*.py[cod]

# Personal / local junk (do not publish)
*.pages
Adsız.txt
tüm konuşma Qmatch.txt
devir teslim 6 ocak.pages
email_signup_screen.dart.txt
**/Info.plistyq

# Optional: keep local status notes out of git
# PROJECT_STATUS_REPORT.md
```

**This phase did not edit `.gitignore`.** Apply these before the first broad `git add` of the tree.

---

## 6. Proposed staging commands (DO NOT RUN YET)

Order matters: strengthen ignore → add ignore → add project paths explicitly.

```bash
# 0) After approving .gitignore additions, edit .gitignore, then:
git add .gitignore

# 1) Config / root
git add .gitattributes .metadata analysis_options.yaml README.md
git add pubspec.yaml pubspec.lock l10n.yaml firebase.json

# 2) Localization
git add lib/l10n/

# 3) App code
git add lib/main.dart lib/core/
git add lib/features/auth/
git add lib/features/profile/
git add lib/features/discover/
git add lib/features/messages/
git add lib/features/settings/
git add lib/features/main/
git add lib/features/assessment/
git add lib/features/matching/
git add lib/features/reveal/
git add lib/features/safety/
git add lib/features/debug/

# 4) Assets (assessment sets + images)
git add assets/

# 5) Docs + scripts
git add docs/
git add scripts/

# 6) Platforms (after .gitignore is solid)
git add android/ ios/ macos/ linux/ web/ windows/

# 7) Firebase client configs — ONLY if private repo / team-approved
# git add lib/firebase_options.dart
# git add android/app/google-services.json
# git add ios/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

# 8) Optional
# git add .github/
```

### Explicitly do **not** run

```bash
# NEVER for this cleanup
git add .
git add -A
git clean -fd
git restore --staged .
git push --force
```

### Verify before commit

```bash
git status --short
git diff --cached --stat
# Confirm lib/.env, app_logs.txt, *.pages, conversation txt, __pycache__ are absent
```

---

## 7. Proposed commit message

```text
feat: ship assessment sets, global l10n foundation, and phone auth hardening

Add bundled IQ/EQ/Frequency sets, en/tr ARB + AppLocalizations wiring across
core user chrome, profile option display maps, and safer phone E.164 signup.
```

(Adjust if you prefer splitting into multiple commits: (1) ignore+scaffold, (2) assessment assets, (3) l10n+UI, (4) auth phone.)

---

## 8. Proposed push command

No remote exists yet. After creating a private GitHub repo:

```bash
git remote add origin git@github.com:<ORG_OR_USER>/Qmatch.git
git push -u origin HEAD
```

Use HTTPS equivalent if preferred. Prefer a **private** repository until Firebase client config policy is decided.

---

## 9. Validation status (latest known — not re-run in 3Q-A1)

From Phase **3P-A3 stabilize** (same working tree; treat as **recent but not re-validated in this step**):

| Check | Latest known |
|-------|----------------|
| `flutter analyze` (auth/profile/settings/discover/main) | **No issues found** |
| `validate_assessment_sets.py` | **PASS** |
| `audit_assessment_content_quality.py` | **PASS WITH NOTES** |
| `audit_flutter_localization.py` | **P0=22, P1=4, P2=35** |

3Q-A1 did **not** re-run these commands.

---

## 10. Risks before push

1. **Near-empty history** → first commit is huge; review `git diff --cached --stat` carefully.
2. **`lib/.env` not ignored yet** → easy to leak if someone runs `git add .`.
3. **Personal files** still untracked and not ignored (`*.pages`, conversation txt, `Adsız.txt`).
4. **Firebase client keys** in `firebase_options.dart` / GoogleService files — OK for private repo with caveats; risky for public.
5. **`app_logs.txt`** has device identifiers — exclude.
6. **No remote** — push blocked until `origin` is added intentionally.
7. **Do not** use force-push; branch is `main`.

---

## 11. Confirmations (this phase)

| Action | Performed? |
|--------|------------|
| Commit | **No** |
| Push | **No** |
| `git add .` / `git add -A` | **No** |
| `git clean` / `git restore` / deletes | **No** |
| Firestore write | **No** |
| Assessment JSON edit | **No** |
| Localization file edit | **No** |
| App code edit | **No** |
| `.gitignore` edit | **No** (proposed only) |
| Report created | **Yes** — `docs/git_safe_commit_plan.md` |

---

## 12. Recommended next step (manual, after approval)

1. Approve and apply `.gitignore` additions.
2. Stage with the explicit `git add` list above.
3. `git status` / `git diff --cached` review.
4. Commit with the proposed message (or split commits).
5. Create **private** GitHub remote, then `git push -u origin HEAD`.
