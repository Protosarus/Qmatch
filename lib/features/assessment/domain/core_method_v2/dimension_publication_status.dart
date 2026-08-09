import 'core_method_v2_validation.dart';

enum DimensionPublicationStatus {
  published,
  insufficientEvidence,
  unavailable,
  incomplete,
}

extension DimensionPublicationStatusX on DimensionPublicationStatus {
  String get wire {
    switch (this) {
      case DimensionPublicationStatus.published:
        return 'published';
      case DimensionPublicationStatus.insufficientEvidence:
        return 'insufficient_evidence';
      case DimensionPublicationStatus.unavailable:
        return 'unavailable';
      case DimensionPublicationStatus.incomplete:
        return 'incomplete';
    }
  }

  bool get isPublished => this == DimensionPublicationStatus.published;
}

DimensionPublicationStatus parseDimensionPublicationStatus(String raw) {
  switch (raw) {
    case 'published':
      return DimensionPublicationStatus.published;
    case 'insufficient_evidence':
      return DimensionPublicationStatus.insufficientEvidence;
    case 'unavailable':
      return DimensionPublicationStatus.unavailable;
    case 'incomplete':
      return DimensionPublicationStatus.incomplete;
    default:
      throw CoreMethodValidationException(
        'unknown publication status',
        [
          CoreMethodValidationError(
            fieldPath: 'publication_status',
            reasonCode: 'unknown_status',
            explanation: raw,
          ),
        ],
      );
  }
}
