/// Public `sendSuperResonance` payload. Extra fields are dropped.
class SuperResonanceSendResult {
  const SuperResonanceSendResult({
    required this.ok,
    required this.alreadySent,
    required this.superResonanceBalance,
    required this.signalId,
  });

  final bool ok;
  final bool alreadySent;
  final int superResonanceBalance;
  final String signalId;

  static SuperResonanceSendResult? fromPublicMap(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    if (data['ok'] != true) return null;
    final balance = _nonNegativeInt(data['super_resonance_balance']);
    final signalId = data['signal_id'];
    if (signalId is! String || signalId.isEmpty) return null;
    return SuperResonanceSendResult(
      ok: true,
      alreadySent: data['already_sent'] == true,
      superResonanceBalance: balance,
      signalId: signalId,
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
