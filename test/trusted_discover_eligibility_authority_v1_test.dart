import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Client-side wiring checks for `trusted_discover_eligibility_authority_v1`.
void main() {
  group('trusted discover eligibility authority — client', () {
    test('ProfileService no longer self-grants discover_eligible', () {
      final src = File(
        'lib/features/profile/services/profile_service.dart',
      ).readAsStringSync();
      expect(src.contains("'discover_eligible':"), isFalse);
      expect(src.contains('"discover_eligible":'), isFalse);
      expect(src.contains('refreshDiscoverEligibility'), isTrue);
      // saveProfile must not depend on a client eligibility write.
      final saveIdx = src.indexOf('Future<void> saveProfile');
      final readIdx = src.indexOf('Future<ProfileReadResult> readOwnProfile');
      expect(saveIdx, greaterThanOrEqualTo(0));
      expect(readIdx, greaterThan(saveIdx));
      final saveBody = src.substring(saveIdx, readIdx);
      expect(saveBody.contains('refreshDiscoverEligibility'), isFalse);
      expect(saveBody.contains("'discover_eligible'"), isFalse);
      expect(saveBody.contains('"discover_eligible"'), isFalse);
    });

    test('AuthService does not client-grant discover_eligible on test complete',
        () {
      final src = File('lib/core/services/auth_service.dart').readAsStringSync();
      expect(src.contains('_refreshDiscoverEligibility'), isFalse);
      // Signup may still seed false; must never write true.
      expect(src.contains("'discover_eligible': true"), isFalse);
      expect(src.contains("'discover_eligible': false"), isTrue);
    });

    test('Frequency completion does not call client eligibility refresh', () {
      final src = File(
        'lib/features/assessment/screens/frequency_test_screen.dart',
      ).readAsStringSync();
      expect(src.contains('refreshDiscoverEligibility'), isFalse);
      expect(src.contains('ProfileService'), isFalse);
    });

    test('deletion revoke-to-false remains', () {
      final src = File(
        'lib/features/settings/services/account_deletion_request_service.dart',
      ).readAsStringSync();
      expect(src.contains("'discover_eligible': false"), isTrue);
      expect(src.contains("'account_deletion_requested': true"), isTrue);
    });

    test('Discover L1 + match validity gates preserved', () {
      final l1 = File(
        'lib/features/discover/services/discover_l1_eligibility_gate.dart',
      ).readAsStringSync();
      expect(l1.contains('passesLocalAccountGates'), isTrue);

      final live = File(
        'lib/features/matching/services/match_live_user_validity_gate.dart',
      ).readAsStringSync();
      expect(live.contains("data['discover_eligible'] != true"), isTrue);

      final rules = File('firestore.rules').readAsStringSync();
      expect(rules.contains('eligibleOk'), isTrue);
      expect(
        rules.contains('request.resource.data.discover_eligible == false'),
        isTrue,
      );
    });

    test('trusted Cloud Function source is present', () {
      expect(File('functions/index.js').existsSync(), isTrue);
      expect(
        File('functions/src/discover_eligibility.js').existsSync(),
        isTrue,
      );
      final index = File('functions/index.js').readAsStringSync();
      expect(index.contains('recomputeDiscoverEligibleOnUserWrite'), isTrue);
      expect(index.contains('planDiscoverEligibleWrite'), isTrue);
      expect(
        index.contains('trusted_discover_eligibility_authority_v1'),
        isTrue,
      );
    });
  });
}
