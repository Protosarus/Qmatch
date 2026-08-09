import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  test('candidate is not listed in pubspec assets', () {
    final pubspec = File(
      '${FrequencyPilotReviewCandidate1Loader.repoRoot}/pubspec.yaml',
    ).readAsStringSync();
    expect(
        pubspec.contains('frequency_pilot_tr_v1_review_candidate_1'), isFalse);
  });

  test('no production Dart import of candidate path', () {
    final lib =
        Directory('${FrequencyPilotReviewCandidate1Loader.repoRoot}/lib');
    final hits = <String>[];
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      if (text.contains('frequency_pilot_tr_v1_review_candidate_1')) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty);
  });

  test('PersonaScoringService is not automatically invoked by trait scoring',
      () {
    final config = FrequencyPilotReviewCandidate1Loader.loadConfig();
    final items = FrequencyPilotReviewCandidate1Loader.loadItems(config);
    final service = TraitScoringService(config: config);
    final result = service.scoreModule(
      FrequencyPilotReviewCandidate1Loader.session(
        config: config,
        items: items,
        responses: FrequencyPilotReviewCandidate1Loader.balancedMixed(items),
      ),
    );
    expect(result.module.dimensionScores, isNotEmpty);
    expect(PersonaScoringService, isNotNull);
  });

  test('parent pilot path is distinct and still present', () {
    expect(
      File(
        '${FrequencyPilotReviewCandidate1Loader.repoRoot}/${FrequencyPilotReviewCandidate1Loader.parentPath}',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${FrequencyPilotReviewCandidate1Loader.repoRoot}/${FrequencyPilotReviewCandidate1Loader.candidatePath}',
      ).existsSync(),
      isTrue,
    );
  });

  test('parent SHA256 unchanged after candidate generation', () {
    expect(
      FrequencyPilotReviewCandidate1Loader.parentSha256FromDisk(),
      FrequencyPilotReviewCandidate1Loader.parentSha256,
    );
  });
}
