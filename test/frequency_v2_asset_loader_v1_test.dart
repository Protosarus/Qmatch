import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset loader loads TR/EN without repo filesystem paths', () async {
    final runtime = FrequencyV2AssetRuntime(bundle: rootBundle);
    expect(runtime.loader.usesFilesystem, isFalse);
    expect(runtime.loader.repoRoot, isNull);

    final tr = await runtime.loadBankForLanguageCode('tr');
    expect(tr.poolVersion, FrequencyBehaviorV2Contract.poolVersionTrDraft1);
    expect(tr.locale, FrequencyBehaviorV2Contract.localeTr);
    expect(tr.sourcePath, FrequencyBehaviorV2Contract.runtimePoolAssetPathTr);
    expect(tr.sourcePath.startsWith('tool/'), isFalse);
    expect(tr.pool.runtimeSelectable, isFalse);
    expect(tr.pool.items.length, 426);

    final en = await runtime.loadBankForLanguageCode('en');
    expect(en.poolVersion, FrequencyBehaviorV2Contract.poolVersionEnDraft1);
    expect(en.locale, FrequencyBehaviorV2Contract.localeEn);
    expect(en.translationVersion,
        FrequencyBehaviorV2Contract.translationVersionEnSemanticV1);
    expect(en.sourcePath, FrequencyBehaviorV2Contract.runtimePoolAssetPathEn);
    expect(
      FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(en.poolVersion),
      isFalse,
    );
  });

  test('asset runtime can compose a 50-item session without Directory.current',
      () async {
    expect(
      FrequencyV2BankLoader().usesFilesystem,
      isFalse,
    );
    final runtime = FrequencyV2AssetRuntime(
      bundle: rootBundle,
      repository: FrequencyV2SessionMemoryRepository(),
      idFactory: FrequencyV2SessionIdFactory(random: Random(9)),
      random: Random(9),
    );
    final bank = await runtime.loadBankForLanguageCode('tr-TR');
    final controller = await runtime.createSession(
      bank: bank,
      ownerUid: 'asset-owner',
      sessionSeed: 'asset-seed',
    );
    expect(controller.session, isNotNull);
    expect(controller.progressTotal, 50);
    expect(controller.session!.itemPlans, hasLength(50));
    expect(controller.currentItem, isNotNull);
    expect(controller.currentItem!.options, hasLength(4));
  });

  test('filesystem injection still reads reviewed tool/ sources', () async {
    final loader = FrequencyV2BankLoader(repoRoot: Directory.current.path);
    expect(loader.usesFilesystem, isTrue);
    final bank = await loader.load(
      poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      locale: FrequencyBehaviorV2Contract.localeTr,
    );
    expect(bank.sourcePath, FrequencyBehaviorV2Contract.draftPoolRelativePath);
    expect(bank.pool.items.length, 426);
  });
}
