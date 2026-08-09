import 'assessment_item_definition.dart';
import 'reverse_pair_descriptor.dart';

class AssessmentResponse {
  final String questionId;
  final String? selectedOptionId;
  final int? likertValue;
  final int? responseTimeMilliseconds;
  final List<int>? presentedOptionOrder;
  final DateTime? answeredAt;

  const AssessmentResponse({
    required this.questionId,
    this.selectedOptionId,
    this.likertValue,
    this.responseTimeMilliseconds,
    this.presentedOptionOrder,
    this.answeredAt,
  });
}

class TraitScoringSessionInput {
  final String module;
  final String schemaVersion;
  final String contentVersion;
  final String traitScoringVersion;
  final String locale;
  final String setId;
  final List<AssessmentItemDefinition> questionDefinitions;
  final List<AssessmentResponse> submittedResponses;
  final Map<String, int> responseTimes;
  final String assessmentStatus;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Explicit reverse-pair RVI semantics. Missing descriptors make reverse
  /// consistency unavailable for that pair (never fabricate inconsistency).
  final List<ReversePairDescriptor> reversePairDescriptors;

  const TraitScoringSessionInput({
    required this.module,
    required this.schemaVersion,
    required this.contentVersion,
    required this.traitScoringVersion,
    required this.locale,
    required this.setId,
    required this.questionDefinitions,
    required this.submittedResponses,
    this.responseTimes = const {},
    required this.assessmentStatus,
    this.startedAt,
    this.completedAt,
    this.reversePairDescriptors = const [],
  });
}
