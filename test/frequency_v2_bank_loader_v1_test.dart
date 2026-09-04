import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FrequencyV2BankLoader', () {
    test('loads reviewed TR bank by version and locale', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      expect(bank.poolVersion, FrequencyBehaviorV2Contract.poolVersionTrDraft1);
      expect(bank.locale, FrequencyBehaviorV2Contract.localeTr);
      expect(bank.pool.schemaVersion, FrequencyBehaviorV2Contract.schemaVersion);
      expect(bank.pool.items.length, FrequencyBehaviorV2Contract.poolItemCount);
      expect(bank.pool.runtimeSelectable, isFalse);
      expect(
        FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(bank.poolVersion),
        isFalse,
      );
    });

    test('loads reviewed EN bank and validates translation_version', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadEn();
      expect(bank.poolVersion, FrequencyBehaviorV2Contract.poolVersionEnDraft1);
      expect(bank.locale, FrequencyBehaviorV2Contract.localeEn);
      expect(
        bank.translationVersion,
        FrequencyBehaviorV2Contract.translationVersionEnSemanticV1,
      );
      expect(bank.pool.items.length, 426);
      expect(
        bank.pool.items.every((i) => i.options.length == 4),
        isTrue,
      );
    });

    test('rejects locale/version mismatch', () async {
      final loader = FrequencyV2BankLoader();
      expect(
        () => loader.load(
          poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
          locale: FrequencyBehaviorV2Contract.localeEn,
        ),
        throwsA(
          isA<FrequencyV2BankLoadException>().having(
            (e) => e.code,
            'code',
            'unknown_bank',
          ),
        ),
      );
    });

    test('rejects EN translation_version mismatch', () async {
      final loader = FrequencyV2BankLoader();
      expect(
        () => loader.load(
          poolVersion: FrequencyBehaviorV2Contract.poolVersionEnDraft1,
          locale: FrequencyBehaviorV2Contract.localeEn,
          expectedTranslationVersion: 'frequency_v2_en_semantic_WRONG',
        ),
        throwsA(
          isA<FrequencyV2BankLoadException>().having(
            (e) => e.code,
            'code',
            'translation_version_mismatch',
          ),
        ),
      );
    });
  });
}
