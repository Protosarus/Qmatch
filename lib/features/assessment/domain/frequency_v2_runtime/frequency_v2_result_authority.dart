import '../frequency_behavior_v2/frequency_behavior_v2_contract.dart';

/// Strict client-side proof that `users/{uid}/assessments/frequency_v2`
/// is an authoritative completed V2 result.
///
/// Mirrors the server parser enough for routing. Does not write Firestore,
/// grant Discover, or map 12D → 6D / canonical_v1.
class FrequencyV2ResultAuthority {
  FrequencyV2ResultAuthority._();

  static const String resultSchemaVersion =
      'qmatch_frequency_behavior_v2_result_v1';
  static const String resultSource = 'admin_finalize_frequency_v2_v1';
  static const String resultStatus = 'completed';
  static const String assessmentType = 'frequency_v2';
  static const String resultDocId = 'frequency_v2';

  static bool isAuthoritativeCompleted(Map<String, dynamic>? data) {
    return parse(data).ok;
  }

  /// Signed 12D `normalized_behavior` when [isAuthoritativeCompleted].
  static Map<String, double>? signedScores(Map<String, dynamic>? data) {
    if (!isAuthoritativeCompleted(data)) return null;
    final out = <String, double>{};
    for (final row in data!['dimensions'] as List) {
      final map = Map<String, dynamic>.from(row as Map);
      out[map['dimension_id'] as String] =
          (map['normalized_behavior'] as num).toDouble();
    }
    return out;
  }

  static ({bool ok, String code}) parse(Map<String, dynamic>? data) {
    if (data == null) return (ok: false, code: 'missing_document');
    if (data['schema_version'] != resultSchemaVersion) {
      return (ok: false, code: 'wrong_schema');
    }
    if (data['assessment_type'] != assessmentType) {
      return (ok: false, code: 'wrong_assessment_type');
    }
    if (data['status'] != resultStatus) {
      return (ok: false, code: 'not_completed');
    }
    if (data['source'] != resultSource) {
      return (ok: false, code: 'untrusted_source');
    }
    final dimensions = data['dimensions'];
    if (dimensions is! List) return (ok: false, code: 'malformed_result');

    final seen = <String>{};
    for (final row in dimensions) {
      if (row is! Map) return (ok: false, code: 'malformed_result');
      final id = row['dimension_id'];
      if (id is! String || id.isEmpty) {
        return (ok: false, code: 'malformed_result');
      }
      if (!FrequencyBehaviorV2Contract.isCanonicalDimension(id)) {
        return (ok: false, code: 'unknown_dimension');
      }
      if (!seen.add(id)) return (ok: false, code: 'duplicate_dimension');
      if (!_inClosed(row['normalized_behavior'], -1, 1)) {
        return (ok: false, code: 'invalid_normalized_behavior');
      }
      if (!_inClosed(row['provisional_confidence'], 0, 1)) {
        return (ok: false, code: 'invalid_provisional_confidence');
      }
      if (!_inClosed(row['confidence_completeness'], 0, 1)) {
        return (ok: false, code: 'invalid_confidence_completeness');
      }
    }
    for (final id in FrequencyBehaviorV2Contract.canonicalDimensions) {
      if (!seen.contains(id)) return (ok: false, code: 'missing_dimension');
    }
    return (ok: true, code: 'ok');
  }

  static bool _inClosed(Object? value, double min, double max) {
    if (value is! num) return false;
    final n = value.toDouble();
    if (n.isNaN || n.isInfinite) return false;
    return n >= min && n <= max;
  }
}
