# Chat detail goldens (P2C-1C-3B / P2C-1C-3B-1)

Synthetic presentation-only scenes. No Firebase.

Wallpaper: repository-owned `assets/images/chat/qmatch_chat_pattern.webp`
(source PNG retained for traceability).

Fonts: offline stand-ins under `test/fonts/google_fonts/` (Roboto renamed).

## Individual goldens

| File | Scenario |
|------|----------|
| `empty_compact_1_0.png` | Empty conversation + wallpaper + empty card + composer |
| `loading_compact_1_0.png` | Loading messages over wallpaper |
| `error_compact_1_0.png` | Recoverable load error card + retry |
| `incoming_compact_1_0.png` | Single incoming bubble + timestamp |
| `outgoing_compact_1_0.png` | Single outgoing bubble + timestamp |
| `mixed_compact_1_0.png` | Mixed in/out + date separators |
| `mixed_large_1_0.png` | Mixed on large iPhone viewport |
| `mixed_compact_text_1_3.png` | Mixed at text scale ~1.3 |
| `long_message_compact_1_0.png` | Long wrapping outgoing message |
| `emoji_multiline_compact_1_0.png` | Multiline incoming (emoji glyphs may be test-font limited) |
| `missing_counterpart_compact_1_0.png` | Fallback title “Conversation” + placeholder avatar |
| `composer_keyboard_compact_1_0.png` | Typed composer text + keyboard-sized viewInsets |

## Contact sheet (human review)

`chat_detail_visual_review_contact_sheet.png`

Reading order: left → right, top → bottom (4×3):

1. empty  
2. incoming  
3. outgoing  
4. mixed conversation  
5. long message  
6. emoji / multiline  
7. missing counterpart  
8. composer typed text *(same source as keyboard panel)*  
9. keyboard-sized layout  
10. text scale 1.3  
11. loading  
12. error  

Thumbs used to assemble the sheet live under `_thumbs/` (test-only).

```bash
flutter test --update-goldens test/chat_detail_golden_test.dart
flutter test test/chat_detail_golden_test.dart
flutter test test/chat_detail_contact_sheet_test.dart
```
