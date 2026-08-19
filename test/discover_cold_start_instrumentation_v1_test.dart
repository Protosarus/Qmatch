import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/debug/qmatch_perf.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  String getCandidatesBody() {
    final src = read('lib/features/discover/services/discover_service.dart');
    final start = src.indexOf(
      'Future<List<DiscoverUserModel>> getCandidates({int limit = 30}) async {',
    );
    final end = src.indexOf(
      'Future<void> _hydrateViewerLegacyFrequencyMirrors({',
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    return src.substring(start, end);
  }

  test('Discover traces cover firestore, L1, L2, and rank', () {
    final service =
        read('lib/features/discover/services/discover_service.dart');
    expect(service.contains("QmatchPerf.trace('discover.firestore_batch'"),
        isTrue);
    expect(service.contains("'discover.me_get'"), isTrue);
    expect(service.contains("'discover.swipes_get'"), isTrue);
    expect(service.contains("'discover.blocks_get'"), isTrue);
    expect(service.contains("'discover.eligible_query'"), isTrue);
    expect(
        service.contains("QmatchPerf.traceSync('discover.l1_local'"), isTrue);
    expect(service.contains("'discover.l2_callable'"), isTrue);
    expect(
        service.contains("QmatchPerf.traceSync('discover.cpu_rank'"), isTrue);

    final sr = read(
      'lib/features/discover/services/discover_super_resonance_controller.dart',
    );
    expect(
        sr.contains("QmatchPerf.trace('super_resonance.availability'"), isTrue);

    final perf = read('lib/core/debug/qmatch_perf.dart');
    expect(perf.contains('!kReleaseMode'), isTrue);
    expect(perf.contains('static T traceSync<T>'), isTrue);
  });

  test('trusted L2 is awaited before the ranked deck is returned', () {
    final body = getCandidatesBody();
    final l2Idx = body.indexOf("'discover.l2_callable'");
    final awaitL2 = body.indexOf(
      "await QmatchPerf.trace(\n      'discover.l2_callable'",
    );
    final rankIdx = body.indexOf("QmatchPerf.traceSync('discover.cpu_rank'");
    final returnIdx = body.lastIndexOf('return ranked;');
    expect(l2Idx, greaterThanOrEqualTo(0));
    expect(awaitL2, greaterThanOrEqualTo(0));
    expect(awaitL2, lessThan(l2Idx));
    expect(rankIdx, greaterThan(l2Idx));
    expect(returnIdx, greaterThan(rankIdx));
    expect(body.contains('applyTrustedMembership'), isTrue);
    expect(body.contains('rankL1Batch'), isTrue);
    expect(body.contains('await _trustedL2Batch'), isFalse);
    expect(body.contains('_trustedL2Batch('), isTrue);
  });

  test('debug shadow is scheduled after rank and is not awaited', () {
    final body = getCandidatesBody();
    final service =
        read('lib/features/discover/services/discover_service.dart');
    final rankIdx = body.indexOf("QmatchPerf.traceSync('discover.cpu_rank'");
    final scheduleIdx = body.indexOf('_scheduleShadowDiagnostics(');
    final returnIdx = body.lastIndexOf('return ranked;');
    expect(scheduleIdx, greaterThan(rankIdx));
    expect(returnIdx, greaterThan(scheduleIdx));
    expect(body.contains('await _computeShadowDiagnostics'), isFalse);
    expect(body.contains('await _scheduleShadowDiagnostics'), isFalse);
    expect(service.contains('unawaited('), isTrue);
    expect(
      service.contains(
        '_enableShadowDiagnostics = enableShadowDiagnostics && kDebugMode',
      ),
      isTrue,
    );
  });

  test('release ranking path is unchanged and does not use shadow order', () {
    final body = getCandidatesBody();
    expect(body.contains('DiscoverStructuralL2Ranking.rankL1Batch'), isTrue);
    expect(body.contains('DiscoverStructuralL2Ranking.applyTrustedMembership'),
        isTrue);
    expect(body.contains('compareDiscoverCandidates'), isTrue);
    expect(body.contains('attached.candidates'), isFalse);
    expect(body.contains('lastShadowDiagnostics = ranked'), isFalse);

    final service =
        read('lib/features/discover/services/discover_service.dart');
    final attachIdx = service.indexOf('_shadowAttacher.attach');
    expect(attachIdx, greaterThan(0));
    expect(service.contains('ranked = attached.candidates'), isFalse);
    expect(service.contains('ranked = l3Attached.candidates'), isFalse);
  });

  test('qmatch.perf logs names and milliseconds only', () {
    final perf = read('lib/core/debug/qmatch_perf.dart');
    expect(
      perf.contains(
        "debugPrint('qmatch.perf \$name \${elapsed.inMilliseconds}ms')",
      ),
      isTrue,
    );
    expect(RegExp(r'\$\{?\s*uid').hasMatch(perf), isFalse);
    expect(perf.contains('candidate_uids'), isFalse);
    expect(perf.contains('canonical_v1'), isFalse);

    final service =
        read('lib/features/discover/services/discover_service.dart');
    for (final name in [
      'discover.firestore_batch',
      'discover.me_get',
      'discover.swipes_get',
      'discover.blocks_get',
      'discover.eligible_query',
      'discover.l1_local',
      'discover.l2_callable',
      'discover.cpu_rank',
    ]) {
      expect(service.contains("'$name'"), isTrue);
    }
    final l2Client = read(
      'lib/features/discover/services/discover_stage_b2_trusted_l2_client.dart',
    );
    expect(l2Client.contains("'discover.l2_us'"), isTrue);
    expect(l2Client.contains("'discover.l2_eu'"), isTrue);
    expect(QmatchPerf.enabled, isTrue);
  });
}
