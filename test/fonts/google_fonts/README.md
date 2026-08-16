# Golden-test font stand-ins (Roboto copies renamed for google_fonts offline lookup)

Registered in `pubspec.yaml` assets solely so widget goldens resolve offline
(`GoogleFonts.config.allowRuntimeFetching = false`).

Production UI still uses the `google_fonts` package (runtime fetch / real families).
See gap G-043 — ideally move off the release asset bundle later.

## Required filenames (golden-tested live UI)

google_fonts looks up assets by API filename prefix. These must exist:

| File | Used for |
|------|----------|
| `Inter-Regular.ttf` | Inter w400 |
| `Inter-Medium.ttf` | Inter w500 |
| `Inter-SemiBold.ttf` | Inter w600 |
| `Inter-Bold.ttf` | Inter w700 |
| `Inter-Italic.ttf` | Inter w400 italic (Discover candidate hint) |
| `PlayfairDisplay-Regular.ttf` | Playfair w400 |
| `PlayfairDisplay-SemiBold.ttf` | Playfair w600 (headers) |
| `PlayfairDisplay-Bold.ttf` | Playfair w700 |
| `PlayfairDisplay-MediumItalic.ttf` | Playfair w500 italic (Profile title) |

Do not remove a file from this list without checking golden-tested UI call sites.
