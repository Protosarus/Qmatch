import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/firestore_paths.dart';

/// Result of submitting an in-app account deletion **request** (not a wipe).
class AccountDeletionRequestResult {
  const AccountDeletionRequestResult({
    required this.ok,
    this.errorMessage,
    this.alreadyRequested = false,
  });

  final bool ok;
  final String? errorMessage;
  final bool alreadyRequested;
}

/// Creates/updates `account_deletion_requests/{uid}` for the signed-in user only.
///
/// Does **not** delete Auth users, Storage files, messages, matches, or profile data.
class AccountDeletionRequestService {
  AccountDeletionRequestService({
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static const String confirmationToken = 'DELETE';

  Future<AccountDeletionRequestResult> submitRequest({
    required String localeLanguageCode,
    String? appVersion,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AccountDeletionRequestResult(
        ok: false,
        errorMessage: 'not_signed_in',
      );
    }

    final uid = user.uid;
    final requestRef = FirestorePaths.accountDeletionRequestDoc(uid);
    final userRef = FirestorePaths.userDoc(uid);

    try {
      final existing = await requestRef.get();
      final already =
          existing.exists && (existing.data()?['status'] as String?) == 'requested';

      final payload = <String, dynamic>{
        'uid': uid,
        'email_or_phone_masked': _maskContact(user),
        'status': 'requested',
        'requested_at': FieldValue.serverTimestamp(),
        'source': 'in_app',
        if (appVersion != null && appVersion.isNotEmpty) 'app_version': appVersion,
        'platform': _platformLabel(),
        'locale': localeLanguageCode,
        'user_acknowledged_irreversible': true,
        'user_acknowledged_timeline': true,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await requestRef.set(payload, SetOptions(merge: true));

      // Soft marker on own user doc only — no data wipe.
      await userRef.set(
        {
          'account_deletion_requested': true,
          'account_deletion_requested_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return AccountDeletionRequestResult(
        ok: true,
        alreadyRequested: already,
      );
    } on FirebaseException catch (e) {
      debugPrint('AccountDeletionRequestService failed: ${e.code} ${e.message}');
      return AccountDeletionRequestResult(
        ok: false,
        errorMessage: e.code,
      );
    } catch (e) {
      debugPrint('AccountDeletionRequestService failed: $e');
      return const AccountDeletionRequestResult(
        ok: false,
        errorMessage: 'unknown',
      );
    }
  }

  Future<bool> hasPendingRequest() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final snap =
          await FirestorePaths.accountDeletionRequestDoc(user.uid).get();
      if (!snap.exists) return false;
      return (snap.data()?['status'] as String?) == 'requested';
    } catch (_) {
      return false;
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return defaultTargetPlatform.name;
    }
  }

  static String _maskContact(User user) {
    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      final parts = email.split('@');
      final local = parts.first;
      final domain = parts.last;
      final maskedLocal = local.length <= 2
          ? '*' * local.length
          : '${local.substring(0, 1)}***${local.substring(local.length - 1)}';
      return '$maskedLocal@$domain';
    }
    final phone = user.phoneNumber?.trim();
    if (phone != null && phone.length >= 4) {
      return '***${phone.substring(phone.length - 4)}';
    }
    return 'unavailable';
  }
}
