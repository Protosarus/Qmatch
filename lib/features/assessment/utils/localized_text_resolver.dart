/// Resolves assessment content that may be a legacy plain string
/// or a future localized map `{ "en": "...", "tr": "..." }`.
///
/// Never throws on malformed input.
class LocalizedTextResolver {
  const LocalizedTextResolver._();

  /// Resolve a question/label value for [languageCode].
  ///
  /// Supports:
  /// - `"plain string"`
  /// - `{ "en": "...", "tr": "..." }` (Map)
  static String resolve(
    dynamic raw, {
    String languageCode = 'en',
  }) {
    if (raw == null) return '';

    if (raw is String) {
      return raw.trim();
    }

    if (raw is Map) {
      final map = <String, String>{};
      for (final e in raw.entries) {
        final v = e.value;
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isEmpty) continue;
        map[e.key.toString().toLowerCase()] = s;
      }
      if (map.isEmpty) return '';

      final lang = languageCode.trim().toLowerCase();
      final primary = map[lang];
      if (primary != null && primary.isNotEmpty) return primary;

      final en = map['en'];
      if (en != null && en.isNotEmpty) return en;

      return map.values.first;
    }

    final fallback = raw.toString().trim();
    return fallback;
  }

  /// Resolve one option entry to a display label.
  ///
  /// Supports:
  /// - `"Option A"`
  /// - `{ "en": "Option A", "tr": "..." }`
  /// - `{ "value": "a", "label": { "en": "...", "tr": "..." } }`
  /// - `{ "value": "a", "label": "Option A" }`
  static String resolveOptionLabel(
    dynamic raw, {
    String languageCode = 'en',
  }) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();

    if (raw is Map) {
      if (raw.containsKey('label')) {
        return resolve(raw['label'], languageCode: languageCode);
      }
      // Direct language map on the option object.
      if (raw.containsKey('en') || raw.containsKey('tr')) {
        return resolve(raw, languageCode: languageCode);
      }
      // Prefer known display fields if present.
      if (raw.containsKey('text')) {
        return resolve(raw['text'], languageCode: languageCode);
      }
    }

    return resolve(raw, languageCode: languageCode);
  }

  /// Resolve a list of options to display labels (order preserved).
  static List<String> resolveOptionLabels(
    dynamic rawList, {
    String languageCode = 'en',
  }) {
    if (rawList is! List || rawList.isEmpty) return const [];
    return rawList
        .map(
          (e) => resolveOptionLabel(e, languageCode: languageCode),
        )
        .toList();
  }

  /// Optional stable option identity for future formats.
  /// Legacy string options return null (score by index).
  static String? optionValueId(dynamic raw) {
    if (raw is Map && raw['value'] != null) {
      final v = raw['value'].toString().trim();
      return v.isEmpty ? null : v;
    }
    return null;
  }
}
