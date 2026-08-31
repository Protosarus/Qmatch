import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_models.dart';

/// Coarse optional cohort fields. Missing values stay null.
/// Never used by the selector or scorer.
class FrequencyBehaviorV2TelemetryCohort {
  const FrequencyBehaviorV2TelemetryCohort({
    this.ageBucket,
    this.professionCategory,
    this.country,
    this.region,
    this.city,
  });

  final String? ageBucket;
  final String? professionCategory;
  final String? country;
  final String? region;
  final String? city;

  Map<String, dynamic> toJson() => {
        'age_bucket': ageBucket,
        'profession_category': professionCategory,
        'country': country,
        'region': region,
        'city': city,
      };
}

/// Session-level calibration metadata. Not a score payload.
class FrequencyBehaviorV2SessionTelemetry {
  const FrequencyBehaviorV2SessionTelemetry({
    required this.sessionId,
    required this.sessionSeed,
    required this.bankVersion,
    required this.selectorVersion,
    required this.scorerVersion,
    required this.locale,
    required this.questionCount,
    this.schemaVersion =
        FrequencyBehaviorV2Contract.telemetrySessionSchemaVersion,
    this.startedAt,
    this.completedAt,
    this.cohort,
  });

  final String schemaVersion;
  final String bankVersion;
  final String selectorVersion;
  final String scorerVersion;
  final String sessionId;
  final String sessionSeed;
  final String locale;
  final int questionCount;
  final String? startedAt;
  final String? completedAt;
  final FrequencyBehaviorV2TelemetryCohort? cohort;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'bank_version': bankVersion,
        'selector_version': selectorVersion,
        'scorer_version': scorerVersion,
        'session_id': sessionId,
        'session_seed': sessionSeed,
        'locale': locale,
        'question_count': questionCount,
        'started_at': startedAt,
        'completed_at': completedAt,
        'cohort': cohort?.toJson(),
      };
}

/// One presented-question calibration event. Separate from canonical answers.
class FrequencyBehaviorV2ResponseTelemetryEvent {
  const FrequencyBehaviorV2ResponseTelemetryEvent({
    required this.sessionId,
    required this.bankVersion,
    required this.selectorVersion,
    required this.scorerVersion,
    required this.questionId,
    required this.primaryDimension,
    required this.presentedOptionOrder,
    required this.selectedOptionId,
    required this.presentationIndex,
    required this.changedAnswerCount,
    required this.finalChanged,
    required this.locale,
    required this.latencyValid,
    this.schemaVersion =
        FrequencyBehaviorV2Contract.telemetryResponseSchemaVersion,
    this.responseLatencyMs,
    this.selectionSequence = const [],
    this.serverTimestamp,
  });

  final String schemaVersion;
  final String bankVersion;
  final String selectorVersion;
  final String scorerVersion;
  final String sessionId;
  final String questionId;
  final String primaryDimension;
  final List<String> presentedOptionOrder;
  final String selectedOptionId;
  final int presentationIndex;
  final int? responseLatencyMs;
  final bool latencyValid;
  final int changedAnswerCount;
  final bool finalChanged;
  final List<String> selectionSequence;
  final String locale;
  final String? serverTimestamp;

  int? get selectedPresentedPosition {
    final i = presentedOptionOrder.indexOf(selectedOptionId);
    return i < 0 ? null : i;
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'bank_version': bankVersion,
        'selector_version': selectorVersion,
        'scorer_version': scorerVersion,
        'session_id': sessionId,
        'question_id': questionId,
        'primary_dimension': primaryDimension,
        'presented_option_order': presentedOptionOrder,
        'selected_option_id': selectedOptionId,
        'presentation_index': presentationIndex,
        'response_latency_ms': responseLatencyMs,
        'latency_valid': latencyValid,
        'changed_answer_count': changedAnswerCount,
        'final_changed': finalChanged,
        'selection_sequence': selectionSequence,
        'locale': locale,
        'server_timestamp': serverTimestamp,
      };
}

class FrequencyBehaviorV2TelemetrySessionRecord {
  const FrequencyBehaviorV2TelemetrySessionRecord({
    required this.session,
    required this.events,
  });

  final FrequencyBehaviorV2SessionTelemetry session;
  final List<FrequencyBehaviorV2ResponseTelemetryEvent> events;
}

/// Counts distinct option_id transitions. First tap is not a change.
class FrequencyBehaviorV2AnswerChangeTracker {
  String? _current;
  final List<String> sequence = [];

  void recordSelection(String optionId) {
    if (_current == null) {
      _current = optionId;
      sequence.add(optionId);
      return;
    }
    if (optionId == _current) return;
    _current = optionId;
    sequence.add(optionId);
  }

  int get changedAnswerCount => sequence.isEmpty ? 0 : sequence.length - 1;

  bool get finalChanged => changedAnswerCount > 0;

  String? get selectedOptionId => _current;
}

class FrequencyBehaviorV2LatencySample {
  const FrequencyBehaviorV2LatencySample({
    required this.analyticsMs,
    required this.valid,
  });

  final int analyticsMs;
  final bool valid;
}

/// Monotonic elapsed-ms sanitizer. Does not feed the scorer.
class FrequencyBehaviorV2LatencySanitizer {
  const FrequencyBehaviorV2LatencySanitizer();

  FrequencyBehaviorV2LatencySample sanitize(int rawMs) {
    final min = FrequencyBehaviorV2Contract.telemetryLatencyMinValidMs;
    final max = FrequencyBehaviorV2Contract.telemetryLatencyMaxValidMs;
    final valid = rawMs >= min && rawMs <= max;
    var stored = rawMs;
    if (stored < min) stored = min;
    if (stored > max) stored = max;
    return FrequencyBehaviorV2LatencySample(analyticsMs: stored, valid: valid);
  }
}

/// Dormant builder. Never publishes. Never calls the scorer.
class FrequencyBehaviorV2TelemetryFactory {
  const FrequencyBehaviorV2TelemetryFactory();

  static const liveCollectionEnabled =
      FrequencyBehaviorV2Contract.telemetryLiveCollectionEnabled;

  FrequencyBehaviorV2SessionTelemetry sessionFromManifest({
    required FrequencyBehaviorV2SessionManifest manifest,
    String scorerVersion = FrequencyBehaviorV2Contract.scorerVersion,
    String? startedAt,
    String? completedAt,
    FrequencyBehaviorV2TelemetryCohort? cohort,
  }) {
    return FrequencyBehaviorV2SessionTelemetry(
      sessionId: manifest.sessionId,
      sessionSeed: manifest.sessionSeed,
      bankVersion: manifest.bankVersion,
      selectorVersion: manifest.selectorVersion,
      scorerVersion: scorerVersion,
      locale: manifest.locale,
      questionCount: manifest.questionIds.length,
      startedAt: startedAt,
      completedAt: completedAt,
      cohort: cohort,
    );
  }

  FrequencyBehaviorV2ResponseTelemetryEvent eventForQuestion({
    required FrequencyBehaviorV2SessionManifest manifest,
    required FrequencyBehaviorV2SessionQuestion question,
    required FrequencyBehaviorV2AnswerChangeTracker tracker,
    required int rawLatencyMs,
    String scorerVersion = FrequencyBehaviorV2Contract.scorerVersion,
    String? serverTimestamp,
  }) {
    final selected = tracker.selectedOptionId;
    if (selected == null) {
      throw StateError('no_selection:${question.questionId}');
    }
    final latency =
        const FrequencyBehaviorV2LatencySanitizer().sanitize(rawLatencyMs);
    return FrequencyBehaviorV2ResponseTelemetryEvent(
      sessionId: manifest.sessionId,
      bankVersion: manifest.bankVersion,
      selectorVersion: manifest.selectorVersion,
      scorerVersion: scorerVersion,
      questionId: question.questionId,
      primaryDimension: question.primaryDimension,
      presentedOptionOrder: List<String>.from(question.presentedOptionOrder),
      selectedOptionId: selected,
      presentationIndex: question.presentationIndex,
      responseLatencyMs: latency.analyticsMs,
      latencyValid: latency.valid,
      changedAnswerCount: tracker.changedAnswerCount,
      finalChanged: tracker.finalChanged,
      selectionSequence: List<String>.from(tracker.sequence),
      locale: manifest.locale,
      serverTimestamp: serverTimestamp,
    );
  }

  void publishLive(FrequencyBehaviorV2TelemetrySessionRecord record) {
    throw UnsupportedError(
      'Frequency V2 calibration telemetry live collection is disabled',
    );
  }
}
