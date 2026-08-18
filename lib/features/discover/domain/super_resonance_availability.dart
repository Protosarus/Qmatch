/// Trusted Super Resonance availability from backend server time.
///
/// [purchasedBalance] is `entitlements/{uid}.super_resonance_balance` only.
/// Daily remaining is never inferred from StoreKit or the device clock.
class SuperResonanceAvailability {
  const SuperResonanceAvailability({
    required this.dailyRemaining,
    required this.dailyLimit,
    required this.purchasedBalance,
    required this.totalAvailable,
  });

  final int dailyRemaining;
  final int dailyLimit;
  final int purchasedBalance;
  final int totalAvailable;

  static const empty = SuperResonanceAvailability(
    dailyRemaining: 0,
    dailyLimit: 0,
    purchasedBalance: 0,
    totalAvailable: 0,
  );

  bool get hasDailyAllowance => dailyLimit > 0;

  static SuperResonanceAvailability? fromPublicMap(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final purchased = _nonNegativeInt(
      data['purchased_balance'] ?? data['super_resonance_balance'],
    );
    final dailyRemaining = _nonNegativeInt(data['daily_remaining']);
    final dailyLimit = _nonNegativeInt(data['daily_limit']);
    final total = data.containsKey('total_available')
        ? _nonNegativeInt(data['total_available'])
        : dailyRemaining + purchased;
    return SuperResonanceAvailability(
      dailyRemaining: dailyRemaining,
      dailyLimit: dailyLimit,
      purchasedBalance: purchased,
      totalAvailable: total,
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
