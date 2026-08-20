import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stable Firestore document id for an FCM token. Matches the backend SHA-256.
String fcmTokenDocId(String token) {
  return sha256.convert(utf8.encode(token)).toString();
}
