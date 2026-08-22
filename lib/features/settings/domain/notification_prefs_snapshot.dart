/// Trusted notification preferences from `getNotificationPrefs` /
/// `setNotificationPrefs`. Missing fields default to enabled.
class NotificationPrefsSnapshot {
  const NotificationPrefsSnapshot({
    required this.pushMaster,
    required this.messages,
    required this.matches,
    required this.superResonance,
  });

  final bool pushMaster;
  final bool messages;
  final bool matches;
  final bool superResonance;

  static const allEnabled = NotificationPrefsSnapshot(
    pushMaster: true,
    messages: true,
    matches: true,
    superResonance: true,
  );

  factory NotificationPrefsSnapshot.fromTrustedMap(Object? raw) {
    if (raw is! Map) return allEnabled;
    return NotificationPrefsSnapshot(
      pushMaster: raw['push_master'] != false,
      messages: raw['messages'] != false,
      matches: raw['matches'] != false,
      superResonance: raw['super_resonance'] != false,
    );
  }

  Map<String, dynamic> toCallablePayload() {
    return {
      'push_master': pushMaster,
      'messages': messages,
      'matches': matches,
      'super_resonance': superResonance,
    };
  }

  NotificationPrefsSnapshot copyWith({
    bool? pushMaster,
    bool? messages,
    bool? matches,
    bool? superResonance,
  }) {
    return NotificationPrefsSnapshot(
      pushMaster: pushMaster ?? this.pushMaster,
      messages: messages ?? this.messages,
      matches: matches ?? this.matches,
      superResonance: superResonance ?? this.superResonance,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationPrefsSnapshot &&
        other.pushMaster == pushMaster &&
        other.messages == messages &&
        other.matches == matches &&
        other.superResonance == superResonance;
  }

  @override
  int get hashCode =>
      Object.hash(pushMaster, messages, matches, superResonance);
}
