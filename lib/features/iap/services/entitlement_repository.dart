import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_paths.dart';
import '../domain/entitlement_snapshot.dart';

/// Read-only owner entitlement snapshot. Never writes grants locally.
class EntitlementRepository {
  EntitlementRepository({
    DocumentReference<Map<String, dynamic>> Function(String uid)? entitlementDoc,
    Future<EntitlementSnapshot> Function(String uid)? fetchOverride,
    Stream<EntitlementSnapshot> Function(String uid)? watchOverride,
  })  : _entitlementDoc = entitlementDoc,
        _fetchOverride = fetchOverride,
        _watchOverride = watchOverride;

  final DocumentReference<Map<String, dynamic>> Function(String uid)?
      _entitlementDoc;
  final Future<EntitlementSnapshot> Function(String uid)? _fetchOverride;
  final Stream<EntitlementSnapshot> Function(String uid)? _watchOverride;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    final override = _entitlementDoc;
    if (override != null) return override(uid);
    return FirestorePaths.entitlementDoc(uid);
  }

  /// One-shot read. Missing doc → free / no access (fail closed).
  Future<EntitlementSnapshot> fetch(String uid) async {
    final custom = _fetchOverride;
    if (custom != null) return custom(uid);
    if (uid.isEmpty) {
      return EntitlementSnapshot.free;
    }
    final snap = await _doc(uid).get();
    return EntitlementSnapshot.fromMap(
      uid,
      snap.data(),
    );
  }

  /// Live entitlement updates from trusted Firestore writes only.
  Stream<EntitlementSnapshot> watch(String uid) {
    final custom = _watchOverride;
    if (custom != null) return custom(uid);
    if (uid.isEmpty) {
      return Stream.value(EntitlementSnapshot.free);
    }
    return _doc(uid).snapshots().map(
          (snap) => EntitlementSnapshot.fromMap(uid, snap.data()),
        );
  }
}
