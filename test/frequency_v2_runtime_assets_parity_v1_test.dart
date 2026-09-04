import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main() {
  test('runtime V2 assets match reviewed tool/ sources byte-for-byte', () {
    const names = [
      'frequency_behavior_pool_tr_v2_draft1.json',
      'frequency_behavior_pool_tr_v2_draft1_review_metadata.json',
      'frequency_behavior_pool_en_v2_draft1.json',
      'frequency_behavior_pool_en_v2_draft1_review_metadata.json',
    ];
    for (final name in names) {
      final source =
          File('tool/frequency_behavior_v2/out/$name').readAsBytesSync();
      final asset =
          File('assets/assessment/frequency_v2/$name').readAsBytesSync();
      expect(asset, source, reason: name);
      expect(
          sha256.convert(asset).toString(), sha256.convert(source).toString());
    }
  });

  test('sync tool --check exits 0 and pubspec lists only runtime copies', () {
    final result = Process.runSync(
      'python3',
      ['tool/sync_frequency_v2_runtime_assets.py', '--check'],
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec.contains(FrequencyBehaviorV2Contract.runtimePoolAssetPathTr),
      isTrue,
    );
    expect(
      pubspec.contains(FrequencyBehaviorV2Contract.runtimePoolAssetPathEn),
      isTrue,
    );
    expect(
      pubspec.contains(FrequencyBehaviorV2Contract.runtimeReviewAssetPathTr),
      isTrue,
    );
    expect(
      pubspec.contains(FrequencyBehaviorV2Contract.runtimeReviewAssetPathEn),
      isTrue,
    );
    expect(pubspec.contains('tool/frequency_behavior_v2/out/'), isFalse);
  });
}
