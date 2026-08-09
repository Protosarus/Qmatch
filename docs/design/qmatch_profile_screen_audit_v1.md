# QMatch Profile screen audit v1 (P2C-1C-4B)

**Branch:** `main` @ `4bbd6cb`  
**Scope:** runtime Profile presentation chain before visual migration.  
**Data contract:** display-name remains P2C-1C-4A (`users/{uid}.name` via `UserIdentityResolver`).

## Runtime path

```text
MainNavigationScreen (Profile tab)
  → ProfileScreen
    → ProfileService.getProfile()
      → Firestore users/{uid} (owner get)
        → UserProfileModel.fromFirestore
          → widgets (identity / photo / about / interests / archetype chip)
```

| Concern | Evidence |
|---------|----------|
| Entry | `main_navigation_screen.dart` → `ProfileScreen()` |
| State | Local `StatefulWidget` (`_profile`, `_isLoading`) |
| Read | `ProfileService.getProfile` → `users/{uid}` |
| Writes on this screen | None (photo edit navigates to `ProfilePhotoEditScreen`) |
| Settings | `Navigator` → `SettingsScreen` |
| Photo edit | Tap avatar → `ProfilePhotoEditScreen` then reload |

## Visible field inventory

| UI element (pre-4B) | Source field | Document | Real runtime? | Legacy? | Safe to display? | Decision |
|---------------------|--------------|----------|---------------|---------|------------------|----------|
| Identity header | `name` + `age` | `users/{uid}` | Yes | `name` is canonical display name | Yes via resolver | **Retain** (resolver; never `, 26`) |
| Avatar photo | `profile_photo_url` | `users/{uid}` | Yes | — | Yes (public photo) | **Retain**; tap → photo edit |
| Camera badge | UI only | — | Action exists | — | Yes | **Retain** as photo-manage affordance |
| Archetype chip | `archetype` / mapped via `AssessmentResultDisplayResolver` | `users/{uid}` | Yes when set | **Legacy IQ/EQ grid label** — not CM v2 persona | Misleading as “science persona” | **Omit** in 4B; gap for CM v2 persona |
| About | `bio` | `users/{uid}` | Yes | — | Yes | **Retain**; empty → localized empty/omit |
| Interests | `interests[]` | `users/{uid}` | Yes | Stored legacy TR option keys | Yes via `ProfileOptionLabels` | **Retain** as compact chips |
| Settings icon | nav | — | Yes | — | Yes | **Retain** in compact header |
| Category codes `HH`… | `category` | `users/{uid}` | Stored | Legacy grid | **No** (raw codes) | **Omit** (never shown) |
| GeoPoint | `location` | `users/{uid}` | Yes | — | **Private coordinates** | **Omit** from UI |
| Location text | `location_text` | `users/{uid}` | Yes when set | — | Public-ish label | **Retain** when non-empty |
| Gender / education / looking_for / lifestyle | model fields | `users/{uid}` | Yes when set | TR stored values | Yes via labels | **Retain** as compact info rows when present |
| Occupation | `occupation` | `users/{uid}` | Optional | — | Yes | **Retain** when present |
| IQ/EQ/Frequency scores | not on this screen | — | — | — | **No** | Keep omitted |
| Compatibility % | not on this screen | — | — | — | **No** | Keep omitted |
| Completion % | none | — | Fake if invented | — | **No** | Do not invent |
| Email / phone / UID | Auth / `uid` | — | — | — | **No** as identity | Never |

## Actions inventory

| Action | Exists? | Destination | 4B decision |
|--------|---------|-------------|-------------|
| Settings | Yes | `SettingsScreen` | Keep |
| Manage photos | Yes | `ProfilePhotoEditScreen` | Keep (avatar tap) |
| Edit profile (name/bio/etc.) | **No** wired screen | — | **G-046** — do not fake |
| Logout / delete account | Settings only | Settings | Do not move to Profile primary |

## Loading / empty / error (pre-4B)

| State | Behavior | Gap |
|-------|----------|-----|
| Loading | Full-screen spinner | Replace with layout skeleton |
| Null profile | `profileNotFound` text | Distinguish missing vs load failure |
| Partial fields | Bio fallback string; interests section omitted if empty | Keep honest omit/empty copy |
| Archetype unknown | Resolver unknown fallback | Omitting chip avoids unknown title noise |

## Assessment / persona honesty

- Stored `archetype` / `category` are **legacy** mirrors, not Core Method v2 persona prototypes.
- Displaying them as a modern “persona” would misrepresent CM v2.
- **4B decision:** omit archetype/category from Profile UI; track future CM v2 persona surface as a gap after production wiring.

## Non-goals (confirmed)

- No display-name contract changes
- No Firestore schema / query path changes for Profile read
- No Profile Edit invention
- No Settings redesign
- No Discover / Messages / Core Method changes
