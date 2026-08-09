import 'package:flutter_test/flutter_test.dart';

import 'support/frequency_pilot_review_candidate_1_helpers.dart';

void main() {
  test('parent frequency pilot SHA256 is unchanged', () {
    expect(
      FrequencyPilotReviewCandidate1Loader.parentSha256FromDisk(),
      FrequencyPilotReviewCandidate1Loader.parentSha256,
    );
  });

  test('parent content_version remains frequency-tr-pilot-v1', () {
    final parent = FrequencyPilotReviewCandidate1Loader.loadParent();
    expect(parent['content_version'], 'frequency-tr-pilot-v1');
    expect(parent['form_id'], 'frequency_tr_pilot_v1');
    expect((parent['items'] as List), hasLength(50));
  });
}
