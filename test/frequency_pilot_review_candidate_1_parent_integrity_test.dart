import 'package:flutter_test/flutter_test.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  test('candidate parent SHA256 constant matches disk', () {
    expect(
      FrequencyPilotReviewCandidate1Loader.parentSha256FromDisk(),
      FrequencyPilotReviewCandidate1Loader.parentSha256,
    );
  });

  test('parent pilot file was not overwritten by candidate generation', () {
    final parent = FrequencyPilotReviewCandidate1Loader.loadParent();
    expect(parent['content_version'], 'frequency-tr-pilot-v1');
    expect(parent['set_id'], 'frequency_tr_pilot_v1_set_001');
    for (final raw in parent['items'] as List) {
      final j = raw as Map;
      expect(j['content_version'], 'frequency-tr-pilot-v1');
    }
  });
}
