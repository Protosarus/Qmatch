import 'package:flutter/foundation.dart';

import 'localized_text_resolver.dart';

/// Temporary Phase 3G diagnostics — logs only in [kDebugMode].
class AssessmentLocalizationDebug {
  const AssessmentLocalizationDebug._();

  static void logSetLoad({
    required String type,
    required String setId,
    required String source,
    required String languageCode,
    Map<String, dynamic>? firstQuestion,
  }) {
    if (!kDebugMode) return;

    final qRaw = firstQuestion == null
        ? null
        : (firstQuestion.containsKey('text')
            ? firstQuestion['text']
            : firstQuestion['question']);
    final qShape = _shapeLabel(qRaw);
    final resolvedLang = _resolvedLanguageKey(qRaw, languageCode: languageCode);
    final preview = LocalizedTextResolver.resolve(
      qRaw,
      languageCode: languageCode,
    );
    final previewShort =
        preview.length > 72 ? '${preview.substring(0, 72)}…' : preview;

    debugPrint(
      '[AssessmentLocalization] type=$type set_id=$setId source=$source '
      'languageCode=$languageCode firstQuestion=$qShape '
      'resolvedFrom=$resolvedLang preview="$previewShort"',
    );
  }

  static void logMappedQuestions({
    required String type,
    required String setId,
    required String languageCode,
    required List<dynamic> rawQuestions,
    required String resolvedFirstQuestion,
  }) {
    if (!kDebugMode) return;
    if (rawQuestions.isEmpty) {
      debugPrint(
        '[AssessmentLocalization] type=$type set_id=$setId mapped=0 '
        'languageCode=$languageCode',
      );
      return;
    }

    final first = rawQuestions.first;
    final qRaw = first is Map
        ? (first.containsKey('text') ? first['text'] : first['question'])
        : null;
    final qShape = _shapeLabel(qRaw);
    final resolvedLang = _resolvedLanguageKey(qRaw, languageCode: languageCode);
    final previewShort = resolvedFirstQuestion.length > 72
        ? '${resolvedFirstQuestion.substring(0, 72)}…'
        : resolvedFirstQuestion;

    debugPrint(
      '[AssessmentLocalization] type=$type set_id=$setId mapped=${rawQuestions.length} '
      'languageCode=$languageCode firstQuestion=$qShape '
      'resolvedFrom=$resolvedLang preview="$previewShort"',
    );
  }

  static String _shapeLabel(dynamic raw) {
    if (raw == null) return 'null';
    if (raw is String) return 'String';
    if (raw is Map) return 'Map';
    return raw.runtimeType.toString();
  }

  /// Which locale key would [LocalizedTextResolver] prefer for [raw].
  static String _resolvedLanguageKey(
    dynamic raw, {
    required String languageCode,
  }) {
    if (raw is String) return 'plain_string';
    if (raw is! Map) return 'fallback';

    final map = <String, String>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty) continue;
      map[e.key.toString().toLowerCase()] = s;
    }
    if (map.isEmpty) return 'empty_map';

    final lang = languageCode.trim().toLowerCase();
    if (map[lang]?.isNotEmpty == true) return lang;
    if (map['en']?.isNotEmpty == true) return 'en';
    return 'first_available';
  }
}
