import 'core_method_v2_validation.dart';

enum AssessmentModuleId { iq, eq, frequency }

/// Wire value for relationship-values module remains `"values"`.
enum CompatibilityModuleId { iq, eq, frequency, relationshipValues }

extension AssessmentModuleIdX on AssessmentModuleId {
  String get wire {
    switch (this) {
      case AssessmentModuleId.iq:
        return 'iq';
      case AssessmentModuleId.eq:
        return 'eq';
      case AssessmentModuleId.frequency:
        return 'frequency';
    }
  }
}

extension CompatibilityModuleIdX on CompatibilityModuleId {
  String get wire {
    switch (this) {
      case CompatibilityModuleId.iq:
        return 'iq';
      case CompatibilityModuleId.eq:
        return 'eq';
      case CompatibilityModuleId.frequency:
        return 'frequency';
      case CompatibilityModuleId.relationshipValues:
        return 'values';
    }
  }
}

AssessmentModuleId parseAssessmentModuleId(String raw) {
  switch (raw) {
    case 'iq':
      return AssessmentModuleId.iq;
    case 'eq':
      return AssessmentModuleId.eq;
    case 'frequency':
      return AssessmentModuleId.frequency;
    default:
      throw CoreMethodValidationException(
        'unknown assessment module',
        [
          CoreMethodValidationError(
            fieldPath: 'module',
            reasonCode: 'unknown_module',
            explanation: raw,
          ),
        ],
      );
  }
}

CompatibilityModuleId parseCompatibilityModuleId(String raw) {
  switch (raw) {
    case 'iq':
      return CompatibilityModuleId.iq;
    case 'eq':
      return CompatibilityModuleId.eq;
    case 'frequency':
      return CompatibilityModuleId.frequency;
    case 'values':
      return CompatibilityModuleId.relationshipValues;
    default:
      throw CoreMethodValidationException(
        'unknown compatibility module',
        [
          CoreMethodValidationError(
            fieldPath: 'module',
            reasonCode: 'unknown_module',
            explanation: raw,
          ),
        ],
      );
  }
}
