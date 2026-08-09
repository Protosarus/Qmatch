import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/identity/identity.dart';

/// Abstraction for display-name persistence (testable without Firebase).
abstract class DisplayNameStore {
  Future<String?> readCanonicalDisplayName(String uid);
  Future<bool> hasValidCanonicalDisplayName(String uid);
  Future<String> prefillCandidate(String uid);
  Future<void> saveCanonicalDisplayName({
    required String uid,
    required String rawInput,
  });
}

/// Owner-controlled persistence for the canonical display name (`users.name`).
class DisplayNameService implements DisplayNameStore {
  DisplayNameService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<String?> readCanonicalDisplayName(String uid) async {
    final snap = await _userRef(uid).get();
    final resolved = UserIdentityResolver.fromUserMap(snap.data());
    return resolved.displayName;
  }

  @override
  Future<bool> hasValidCanonicalDisplayName(String uid) async {
    final snap = await _userRef(uid).get();
    final raw = snap.data()?[DisplayNameContract.firestoreField];
    final rawName = raw is String ? raw : (raw?.toString() ?? '');
    // Gate uses write-path validation (2–24 graphemes), not display coercion.
    return DisplayNameValidator.validate(rawName).isValid;
  }

  @override
  Future<String> prefillCandidate(String uid) async {
    final canonical = await readCanonicalDisplayName(uid);
    if (canonical != null) return canonical;

    final authName = _auth.currentUser?.displayName;
    if (authName == null || authName.trim().isEmpty) return '';
    final validated = DisplayNameValidator.validate(authName);
    if (validated.isValid) return validated.normalized!;
    return DisplayNameValidator.normalize(authName);
  }

  @override
  Future<void> saveCanonicalDisplayName({
    required String uid,
    required String rawInput,
  }) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) {
      throw StateError('Not authenticated as owner');
    }

    final validated = DisplayNameValidator.validate(rawInput);
    if (!validated.isValid) {
      throw ArgumentError('Invalid display name: ${validated.error}');
    }

    await _userRef(uid).set(
      {
        DisplayNameContract.firestoreField: validated.normalized,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
