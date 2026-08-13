/// Owner-scoped entitlement snapshot from Firestore `entitlements/{uid}`.
///
/// Access / balances are trusted backend writes only. Clients must never
/// invent `resonance_access` from StoreKit success.
class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.uid,
    required this.tier,
    required this.subscriptionState,
    required this.resonanceAccess,
    required this.superResonanceBalance,
    required this.boostBalance,
    this.platform,
    this.canonicalProductKey,
    this.productId,
    this.schemaVersion,
  });

  final String uid;
  final String tier;
  final String subscriptionState;

  /// Authoritative premium gate from trusted backend / Firestore.
  final bool resonanceAccess;

  final int superResonanceBalance;
  final int boostBalance;
  final String? platform;
  final String? canonicalProductKey;
  final String? productId;
  final String? schemaVersion;

  static const free = EntitlementSnapshot(
    uid: '',
    tier: 'free',
    subscriptionState: 'none',
    resonanceAccess: false,
    superResonanceBalance: 0,
    boostBalance: 0,
  );

  /// Parse Firestore map. Missing / invalid access fields fail closed to false.
  factory EntitlementSnapshot.fromMap(String uid, Map<String, dynamic>? data) {
    if (data == null) {
      return EntitlementSnapshot(
        uid: uid,
        tier: 'free',
        subscriptionState: 'none',
        resonanceAccess: false,
        superResonanceBalance: 0,
        boostBalance: 0,
      );
    }

    return EntitlementSnapshot(
      uid: uid,
      tier: (data['tier'] as String?) ?? 'free',
      subscriptionState: (data['subscription_state'] as String?) ?? 'none',
      resonanceAccess: data['resonance_access'] == true,
      superResonanceBalance: _nonNegativeInt(data['super_resonance_balance']),
      boostBalance: _nonNegativeInt(data['boost_balance']),
      platform: data['platform'] as String?,
      canonicalProductKey: data['canonical_product_key'] as String?,
      productId: data['product_id'] as String?,
      schemaVersion: data['schema_version'] as String?,
    );
  }

  static int _nonNegativeInt(Object? value) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) {
      final i = value.toInt();
      return i < 0 ? 0 : i;
    }
    return 0;
  }
}
