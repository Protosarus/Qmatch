# QMatch Profile Photo Management audit v1 (P2C-1C-5)

**Branch:** `main` @ `4bbd6cb`  
**Screen:** `ProfilePhotoEditScreen` (“Fotoğraflarım” / `myPhotos`)

## Runtime path

```text
ProfileScreen (photo tap)
  → ProfilePhotoEditScreen(profile)
    → PhotoUploadService.pickMultipleImages / deletePhoto
    → ProfileService.saveProfile (photos + profile_photo_url)
```

| Concern | Evidence |
|---------|----------|
| List source | `widget.profile.photos` copied into local `_photos` |
| Primary photo | Index `0` → `profile_photo_url` on save |
| Max count | **9** (`_photos.length >= 9`, grid `itemCount: 9`) |
| Picker | `ImagePicker.pickMultipleMedia` (quality 80) |
| Storage path | `profile_photos/{uid}/profile_{uid}_{ts}_{i}.jpg` |
| Firestore | Merge via existing `ProfileService.saveProfile` |
| Reorder | Long-press → “set as main” moves index to 0 |
| Delete | Long-press → Storage delete (best-effort) + list save |
| Empty slots | **Pre-migration:** visual-only 9 cells. **P2C-1C-5:** honest empty / photos+Add / nine-only |
| Cancel picker | Empty list → no upload; not treated as error |
| Errors | UI uses localized `profilePhotosUploadFailed` / `profilePhotosDeleteFailed` (no raw Firebase text) |

## Visual migration rules (this phase)

- Do **not** change max count, Storage path, Firestore fields, or upload semantics.
- Zero photos → honest empty state + one Add action (not nine empties).
- 1–8 → real tiles + one Add tile.
- 9 → nine tiles, no Add.
- Keep long-press options (set main / delete).
- Preserve primary star marker (index 0 is real primary).

## P2C-1C-5 post-migration notes

- Shared cosmic background applied; max remains `kProfilePhotoMaxCount = 9`.
- Goldens / contact sheet: `test/goldens/profile_photos/` — presentation only.
- Open: live iOS permission + upload/delete QA; photo moderation still absent (identity/safety gaps).

## P2C-1C-5B polish notes

- Header migrated to shared `QMatchPushedScreenHeader`.
- Add-photo CTA migrated to shared `QMatchPrimaryAction`; upload callback and save path unchanged.
- Test-only hooks exist for deterministic verification only: `debugPickPhotos`, `debugSaveProfile`, `animateBackground`.
- Live 8-second simulator observation is still required to sign off the breathing effect.
