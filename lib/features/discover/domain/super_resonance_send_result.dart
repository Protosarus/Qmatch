/// Public `sendSuperResonance` payload. Extra fields are dropped.
class SuperResonanceSendResult {
  const SuperResonanceSendResult({
    required this.ok,
    required this.alreadySent,
    required this.superResonanceBalance,
    required this.signalId,
    this.dailyRemaining = 0,
    this.purchasedBalance = 0,
    this.totalAvailable = 0,
  });

  final bool ok;
  final bool alreadySent;

  /// Purchased consumable remaining (`super_resonance_balance`).
  final int superResonanceBalance;
  final String signalId;
  final int dailyRemaining;
  final int purchasedBalance;
  final int totalAvailable;

  static SuperResonanceSendResult? fromPublicMap(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    if (data['ok'] != true) return null;
    final purchased = _nonNegativeInt(
      data['purchased_balance'] ?? data['super_resonance_balance'],
    );
    final dailyRemaining = _nonNegativeInt(data['daily_remaining']);
    final total = data.containsKey('total_available')
        ? _nonNegativeInt(data['total_available'])
        : dailyRemaining + purchased;
    final signalId = data['signal_id'];
    if (signalId is! String || signalId.isEmpty) return null;
    return SuperResonanceSendResult(
      ok: true,
      alreadySent: data['already_sent'] == true,
      superResonanceBalance: purchased,
      signalId: signalId,
      dailyRemaining: dailyRemaining,
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
