import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/services/entitlement_repository.dart';
import 'package:qmatch/features/iap/services/iap_backend_client.dart';
import 'package:qmatch/features/iap/services/ios_iap_client.dart';
import 'package:qmatch/features/iap/services/ios_iap_session.dart';
import 'package:qmatch/features/iap/widgets/ios_iap_session_host.dart';

import 'ios_iap_client_v1_test.dart' as iap_client_test;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    IosIapSession.debugResetInstance();
  });

  IosIapClient buildClient(iap_client_test.FakeIapStore store) {
    return IosIapClient(
      store: store,
      isIosOverride: true,
      uidProvider: () => 'uid-1',
      entitlements: EntitlementRepository(
        fetchOverride: (u) async => EntitlementSnapshot(
          uid: u,
          tier: 'free',
          subscriptionState: 'none',
          resonanceAccess: false,
          superResonanceBalance: 0,
          boostBalance: 0,
        ),
      ),
      backend: IapBackendClient(
        call: (name, data) async {
          if (name == IapBackendClient.verifyAndApplyPurchaseName) {
            return {
              'ok': true,
              'trusted': true,
              'verified': true,
            };
          }
          fail('unexpected callable $name');
        },
      ),
    );
  }

  test('session attach starts one listener and second attach is a no-op', () {
    final store = iap_client_test.FakeIapStore();
    final session = IosIapSession(createClient: () => buildClient(store));
    session.attach();
    session.attach();
    expect(session.isAttached, isTrue);
    expect(session.isListening, isTrue);
    expect(store.listenCount, 1);
    expect(identical(session.client, session.client), isTrue);
  });

  test('session detach cancels the listener', () async {
    final store = iap_client_test.FakeIapStore();
    final session = IosIapSession(createClient: () => buildClient(store));
    session.attach();
    expect(session.isListening, isTrue);
    await session.detach();
    expect(session.isAttached, isFalse);
    expect(session.isListening, isFalse);
  });

  test('non-iOS attach does not throw', () {
    final store = iap_client_test.FakeIapStore();
    final session = IosIapSession(
      createClient: () => IosIapClient(
        store: store,
        isIosOverride: false,
        uidProvider: () => 'uid-1',
      ),
    );
    expect(session.attach, returnsNormally);
    expect(session.isAttached, isTrue);
    expect(session.isListening, isFalse);
    expect(store.listenCount, 0);
  });

  testWidgets('IosIapSessionHost attaches on mount and detaches on dispose',
      (tester) async {
    final store = iap_client_test.FakeIapStore();
    final session = IosIapSession(createClient: () => buildClient(store));

    await tester.pumpWidget(
      MaterialApp(
        home: IosIapSessionHost(
          session: session,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    expect(session.isListening, isTrue);
    expect(store.listenCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(session.isAttached, isFalse);
    expect(session.isListening, isFalse);
  });

  group('wiring (source)', () {
    test('AuthWrapper starts IAP session after Firebase Auth, not Welcome', () {
      final wrapper = File(
        'lib/core/navigation/auth_wrapper.dart',
      ).readAsStringSync();
      expect(wrapper.contains('IosIapSessionHost'), isTrue);
      expect(wrapper.contains('qmatch-iap-session-'), isTrue);
      final welcomeIdx = wrapper.indexOf('WelcomeScreen');
      final hostIdx = wrapper.indexOf('IosIapSessionHost');
      expect(hostIdx, greaterThan(welcomeIdx));
    });

    test('paywall reuses session client instead of constructing a new listener',
        () {
      final paywall = File(
        'lib/features/iap/screens/resonance_paywall_screen.dart',
      ).readAsStringSync();
      expect(paywall.contains('IosIapSession.instance.client'), isTrue);
      expect(paywall.contains('?? IosIapClient()'), isFalse);
    });

    test('client recovers unfinished txns only when no paywall flow owns them',
        () {
      final client = File(
        'lib/features/iap/services/ios_iap_client.dart',
      ).readAsStringSync();
      expect(client.contains('_recoverUnfinished'), isTrue);
      expect(client.contains('verifyAndApplyPurchase'), isTrue);
      expect(client.contains('_inFlightRecovery'), isTrue);
      expect(client.contains('ownedByPaywallFlow'), isTrue);
    });
  });
}
