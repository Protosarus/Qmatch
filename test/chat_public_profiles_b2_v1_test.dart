import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/identity/user_identity_resolver.dart';
import 'package:qmatch/features/messages/services/chat_service.dart';
import 'package:qmatch/features/messages/widgets/qmatch_conversation_app_bar.dart';
import 'package:qmatch/features/messages/widgets/qmatch_conversation_tile.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  String read(String path) => File(path).readAsStringSync();

  String chatServiceGetBody() {
    final src = read('lib/features/messages/services/chat_service.dart');
    final start = src.indexOf(
      'Future<Map<String, dynamic>?> getUserPublicProfile(String uid) async {',
    );
    final end = src.indexOf(
      'String getOtherParticipantId(ChatThreadModel thread, String currentUid)',
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    return src.substring(start, end);
  }

  group('Chat B2 public_profiles peer GET', () {
    test('A getUserPublicProfile reads publicProfileDoc(uid)', () {
      final body = chatServiceGetBody();
      expect(body.contains('FirestorePaths.publicProfileDoc(uid).get()'), isTrue);
    });

    test('B does not use userDoc(uid) as a peer fallback', () {
      final body = chatServiceGetBody();
      final service = read('lib/features/messages/services/chat_service.dart');
      expect(body.contains('userDoc('), isFalse);
      expect(body.contains("collection('users')"), isFalse);
      expect(body.contains('FirestorePaths.users()'), isFalse);
      expect(service.contains('FirestorePaths.userDoc('), isFalse);
    });

    test('permission-denied and not-found return null; other errors rethrow', () {
      final body = chatServiceGetBody();
      expect(body.contains("e.code == 'permission-denied'"), isTrue);
      expect(body.contains("e.code == 'not-found'"), isTrue);
      expect(body.contains('return null'), isTrue);
      expect(body.contains('rethrow'), isTrue);
    });

    test('E discover_eligible is not a client-side rejection', () {
      final body = chatServiceGetBody();
      expect(body.contains('discover_eligible'), isFalse);
      expect(
        read('lib/features/messages/services/chat_service.dart')
            .contains("discover_eligible == true"),
        isFalse,
      );
    });
  });

  group('Chat B2 safe display field contract', () {
    test('C name, profile_photo_url, and photos are parsed', () {
      final mapped = chatPublicProfileFromData('peerA', {
        'name': 'Ada',
        'age': 29,
        'profile_photo_url': 'https://example.com/a.jpg',
        'photos': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
        'discover_eligible': false,
      });
      expect(mapped['uid'], 'peerA');
      expect(mapped['name'], 'Ada');
      expect(mapped['age'], 29);
      expect(mapped['profile_photo_url'], 'https://example.com/a.jpg');
      expect(mapped['photos'], [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
      ]);
    });

    test('D missing optional fields do not crash', () {
      final mapped = chatPublicProfileFromData('peerB', {});
      expect(mapped['uid'], 'peerB');
      expect(mapped['name'], isNull);
      expect(mapped['age'], isNull);
      expect(mapped['profile_photo_url'], isNull);
      expect(mapped['photos'], isEmpty);
      expect(
        () => UserIdentityResolver.fromUserMap(mapped),
        returnsNormally,
      );
      expect(
        UserIdentityResolver.fromUserMap(mapped).hasDisplayName,
        isFalse,
      );
    });

    test('E discover_eligible false still maps display fields', () {
      final mapped = chatPublicProfileFromData('peerC', {
        'discover_eligible': false,
        'name': 'Ada',
        'profile_photo_url': 'https://example.com/a.jpg',
      });
      expect(mapped['name'], 'Ada');
      expect(mapped['profile_photo_url'], 'https://example.com/a.jpg');
      expect(mapped.containsKey('discover_eligible'), isFalse);
    });

    test('G chat peer header does not require private users fields', () {
      final mapped = chatPublicProfileFromData('peerD', {
        'name': 'Ada',
        'profile_photo_url': 'https://example.com/a.jpg',
        'photos': ['https://example.com/a.jpg'],
        'email': 'hidden@example.com',
        'phone': '+15555550100',
        'archetype': 'The Mastermind',
        'category': 'HH',
        'active': true,
        'profile_completed': true,
        'test_completed': true,
        'assessment_flow_completed': true,
        'iq_normalized': 0.9,
        'eq_normalized': 0.8,
        'frequency_type': 'deep',
        'location': 'secret',
      });
      expect(mapped.containsKey('email'), isFalse);
      expect(mapped.containsKey('phone'), isFalse);
      expect(mapped.containsKey('archetype'), isFalse);
      expect(mapped.containsKey('category'), isFalse);
      expect(mapped.containsKey('active'), isFalse);
      expect(mapped.containsKey('profile_completed'), isFalse);
      expect(mapped.containsKey('test_completed'), isFalse);
      expect(mapped.containsKey('assessment_flow_completed'), isFalse);
      expect(mapped.containsKey('iq_normalized'), isFalse);
      expect(mapped.containsKey('eq_normalized'), isFalse);
      expect(mapped.containsKey('frequency_type'), isFalse);
      expect(mapped.containsKey('location'), isFalse);
      expect(mapped['name'], 'Ada');
    });

    test('mixed or non-string photos do not crash', () {
      final mapped = chatPublicProfileFromData('peerE', {
        'photos': ['https://example.com/ok.jpg', 12, null, '  '],
      });
      expect(mapped['photos'], ['https://example.com/ok.jpg']);
    });
  });

  group('Chat B2 UI fallbacks', () {
    test('F messages FutureBuilder treats missing profile as fallback data', () {
      final src = read('lib/features/messages/screens/messages_screen.dart');
      expect(src.contains('chatService.getUserPublicProfile(otherId)'), isTrue);
      expect(src.contains('final profile = snap.data;'), isTrue);
      expect(src.contains('UserIdentityResolver.fromUserMap(profile)'), isTrue);
      expect(src.contains('l10n.messagesConversationFallback'), isTrue);
      expect(src.contains('snap.data!'), isFalse);
    });

    test('F chat detail isolates public profile GET from bootstrap failure', () {
      final src = read('lib/features/messages/screens/chat_detail_screen.dart');
      final start = src.indexOf('Map<String, dynamic>? p;');
      final end = src.indexOf('var blockedByMe = false;');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final body = src.substring(start, end);
      expect(body.contains('getUserPublicProfile(widget.otherUserId)'), isTrue);
      expect(body.contains('ChatDetail public profile load failed'), isTrue);
      expect(body.contains('_bootstrapFailed'), isFalse);
    });

    testWidgets(
      'F null/not-found peer profile uses name and avatar placeholders',
      (tester) async {
        late AppLocalizations l10n;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                final resolved = UserIdentityResolver.fromUserMap(null);
                final displayName = resolved.hasDisplayName
                    ? resolved.displayName!
                    : l10n.messagesConversationFallback;
                return Scaffold(
                  appBar: QMatchConversationAppBar(
                    title: displayName,
                    loading: false,
                    photoUrl: null,
                  ),
                  body: QMatchConversationTile(
                    displayName: displayName,
                    age: resolved.age,
                    photoUrl: null,
                    previewText: 'hi',
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text(l10n.messagesConversationFallback), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
