import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/settings/domain/notification_prefs_snapshot.dart';
import 'package:qmatch/features/settings/services/notification_prefs_client.dart';

void main() {
  group('NotificationPrefsSnapshot', () {
    test('missing or malformed maps default all ON', () {
      expect(
        NotificationPrefsSnapshot.fromTrustedMap(null),
        NotificationPrefsSnapshot.allEnabled,
      );
      expect(
        NotificationPrefsSnapshot.fromTrustedMap('bad'),
        NotificationPrefsSnapshot.allEnabled,
      );
      expect(
        NotificationPrefsSnapshot.fromTrustedMap(<String, dynamic>{}),
        NotificationPrefsSnapshot.allEnabled,
      );
      expect(
        NotificationPrefsSnapshot.fromTrustedMap({
          'push_master': null,
          'messages': 'x',
        }),
        NotificationPrefsSnapshot.allEnabled,
      );
    });

    test('only explicit false disables a field', () {
      final prefs = NotificationPrefsSnapshot.fromTrustedMap({
        'push_master': false,
        'messages': true,
        'matches': false,
        'super_resonance': true,
      });
      expect(prefs.pushMaster, isFalse);
      expect(prefs.messages, isTrue);
      expect(prefs.matches, isFalse);
      expect(prefs.superResonance, isTrue);
    });

    test('toCallablePayload sends all four booleans', () {
      expect(
        const NotificationPrefsSnapshot(
          pushMaster: false,
          messages: true,
          matches: false,
          superResonance: true,
        ).toCallablePayload(),
        {
          'push_master': false,
          'messages': true,
          'matches': false,
          'super_resonance': true,
        },
      );
    });
  });

  group('NotificationPrefsClient', () {
    test('get uses europe-west1 getNotificationPrefs', () async {
      String? called;
      Map<String, dynamic>? sent;
      final client = NotificationPrefsClient(
        call: (name, data) async {
          called = name;
          sent = data;
          return {
            'push_master': false,
            'messages': true,
            'matches': true,
            'super_resonance': false,
          };
        },
      );

      final prefs = await client.get();
      expect(called, NotificationPrefsClient.getCallableName);
      expect(NotificationPrefsClient.region, 'europe-west1');
      expect(NotificationPrefsClient.getCallableName, 'getNotificationPrefs');
      expect(sent, isEmpty);
      expect(prefs.pushMaster, isFalse);
      expect(prefs.superResonance, isFalse);
    });

    test('set posts full payload to setNotificationPrefs', () async {
      String? called;
      Map<String, dynamic>? sent;
      final client = NotificationPrefsClient(
        call: (name, data) async {
          called = name;
          sent = data;
          return data;
        },
      );

      const next = NotificationPrefsSnapshot(
        pushMaster: true,
        messages: false,
        matches: true,
        superResonance: false,
      );
      final saved = await client.set(next);
      expect(called, NotificationPrefsClient.setCallableName);
      expect(NotificationPrefsClient.setCallableName, 'setNotificationPrefs');
      expect(sent, next.toCallablePayload());
      expect(saved, next);
    });
  });
}
