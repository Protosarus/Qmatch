import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps locked V2 session to finalizeFrequencyV2 allowlist', () async {
    final bank = await FrequencyV2RuntimeTestHarness.loadTr();
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'owner-1',
      seed: 'map-seed',
    );
    final mapped = FrequencyV2FinalizeRequestMapper.mapLockedSession(
      session: pending.session,
      ownerUid: 'owner-1',
    );
    expect(mapped.ok, isTrue);
    final payload = mapped.payload!;
    expect(
      payload.keys.toSet(),
      FrequencyV2FinalizeRequestMapper.allowedKeys.difference({
        'translation_version',
      }),
    );
    expect(payload['schema_version'], 'frequency_behavior_v2_finalize_session_v1');
    expect(payload['catalog_version'], 'frequency_behavior_v2_catalog_v1');
    expect(payload['assessment_type'], 'frequency_v2');
    expect(payload['item_plans'], hasLength(50));
    expect(payload['answers'], hasLength(50));
    expect((payload['item_plans'] as List).first, contains('presented_option_order'));
    for (final key in FrequencyV2FinalizeRequestMapper.forbiddenAuthorityKeys) {
      expect(payload.containsKey(key), isFalse, reason: key);
    }
  });

  test('EN mapper includes translation_version', () async {
    final bank = await FrequencyV2RuntimeTestHarness.loadEn();
    final pending = await FrequencyV2RuntimeTestHarness.pendingSession(
      bank: bank,
      uid: 'owner-en',
      seed: 'map-en',
    );
    final mapped = FrequencyV2FinalizeRequestMapper.mapLockedSession(
      session: pending.session,
      ownerUid: 'owner-en',
    );
    expect(mapped.ok, isTrue);
    expect(
      mapped.payload!['translation_version'],
      'frequency_v2_en_semantic_v1',
    );
  });
}
