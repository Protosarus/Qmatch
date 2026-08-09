# QMatch display-name contract v1 (P2C-1C-4A)

## Domain property

**`displayName`** — public visible nickname / preferred address name.

- Not a legal-name requirement
- Not a globally unique `@username`
- Duplicates across users are allowed
- Editable later via Profile Edit (when that screen exists)
- Must never be replaced by UID, email, phone, or document ID in UI

## Canonical Firestore field

**Key:** `name` on `users/{uid}`

Rationale: the repository already serializes identity as snake-compatible single-token `name` (alongside `age`, `bio`, `looking_for`, …). Introducing `display_name` would create competing writes. Canonical writes use **only** `name`.

```text
users/{uid}.name : string  // trimmed, validated display name
```

Domain Dart property name: `displayName` (resolvers / validators).  
Persistence / models may continue exposing a Dart `name` field that maps 1:1 to Firestore `name`.

## Source of truth

| Layer | Role |
|-------|------|
| Firestore `users/{uid}.name` | **Canonical** public identity |
| Firebase Auth `displayName` | Optional prefill / legacy only — **not** a competing public source |
| Presentation resolvers | Read Firestore maps via shared resolver |

Auth mirroring on save is **not** required. If present historically, Firestore remains authoritative after reload.

## Validation (shared)

See `DisplayNameValidator`:

- Trim; collapse internal whitespace; single line
- 2–24 user-perceived graphemes
- At least one letter or number (Unicode-aware)
- Reject control / newline / tab
- Reject email-only, phone-only, URL-only shapes
- Preserve user capitalization; allow apostrophe, hyphen, accents, non-Latin scripts

## Read order

1. Canonical Firestore `name` (if safe for public display after normalize)
2. Documented legacy: same `name` field with empty/contact-like/control-only → treat as missing (no other public aliases today)
3. Completion-screen prefill may use Auth `displayName` when Firestore is missing
4. Otherwise missing — localized generic label for **other** users; current user gated to completion

### Read vs write length policy

- **Write** (`DisplayNameValidator.validate`): enforce 2–24 graphemes.
- **Read** (`UserIdentityResolver.coerceForDisplay`): show normalized safe public names even if outside write bounds (e.g. oversized legacy peers); UI may ellipsize. Contact-like values remain rejected.

## Formatting

`UserIdentityResolver.formatNameAndAge` / `formatFromUserMap`:

- safe name + valid age → `"Name, age"`
- safe name only → `"Name"`
- missing name → `null` (never `", 26"`; never age-only as the identity header)

## Runtime gate

After authentication, before assessments / profile setup / main shell:

- Valid canonical `name` → continue existing progress routing
- Missing/invalid → `DisplayNameCompletionScreen`
- No redirect loops; logout still returns to Welcome

## Gaps

- Profanity / moderation: not in this phase (track in gap register)
- Legacy Auth-only names: user confirms into Firestore on completion
- Profile Edit UI: deferred
- Bulk production migration scripts: out of scope
