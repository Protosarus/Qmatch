import 'temporal_shadow_extractor.dart';
import 'temporal_shadow_extractor_contract.dart';
import 'temporal_shadow_extractor_models.dart';
import 'temporal_shadow_diagnostics_bridge_contract.dart';

/// One thread's shadow diagnostic outcome (no message bodies).
class TemporalShadowThreadDiagnostic {
  const TemporalShadowThreadDiagnostic({
    required this.threadId,
    required this.participantP,
    required this.participantQ,
    required this.eventCount,
    required this.result,
  });

  final String threadId;
  final String participantP;
  final String participantQ;
  final int eventCount;
  final TemporalShadowThreadResult result;

  Map<String, dynamic> toWireMap() => {
        'thread_id': threadId,
        'participant_p': participantP,
        'participant_q': participantQ,
        'event_count': eventCount,
        'result': result.toWireMap(),
      };
}

/// Aggregate local diagnostics across threads — never persisted by this bridge.
class TemporalShadowAggregateDiagnostics {
  const TemporalShadowAggregateDiagnostics({
    required this.hasData,
    required this.noDataReason,
    required this.threadCountExamined,
    required this.threadCountWithResults,
    required this.uniqueUserCount,
    required this.totalEligibleEvents,
    required this.threads,
  });

  final bool hasData;
  final String? noDataReason;
  final int threadCountExamined;
  final int threadCountWithResults;
  final int uniqueUserCount;
  final int totalEligibleEvents;
  final List<TemporalShadowThreadDiagnostic> threads;

  static TemporalShadowAggregateDiagnostics noData(String reason) {
    return TemporalShadowAggregateDiagnostics(
      hasData: false,
      noDataReason: reason,
      threadCountExamined: 0,
      threadCountWithResults: 0,
      uniqueUserCount: 0,
      totalEligibleEvents: 0,
      threads: const [],
    );
  }

  Map<String, dynamic> toWireMap() => {
        'scoring_version':
            TemporalShadowDiagnosticsBridgeContract.scoringVersion,
        'policy_status': TemporalShadowDiagnosticsBridgeContract.policyStatus,
        'shadow_only': TemporalShadowDiagnosticsBridgeContract.shadowOnly,
        'persists_derived_features':
            TemporalShadowDiagnosticsBridgeContract.persistsDerivedFeatures,
        'affects_discover_ranking':
            TemporalShadowDiagnosticsBridgeContract.affectsDiscoverRanking,
        'gates_calibrated': TemporalShadowExtractorContract.gatesCalibrated,
        'has_data': hasData,
        if (noDataReason != null) 'no_data_reason': noDataReason,
        'thread_count_examined': threadCountExamined,
        'thread_count_with_results': threadCountWithResults,
        'unique_user_count': uniqueUserCount,
        'total_eligible_events': totalEligibleEvents,
        'omega': {'status': 'unavailable'},
        'threads': [for (final t in threads) t.toWireMap()],
      };
}

/// Input bundle for one thread (metadata only).
class TemporalShadowThreadInput {
  const TemporalShadowThreadInput({
    required this.threadId,
    required this.participants,
    required this.events,
  });

  final String threadId;
  final List<String> participants;
  final List<TemporalShadowEvent> events;
}

/// Debug/shadow bridge: metadata → [TemporalShadowExtractor].
///
/// Never accepts or emits message bodies. Does not persist features or affect
/// Discover ranking.
class TemporalShadowDiagnosticsBridge {
  const TemporalShadowDiagnosticsBridge({
    TemporalShadowExtractor extractor = const TemporalShadowExtractor(),
  }) : _extractor = extractor;

  final TemporalShadowExtractor _extractor;

  /// Build an event from already-projected metadata fields only.
  ///
  /// Prefer [clientCreatedAtMs]; fall back to [createdAtMs]. Returns null when
  /// sender/timestamp missing. Callers must not pass message text here.
  static TemporalShadowEvent? eventFromMetadata({
    required String? senderId,
    int? clientCreatedAtMs,
    int? createdAtMs,
  }) {
    if (senderId == null || senderId.isEmpty) return null;
    final ts = clientCreatedAtMs ?? createdAtMs;
    if (ts == null) return null;
    return TemporalShadowEvent(timestampMs: ts, senderId: senderId);
  }

  /// Project a raw Firestore message map to an event without reading bodies.
  ///
  /// Only [TemporalShadowDiagnosticsBridgeContract.allowedMessageFieldKeys]
  /// are consulted. `text` / body fields are ignored even if present.
  static TemporalShadowEvent? eventFromFirestoreMessageData(
    Map<String, dynamic> data,
  ) {
    final senderId = data['sender_id'] as String?;
    final clientCreatedAtMs = (data['client_created_at'] as num?)?.toInt();
    final createdAtMs = _timestampToMs(data['created_at']);
    return eventFromMetadata(
      senderId: senderId,
      clientCreatedAtMs: clientCreatedAtMs,
      createdAtMs: createdAtMs,
    );
  }

  /// Analyze one thread. Returns null when participants are not a dyad or
  /// there are no eligible events in-window.
  TemporalShadowThreadDiagnostic? analyzeThread({
    required String threadId,
    required List<String> participants,
    required List<TemporalShadowEvent> events,
    Duration? localTimeZoneOffset,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final dyad = _dyadParticipants(participants);
    if (dyad == null) return null;

    final (p, q) = dyad;
    final start = windowStart ?? _inferWindowStart(events);
    final end = windowEnd ?? _inferWindowEnd(events);
    if (start == null || end == null || !end.isAfter(start)) {
      return null;
    }

    final result = _extractor.extractThread(
      participantP: p,
      participantQ: q,
      events: events,
      windowStart: start,
      windowEnd: end,
      localTimeZoneOffset: localTimeZoneOffset,
    );

    final eligible = result.dyadic.eventCountTotal;
    if (eligible <= 0) return null;

    return TemporalShadowThreadDiagnostic(
      threadId: threadId,
      participantP: p,
      participantQ: q,
      eventCount: eligible,
      result: result,
    );
  }

  /// Aggregate local diagnostics. Clear no-data when nothing eligible.
  TemporalShadowAggregateDiagnostics analyzeThreads({
    required List<TemporalShadowThreadInput> threads,
    Duration? localTimeZoneOffset,
  }) {
    if (threads.isEmpty) {
      return TemporalShadowAggregateDiagnostics.noData('no_threads');
    }

    final out = <TemporalShadowThreadDiagnostic>[];
    final users = <String>{};
    var totalEvents = 0;

    for (final t in threads) {
      final d = analyzeThread(
        threadId: t.threadId,
        participants: t.participants,
        events: t.events,
        localTimeZoneOffset: localTimeZoneOffset,
      );
      if (d == null) continue;
      out.add(d);
      users.add(d.participantP);
      users.add(d.participantQ);
      totalEvents += d.eventCount;
    }

    if (out.isEmpty) {
      return TemporalShadowAggregateDiagnostics(
        hasData: false,
        noDataReason: 'no_eligible_events',
        threadCountExamined: threads.length,
        threadCountWithResults: 0,
        uniqueUserCount: 0,
        totalEligibleEvents: 0,
        threads: const [],
      );
    }

    return TemporalShadowAggregateDiagnostics(
      hasData: true,
      noDataReason: null,
      threadCountExamined: threads.length,
      threadCountWithResults: out.length,
      uniqueUserCount: users.length,
      totalEligibleEvents: totalEvents,
      threads: List.unmodifiable(out),
    );
  }

  static (String, String)? _dyadParticipants(List<String> participants) {
    final uniq = <String>{
      for (final p in participants)
        if (p.isNotEmpty &&
            p != TemporalShadowExtractorContract.systemSenderId)
          p,
    };
    if (uniq.length != 2) return null;
    final sorted = uniq.toList()..sort();
    return (sorted[0], sorted[1]);
  }

  static DateTime? _inferWindowStart(List<TemporalShadowEvent> events) {
    if (events.isEmpty) return null;
    var min = events.first.timestampMs;
    for (final e in events) {
      if (e.timestampMs < min) min = e.timestampMs;
    }
    return DateTime.fromMillisecondsSinceEpoch(min, isUtc: true);
  }

  static DateTime? _inferWindowEnd(List<TemporalShadowEvent> events) {
    if (events.isEmpty) return null;
    var max = events.first.timestampMs;
    for (final e in events) {
      if (e.timestampMs > max) max = e.timestampMs;
    }
    // Include the last event in the closed window.
    return DateTime.fromMillisecondsSinceEpoch(max + 1, isUtc: true);
  }

  static int? _timestampToMs(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    // Duck-type cloud_firestore.Timestamp without importing it in domain.
    try {
      final dynamic d = raw;
      final ms = d.millisecondsSinceEpoch;
      if (ms is int) return ms;
      if (ms is num) return ms.toInt();
    } catch (_) {}
    return null;
  }
}
