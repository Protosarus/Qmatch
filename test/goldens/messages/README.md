# Messages inbox golden baselines (P2C-1C-3A)

Test-only visual fixtures for the Messages conversation list.

## Rules

- Synthetic fixtures only (`test/support/messages_golden_*.dart`)
- No Firebase reads/writes
- No production / debug routes
- Chat-detail screen covered separately in P2C-1C-3B (`test/goldens/chat_detail/`)

## Regenerate

```bash
flutter test --update-goldens test/messages_golden_test.dart
flutter test test/messages_golden_test.dart
```
